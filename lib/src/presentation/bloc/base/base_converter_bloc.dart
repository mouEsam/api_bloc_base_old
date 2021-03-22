import 'dart:async';

import 'package:async/async.dart';
import 'package:rxdart/rxdart.dart';

import '../base_provider/base_provider_bloc.dart' as provider;
import 'base_working_bloc.dart';

export 'working_state.dart';

abstract class BaseConverterBloc<Input, Output>
    extends BaseWorkingBloc<Input, Output> {
  StreamSubscription _subscription;

  final _inputSubject = BehaviorSubject<Input>();
  Stream<Input> get inputStream => LazyStream(() => _inputSubject.shareValue());
  StreamSink<Input> get inputSink => _inputSubject.sink;

  BaseConverterBloc(
      {Output currentData, provider.BaseProviderBloc<Input> sourceBloc})
      : super(currentData, sourceBloc: sourceBloc) {
    _subscription = inputStream.listen(handleData, onError: (e, s) {
      print(e);
      print(s);
      emit(ErrorState(defaultError));
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _inputSubject.drain().then((value) => _inputSubject.close());
    return super.close();
  }
}
