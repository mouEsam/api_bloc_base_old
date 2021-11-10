import 'dart:async';

import 'package:api_bloc_base/src/data/repository/base_repository.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

import 'error_mixin.dart';
import 'lifecycle_observer.dart';
import 'provider_mixin.dart';
import 'state.dart';

abstract class ProviderBloc<Data> extends BaseCubit<ProviderState<Data>>
    with ErrorMixin, ProviderMixin<Data>
    implements LifecycleAware {
  get defaultErrorMessage => "error";

  final Duration? refreshInterval = Duration(seconds: 30);
  final Duration? retryInterval = Duration(seconds: 30);
  final ValueNotifier<bool> isAppGreen = ValueNotifier(true);

  final Result<Either<ResponseEntity, Data>>? singleDataSource;
  final Either<ResponseEntity, Stream<Data>>? streamDataSource;

  final LifecycleObserver? appLifecycleObserver;
  final List<Stream<ProviderState>> sources;

  final bool enableRefresh;
  final bool enableRetry;

  late final Listenable _singleTrafficLights;

  List<ValueNotifier<bool>> get trafficLights => [isAppGreen];
  bool get trafficLightsValue =>
      trafficLights.every((element) => element.value);

  final BehaviorSubject<Data> _input = BehaviorSubject();

  late final StreamSubscription<ProviderState<Data>> _dataSubscription;
  late final StreamSubscription<ProviderState<Data>> _stateSubscription;

  StreamSubscription<Data>? _streamSourceSubscription;

  @override
  get notifiers => [...trafficLights];

  late bool _lastTrafficLightsValue;

  Timer? _timer;

  ProviderBloc({
    Data? initialDate,
    this.singleDataSource,
    this.streamDataSource,
    this.appLifecycleObserver,
    this.sources = const [],
    this.enableRefresh = true,
    this.enableRetry = true,
    bool getOnCreate = true,
  }) : super(ProviderLoading()) {
    setupTrafficLights();
    setupStreams();
    setupRetrialAndRefresh();
    setupInitialData(initialDate);
    if (getOnCreate) {
      fetchData();
    }
  }

  void setupInitialData(Data? initialDate) {
    if (initialDate is Data) {
      injectInput(initialDate);
    }
  }

  @mustCallSuper
  Future<void> fetchData({bool refresh = false}) async {
    if (!refresh) {
      emitLoading();
    }
    final singleSource = this.singleDataSource;
    final streamSource = this.streamDataSource;
    if (_lastTrafficLightsValue) {
      if (singleSource != null) {
        await _handleSingleSource(singleSource, refresh);
      } else if (streamSource != null) {
        _handleStreamSource(streamSource);
      }
    }
  }

  Future<void> refreshData() {
    return fetchData(refresh: true);
  }

  Future<void> _handleSingleSource(
      Result<Either<ResponseEntity, Data>> singleSource, bool refresh) async {
    final future = await singleSource.resultFuture;
    return future.fold(
      (l) async {
        emitError(l);
      },
      (r) {
        return _handleStreamSource(Right(Stream.value(r)));
      },
    );
  }

  void _handleStreamSource(Either<ResponseEntity, Stream<Data>> streamSource) {
    return streamSource.fold(
      (l) async {
        emitError(l);
      },
      (r) {
        _streamSourceSubscription?.cancel();
        _streamSourceSubscription = r.listen(_input.add);
      },
    );
  }

  void setupRetrialAndRefresh() {
    _stateSubscription = stream.listen((state) {
      if (state is Invalidated) {
        fetchData();
        return;
      }
      setupTimer();
    }, onError: (e, s) {
      print(e);
      print(s);
    });
  }

  void setupTimer() {
    if (state is ProviderError && enableRetry) {
      if (retryInterval != null) {
        _timer?.cancel();
        _timer = Timer(retryInterval!, fetchData);
      }
    } else if (state is ProviderLoaded && enableRefresh) {
      if (refreshInterval != null) {
        _timer?.cancel();
        _timer = Timer.periodic(refreshInterval!, (_) => refreshData());
      }
    }
  }

  void injectInput(Data input) {
    _input.add(input);
  }

  void setupStreams() {
    _dataSubscription =
        _input.switchMap<Tuple2<Data, List<ProviderState<dynamic>>>>((event) {
      if (sources.isEmpty) {
        return Stream.value(Tuple2(event, []));
      } else {
        return CombineLatestStream<ProviderState<dynamic>,
                Tuple2<Data, List<ProviderState<dynamic>>>>(
            sources, (a) => Tuple2(event, a));
      }
    }).asyncMap((event) async {
      ProviderError? errorState =
          event.value2.firstWhereOrNull((element) => element is ProviderError)
              as ProviderError<dynamic>?;
      if (errorState != null) {
        return createErrorState<Data>(errorState.response);
      } else if (event.value2.any((element) => element is ProviderLoading)) {
        return createLoadingState<Data>();
      } else {
        final result = combineDataWithSources(event.value1,
            event.value2.map((e) => (e as ProviderLoaded).data).toList());
        return createLoadedState<Data>(result);
      }
    }).listen((event) {
      emitState(event);
    }, onError: (e, s) {
      print(e);
      print(s);
      emitError(Failure(extractErrorMessage(e)));
    });
  }

  Data combineDataWithSources(Data data, List<dynamic> map) {
    return data;
  }

  void setupTrafficLights() {
    _lastTrafficLightsValue = trafficLightsValue;
    _singleTrafficLights = Listenable.merge(trafficLights);
    _singleTrafficLights.addListener(() {
      final newValue = trafficLightsValue;
      if (_lastTrafficLightsValue != newValue) {
        trafficLightsChanged(newValue);
      }
      _lastTrafficLightsValue = newValue;
    });
  }

  void trafficLightsChanged(bool green) {
    if (green) {
      _dataSubscription.resume();
      _stateSubscription.resume();
      _streamSourceSubscription?.resume();
      setupTimer();
    } else {
      _dataSubscription.pause();
      _stateSubscription.pause();
      _streamSourceSubscription?.pause();
      _timer?.cancel();
    }
  }

  @override
  void onResume() {
    isAppGreen.value = true;
  }

  @override
  void onPause() {
    isAppGreen.value = false;
  }

  @override
  void onDetach() {}

  @override
  void onInactive() {}

  @override
  Future<void> close() {
    _dataSubscription.cancel();
    _stateSubscription.cancel();
    _streamSourceSubscription?.cancel();
    _timer?.cancel();
    return super.close();
  }
}
