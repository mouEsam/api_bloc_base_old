import 'dart:async';

import 'package:api_bloc_base/src/data/repository/base_repository.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:async/async.dart' as async;
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'lifecycle_observer.dart';
import 'provider_state.dart';

export 'provider_state.dart';

class BaseBloc extends Cubit<int> {
  BaseBloc() : super(0);
}

abstract class BaseProviderBloc<Data> extends Cubit<ProviderState<Data>>
    implements LifecycleAware {
  static const REFRESH_TIME = Duration(seconds: 30);

  final LifecycleObserver observer;
  final _dataSubject = BehaviorSubject<Data>();
  final _stateSubject = BehaviorSubject<ProviderState<Data>>();
  var _dataFuture = Completer<Data>();
  var _stateFuture = Completer<ProviderState<Data>>();

  StreamSubscription<Data> _subscription;
  bool green = false;
  bool shouldBeGreen = false;

  String get defaultError => 'Error';

  Timer _retrialTimer;
  Stream<Data> get dataStream =>
      async.LazyStream(() => _dataSubject.shareValue());
  Stream<ProviderState<Data>> get stateStream =>
      async.LazyStream(() => _stateSubject.shareValue());
  Future<Data> get dataFuture => _dataFuture.future;
  Future<ProviderState<Data>> get stateFuture => _stateFuture.future;

  Data get latestData => _dataSubject.value;

  Result<Either<ResponseEntity, Data>> get dataSource => null;
  Either<ResponseEntity, Stream<Data>> get dataSourceStream => null;

  BaseProviderBloc(
      {Data initialDate,
      bool enableRetry = true,
      bool getOnCreate = true,
      this.observer})
      : super(ProviderLoadingState()) {
    observer?.addListener(this);
    if (initialDate != null) {
      emit(ProviderLoadedState(initialDate));
    }
    _setUpListener(enableRetry);
    if (getOnCreate) {
      startTries();
    }
  }

  void startTries([bool userLogStateEvent = true]) {
    green = true;
    shouldBeGreen = userLogStateEvent || shouldBeGreen;
    getData();
  }

  void stopRetries([bool userLogStateEvent = true]) {
    green = false;
    shouldBeGreen = !userLogStateEvent && shouldBeGreen;
    _retrialTimer?.cancel();
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

  void _setUpListener(bool enableRetry) {
    listen((state) {
      if (state is InvalidatedState) {
        getData();
      } else {
        _handleState(state);
      }
      print('${state} ${enableRetry}');
      if (REFRESH_TIME != null) {
        if (state is ProviderErrorState && enableRetry) {
          _retrialTimer?.cancel();
          _retrialTimer = Timer(REFRESH_TIME, getData);
        } else if (state is ProviderLoadedState) {
          _retrialTimer?.cancel();
          _retrialTimer = Timer.periodic(REFRESH_TIME, (_) => refresh());
        }
      }
    }, onError: (e, s) {
      print(e);
      print(s);
    });
  }

  void _handleState(state) {
    Data data;
    if (state is ProviderLoadedState) {
      data = state.data;
      _retrialTimer?.cancel();
      _dataSubject.add(data);
      if (_dataFuture.isCompleted) {
        _dataFuture = Completer<Data>();
      }
      _dataFuture.complete(data);
    }
    _stateSubject.add(state);
    if (_stateFuture.isCompleted) {
      _stateFuture = Completer<ProviderState<Data>>();
    }
    _stateFuture.complete(state);
  }

  Future<Data> handleOperation(
      Result<Either<ResponseEntity, Data>> result, bool refresh) async {
    if (!refresh) {
      emitLoading();
    }
    final future = await result.resultFuture;
    return future.fold<Data>(
      (l) {
        emit(ProviderErrorState(l.message));
        return null;
      },
      (r) {
        emit(ProviderLoadedState(r));
        return r;
      },
    );
  }

  Future<void> handleStream(
      Either<ResponseEntity, Stream<Data>> result, bool refresh) async {
    result.fold(
      (l) {
        emit(ProviderErrorState(l.message));
      },
      (r) {
        _subscription?.cancel();
        _subscription = r.doOnEach((notification) {
          if (!refresh) {
            emitLoading();
          }
        }).listen((event) {
          emit(ProviderLoadedState(event));
        }, onError: (e, s) {
          print(e);
          print(s);
          emit(ProviderErrorState(defaultError));
        });
      },
    );
  }

  void interceptOperation<S>(Result<Either<ResponseEntity, S>> result,
      {void onSuccess(), void onFailure(), void onDate(S data)}) {
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
      {void onSuccess(), void onFailure()}) {
    result.resultFuture.then((value) {
      if (value is Success) {
        onSuccess?.call();
      } else if (value is Failure) {
        onFailure?.call();
      }
    });
  }

  @mustCallSuper
  void getData({bool refresh = false}) {
    if (green && shouldBeGreen) {
      if (dataSource != null) {
        handleOperation(dataSource, refresh);
      } else if (dataSourceStream != null) {
        handleStream(dataSourceStream, refresh);
      }
    }
  }

  void invalidate() {
    emit(InvalidatedState<Data>());
  }

  void refresh() {
    getData(refresh: true);
  }

  void emitLoading() {
    emit(ProviderLoadingState<Data>());
  }

  Stream<ProviderState<Out>> transformStream<Out>(
      {Out outData, Stream<Out> outStream}) {
    return stateStream.flatMap((value) {
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
        return null;
      }
    }).asBroadcastStream();
  }

  @override
  Future<void> close() {
    observer?.removeListener(this);
    _subscription?.cancel();
    _dataSubject.drain().then((value) => _dataSubject.close());
    _stateSubject.drain().then((value) => _stateSubject.close());
    _retrialTimer?.cancel();
    return super.close();
  }
}
