import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

abstract class BaseCubit<State> extends Cubit<State> {
  BaseCubit(State initialState) : super(initialState);

  Stream<State> get exclusiveStream => super.stream;

  @override
  get stream => super.stream.shareValueSeeded(state).map((e) => state);

  List<ChangeNotifier> get notifiers => [];

  @override
  Future<void> close() {
    notifiers.forEach((element) {
      try {
        element.dispose();
      } catch (e) {
        print(e);
      }
    });
    return super.close();
  }

  @override
  void emit(State state) {
    print("$runtimeType ${this.state == state} emitting ${state.runtimeType}");
    super.emit(state);
  }
}
