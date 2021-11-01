import 'dart:async';

import 'package:async/async.dart';
import 'package:async/async.dart' as async;
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../base_provider/base_provider_bloc.dart' as provider;
import 'base_working_bloc.dart';

export 'working_state.dart';

abstract class BaseConverterBloc<Input, Output>
    extends BaseWorkingBloc<Output> {
  late final StreamSubscription eventSubscription;

  StreamSubscription? _inputSubscription;

  get initialState => LoadingState();

  late final Stream<provider.ProviderState<Input>> source;

  final provider.BaseProviderBloc<Input>? sourceBloc;

  Stream<provider.ProviderState<Output>> get providerStream =>
      async.LazyStream(() => stateStream
          .map((event) {
            if (event is LoadingState<Output>) {
              return provider.ProviderLoadingState<Output>();
            } else if (event is LoadedState<Output>) {
              return provider.ProviderLoadedState<Output>(event.data);
            } else if (event is ErrorState<Output>) {
              return provider.ProviderErrorState<Output>(event.message);
            }
          })
          .whereType<provider.ProviderState<Output>>()
          .asBroadcastStream(onCancel: (sub) => sub.cancel()));

  // final BehaviorSubject<BlocState<Output>> _statesSubject =
  //     BehaviorSubject<BlocState<Output>>();
  Stream<BlocState<Output>> get stateStream =>
      async.LazyStream(() => stream.startWith(state).shareValue());

  final _inputSubject = StreamController<Input>.broadcast();
  Stream<Input> get inputStream => LazyStream(() => _inputSubject.stream);
  StreamSink<Input> get inputSink => _inputSubject.sink;

  BaseConverterBloc({Output? currentData, this.sourceBloc})
      : super(currentData) {
    getData();
    _inputSubscription = inputStream.listen(handleInput, onError: (e, s) {
      print(e);
      print(s);
      emit(ErrorState(defaultError));
    });
    if (sourceBloc != null) {
      source = sourceBloc!.stateStream;
    }
    eventSubscription =
        source.shareValue().listen(handleEvent, onError: (e, s) {
      print(this);
      print(e);
      print(s);
      emit(ErrorState(defaultError));
    });
  }

  Output convertInput(Input input);

  void clean() {
    // currentData = null;
  }

  void handleEvent(provider.ProviderState event) {
    if (event is provider.ProviderLoadingState<Input>) {
      handleLoadingState(event);
    } else if (event is provider.ProviderLoadedState<Input>) {
      inputSink.add(event.data);
    } else if (event is provider.ProviderErrorState<Input>) {
      handleErrorState(event);
    }
  }

  @mustCallSuper
  void handleErrorState(provider.ProviderErrorState<Input> errorState) {
    emit(ErrorState<Output>(errorState.message));
  }

  @mustCallSuper
  void handleLoadingState(provider.ProviderLoadingState<Input> loadingState) {
    emitLoading();
  }

  @mustCallSuper
  void handleInput(Input event) {
    if (event == null) {
      emit(ErrorState<Output>(notFoundMessage));
    } else {
      setData(convertOutput(convertInput(event)));
    }
  }

  Output convertOutput(Output output) {
    return output;
  }

  @mustCallSuper
  void setData(Output newData) {
    currentData = newData;
    emitLoaded();
  }

  @mustCallSuper
  Future<void> getData([bool refresh = false]) async {
    if (!refresh) emitLoading();
    return null;
  }

  Future<void> reset() async {
    //currentData = null;
    wasInitialized = false;
    return getData();
  }

  @mustCallSuper
  Future<void> refresh() async {
    sourceBloc?.refresh();
    return getData(true);
  }

  @override
  Future<void> close() {
    _inputSubscription?.cancel();
    eventSubscription.cancel();
    _inputSubject.close();
    // _statesSubject.drain().then((value) => _statesSubject.close());
    return super.close();
  }
}
