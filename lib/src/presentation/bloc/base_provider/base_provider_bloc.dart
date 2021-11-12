import 'dart:async';

import 'package:api_bloc_base/src/data/repository/base_repository.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:async/async.dart' as async;
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

import 'lifecycle_observer.dart';
import 'provider_state.dart';

export 'provider_state.dart';

abstract class BaseProviderBloc<Data> extends BaseCubit<ProviderState<Data>>
    implements LifecycleAware {
  final Duration? refreshInterval = Duration(seconds: 30);
  final Duration? retryInterval = Duration(seconds: 30);
  final LifecycleObserver? observer;

  final BehaviorSubject<Data?> _dataSubject = BehaviorSubject<Data?>();
  var _dataFuture = Completer<Data?>();
  var _stateFuture = Completer<ProviderState<Data>>();

  StreamSubscription<ProviderState<Data>>? _subscription;
  bool green = false;
  bool shouldBeGreen = false;

  String get defaultError => 'Error';

  Timer? _retrialTimer;
  Stream<Data?> get dataStream =>
      async.LazyStream(() => _dataSubject.shareValue())
          .asBroadcastStream(onCancel: (c) => c.cancel());

  Stream<ProviderState<Data>> get stateStream => stream;

  Future<Data?> get dataFuture => _dataFuture.future;
  Future<ProviderState<Data>> get stateFuture => _stateFuture.future;

  Data? get latestData => _dataSubject.valueOrNull;

  Result<Either<ResponseEntity, Data>>? get dataSource => null;
  Either<ResponseEntity, Stream<Data>>? get dataSourceStream => null;

  final List<Stream<ProviderState>> sources;

  BaseProviderBloc(
      {Data? initialDate,
      bool enableRetry = true,
      bool enableRefresh = true,
      bool getOnCreate = true,
      this.observer,
      this.sources = const []})
      : super(ProviderLoadingState()) {
    if (observer != null) {
      observer?.addListener(this);
    } else {
      green = true;
      shouldBeGreen = true;
    }
    if (initialDate != null) {
      emit(ProviderLoadedState(initialDate));
    }
    _setUpListener(enableRetry, enableRefresh);
    if (getOnCreate) {
      startTries();
    }
  }

  void startTries([bool userLogStateEvent = true]) {
    green = true;
    shouldBeGreen = userLogStateEvent || shouldBeGreen;
    if (userLogStateEvent) {
      _subscription?.cancel();
      _subscription = null;
    } else {
      _subscription?.resume();
    }
    getData();
  }

  void stopRetries([bool userLogStateEvent = true]) {
    green = false;
    shouldBeGreen = !userLogStateEvent && shouldBeGreen;
    _retrialTimer?.cancel();
    _subscription?.pause();
    emitLoading();
  }

  @override
  void onResume() {
    startTries(false);
  }

  @override
  void onPause() {
    stopRetries(false);
  }

  @override
  void onDetach() {}

  @override
  void onInactive() {}

  void _setUpListener(bool enableRetry, bool enableRefresh) {
    stream.listen((state) {
      if (state is InvalidatedState) {
        getData();
      } else {
        _handleState(state);
      }
      if (state is ProviderErrorState && enableRetry) {
        if (retryInterval != null) {
          _retrialTimer?.cancel();
          _retrialTimer = Timer(retryInterval!, getData);
        }
      } else if (state is ProviderLoadedState && enableRefresh) {
        if (refreshInterval != null) {
          _retrialTimer?.cancel();
          _retrialTimer = Timer.periodic(refreshInterval!, (_) => refresh());
        }
      }
    }, onError: (e, s) {
      print(e);
      print(s);
    });
  }

  void _handleState(state) {
    if (state is ProviderLoadedState) {
      Data data = state.data;
      _retrialTimer?.cancel();
      _dataSubject.add(data);
      if (_dataFuture.isCompleted) {
        _dataFuture = Completer<Data>();
      }
      _dataFuture.complete(data);
    }
    if (_stateFuture.isCompleted) {
      _stateFuture = Completer<ProviderState<Data>>();
    }
    _stateFuture.complete(state);
  }

  Future<void> handleOperation(
      Result<Either<ResponseEntity, Data>> result, bool refresh) async {
    if (!refresh) {
      emitLoading();
    }
    final future = await result.resultFuture;
    return future.fold(
      (l) async {
        emitErrorState(l.message, !refresh);
      },
      (r) {
        return handleStream(Right(Stream.value(r)), refresh);
      },
    );
  }

  Future<void> handleStream(
      Either<ResponseEntity, Stream<Data>> result, bool refresh) async {
    result.fold(
      (l) {
        emitErrorState(l.message, !refresh);
      },
      (r) {
        print("${this.runtimeType} handleStream");
        _subscription?.cancel();
        _subscription =
            r.asBroadcastStream(onCancel: (c) => c.cancel()).doOnData((data) {
          if (!refresh) {
            emitLoading();
          }
          print("${this.runtimeType} doOnEach");
        }).switchMap<Tuple2<Data, List<ProviderState<dynamic>>>>((event) {
          print("${this.runtimeType} combine");
          if (sources.isEmpty) {
            return Stream.value(Tuple2(event, []));
          } else {
            return CombineLatestStream<ProviderState<dynamic>,
                    Tuple2<Data, List<ProviderState<dynamic>>>>(
                sources, (a) => Tuple2(event, a));
          }
        }).asyncMap((event) async {
          print("${this.runtimeType} asyncMap");
          print("${event.value2.map((e) => e.runtimeType)} asyncMap");
          ProviderErrorState? errorState = event.value2
                  .firstWhereOrNull((element) => element is ProviderErrorState)
              as ProviderErrorState<dynamic>?;
          if (errorState != null) {
            return createErrorState<Data>(errorState.message);
          } else if (event.value2
              .any((element) => element is ProviderLoadingState)) {
            return createLoadingState<Data>();
          } else {
            final result = combineDataWithSources(
                event.value1,
                event.value2
                    .map((e) => (e as ProviderLoadedState).data)
                    .toList());
            return createLoadedState<Data>(result);
          }
        }).listen((event) {
          print("${this.runtimeType} listening");
          print("${event.runtimeType} listening");
          emitState(event);
        }, onError: (e, s) {
          print(e);
          print(s);
          emitErrorState(defaultError, !refresh);
        });
      },
    );
  }

  Data combineDataWithSources(Data data, List<dynamic> map) {
    return data;
  }

  void interceptOperation<S>(Result<Either<ResponseEntity, S>> result,
      {void onSuccess()?, void onFailure()?, void onDate(S data)?}) {
    result.resultFuture.then((value) {
      value.fold((l) {
        if (l is Success) {
          onSuccess?.call();
        } else if (l is Failure) {
          onFailure?.call();
        }
      }, (r) {
        if (onDate != null) {
          onDate(r);
        } else if (onSuccess != null) {
          onSuccess();
        }
      });
    });
  }

  void interceptResponse(Result<ResponseEntity> result,
      {void onSuccess()?, void onFailure()?}) {
    result.resultFuture.then((value) {
      if (value is Success) {
        onSuccess?.call();
      } else if (value is Failure) {
        onFailure?.call();
      }
    });
  }

  void clean() {
    _dataSubject.value = null;
    _dataFuture = Completer();
  }

  @mustCallSuper
  Future<Data?> getData({bool refresh = false}) async {
    if (!refresh) clean();
    final Result<Either<ResponseEntity, Data>>? dataSource = this.dataSource;
    final Either<ResponseEntity, Stream<Data>>? dataSourceStream =
        this.dataSourceStream;
    if (green && shouldBeGreen) {
      if (dataSource != null) {
        await handleOperation(dataSource, refresh);
      } else if (dataSourceStream != null && _subscription == null) {
        await handleStream(dataSourceStream, refresh);
        return null;
      }
    }
    return null;
  }

  Future<Data?> refresh() {
    return getData(refresh: true);
  }

  ProviderState<Data> createLoadingState<Data>() {
    return ProviderLoadingState<Data>();
  }

  ProviderState<Data> createLoadedState<Data>(Data data) {
    return ProviderLoadedState<Data>(data);
  }

  ProviderState<Data> createErrorState<Data>(String? message) {
    return ProviderErrorState<Data>(message);
  }

  void emitState(ProviderState<Data> state) {
    if (state is ProviderLoadingState<Data>) {
      emitLoading();
    } else if (state is ProviderLoadedState<Data>) {
      emitLoaded(state.data);
    } else if (state is ProviderErrorState<Data>) {
      emitErrorState(state.message, true);
    }
  }

  void emitLoading() {
    emit(createLoadingState<Data>());
  }

  void emitLoaded(Data data) {
    emit(createLoadedState<Data>(data));
  }

  void invalidate() {
    emit(InvalidatedState<Data>());
  }

  void emitErrorState(String? message, bool clean) {
    if (clean) this.clean();
    emit(createErrorState<Data>(message));
  }

  Stream<ProviderState<Out>> transformStream<Out>(
      {Out? outData, Stream<Out>? outStream}) {
    return stateStream.flatMap<ProviderState<Out>>((value) {
      if (value is ProviderLoadingState<Data>) {
        return Stream.value(ProviderLoadingState<Out>());
      } else if (value is ProviderErrorState<Data>) {
        return Stream.value(ProviderErrorState<Out>(value.message));
      } else if (value is InvalidatedState<Data>) {
        return Stream.value(InvalidatedState<Out>());
      } else {
        if (outData != null) {
          return Stream.value(ProviderLoadedState<Out>(outData));
        } else if (outStream != null) {
          return outStream.map((event) => ProviderLoadedState<Out>(event));
        }
        return Stream.empty();
      }
    }).asBroadcastStream(onCancel: ((sub) => sub.cancel()));
  }

  @override
  Future<void> close() {
    observer?.removeListener(this);
    _subscription?.cancel();
    _dataSubject.drain().then((value) => _dataSubject.close());
    _retrialTimer?.cancel();
    return super.close();
  }
}
