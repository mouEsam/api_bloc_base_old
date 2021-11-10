import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../api_bloc_base.dart';
import '../base_provider/provider_state.dart' as provider;
import 'base_converter_bloc.dart';

export 'working_state.dart';

mixin IndependentMixin<Input, Output> on BaseConverterBloc<Input, Output>
    implements LifecycleAware {
  final Duration? refreshInterval = const Duration(seconds: 30);
  final Duration? retryInterval = const Duration(seconds: 30);

  Timer? _retrialTimer;

  bool green = false;
  bool shouldBeGreen = false;
  bool wasSatUp = false;

  LifecycleObserver? get lifecycleObserver;

  List<Stream<provider.ProviderState>> get sources;

  Stream<provider.ProviderState<Input>> get source {
    Stream<provider.ProviderState<Input>> finalStream;
    final sources = this.sources;
    if (sourceBloc != null) {
      sources.add(sourceBloc!.stateStream);
    }
    if (sources.isNotEmpty) {
      final stream = CombineLatestStream.list(sources)
          .asBroadcastStream(onCancel: (sub) => sub.cancel());
      finalStream = CombineLatestStream.combine2<List, Input,
              provider.ProviderState<Input>>(stream, originalDataStream,
          (list, data) {
        provider.ProviderErrorState? error = list.firstWhere(
            (element) => element is provider.ProviderErrorState,
            orElse: () => null);
        if (error != null) {
          return provider.ProviderErrorState<Input>(error.message);
        }
        provider.ProviderLoadingState? loading = list.firstWhere(
            (element) => element is provider.ProviderLoadingState,
            orElse: () => null);
        if (loading != null) {
          return provider.ProviderLoadingState<Input>();
        }
        provider.InvalidatedState? invalidated = list.firstWhere(
            (element) => element is provider.InvalidatedState,
            orElse: () => null);
        if (invalidated != null) {
          return provider.InvalidatedState<Input>();
        }
        return provider.ProviderLoadedState<Input>(data);
      }).asBroadcastStream(onCancel: (sub) => sub.cancel());
    } else {
      finalStream = originalDataStream
          .map((data) => provider.ProviderLoadedState<Input>(data))
          .cast<provider.ProviderState<Input>>()
          .asBroadcastStream(onCancel: (sub) => sub.cancel());
    }
    return finalStream;
  }

  void setIndependenceUp(
      bool getOnCreate, bool enableRetry, bool enableRefresh) {
    if (lifecycleObserver != null) {
      lifecycleObserver?.addListener(this);
    } else {
      green = true;
      shouldBeGreen = true;
    }
    _setUpListener(getOnCreate, enableRetry, enableRefresh);
  }

  void _setUpListener(bool getOnCreate, bool enableRetry, bool enableRefresh) {
    stream.listen((state) {
      if (state is ErrorState && enableRetry) {
        if (retryInterval != null) {
          _retrialTimer?.cancel();
          _retrialTimer = Timer(retryInterval!, getData);
        }
      } else if (state is LoadedState && enableRefresh) {
        if (refreshInterval != null) {
          _retrialTimer?.cancel();
          _retrialTimer = Timer.periodic(refreshInterval!, (_) => refresh());
        }
      }
    }, onError: (e, s) {
      print(e);
      print(s);
    });
    if (getOnCreate) {
      startTries();
    }
  }

  Output combineData(Output data) => data;

  @override
  void setData(Output newData) {
    final data = combineData(newData);
    _finalDataSubject.add(data);
    super.setData(data);
  }

  final _ownDataSubject = StreamController<Input>.broadcast();
  Stream<Input> get originalDataStream => _ownDataSubject.stream.shareValue();

  final BehaviorSubject<Output> _finalDataSubject = BehaviorSubject<Output>();
  Stream<Output> get finalDataStream => _finalDataSubject.shareValue();

  void injectInput(Input input) {
    if (!_ownDataSubject.isClosed) {
      _ownDataSubject.add(input);
    }
  }

  void clean() {
    super.clean();
    //_finalDataSubject.value = null;
  }

  Result<Either<ResponseEntity, Input>> get dataSource;

  Future<void> getData([bool refresh = false]) async {
    if (green && shouldBeGreen) {
      super.getData(refresh);
      final data = dataSource;
      await handleDataRequest(data, refresh);
    }
  }

  Future<void> handleDataRequest(
      Result<Either<ResponseEntity, Input>> result, bool refresh) async {
    if (!refresh) handleLoadingState(ProviderLoadingState<Input>());
    final future = await result.resultFuture;
    return future.fold(
      (l) {
        handleErrorState(ProviderErrorState<Input>(l.message));
      },
      (r) {
        injectInput(r);
      },
    );
  }

  void startTries([bool userLogStateEvent = true]) {
    green = true;
    shouldBeGreen = userLogStateEvent || shouldBeGreen;
    eventSubscription.resume();
    getData();
  }

  void stopRetries([bool userLogStateEvent = true]) {
    green = false;
    shouldBeGreen = !userLogStateEvent && shouldBeGreen;
    _retrialTimer?.cancel();
    eventSubscription.pause();
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

  @override
  Future<void> close() {
    _retrialTimer?.cancel();
    _ownDataSubject.close();
    _finalDataSubject.drain().then((value) => _finalDataSubject.close());
    return super.close();
  }
}
