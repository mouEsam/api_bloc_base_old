import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'base_working_bloc.dart';

export 'working_state.dart';

abstract class BaseConverterBloc<Input, Output>
    extends BaseWorkingBloc<Input, Output> {
  String get notFoundMessage => 'foundNothing';
  String get defaultError => 'Error';

  StreamSubscription _subscription;

  final _inputSubject = BehaviorSubject<Input>();
  Stream<Input> get inputStream => _inputSubject.shareValue();
  StreamSink<Input> get inputSink => _inputSubject.sink;

  BaseConverterBloc() : super(null) {
    _subscription = inputStream.listen(_handler, onError: (e, s) {
      print(e);
      print(s);
      emit(ErrorState(defaultError));
    });
  }

  void _handler(Input event) {
    if (event == null) {
      emit(ErrorState<Output>(notFoundMessage));
    } else {
      currentData = converter(event);
      emitLoaded();
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _inputSubject.drain().then((value) => _inputSubject.close());
    return super.close();
  }
}
