import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

abstract class BaseCubit<State> extends Cubit<State> {
  BaseCubit(State initialState) : super(initialState);

  Stream<State> get exclusiveStream => super.stream;

  @override
  get stream => super.stream.startWith(state).map((e) => state);
}
