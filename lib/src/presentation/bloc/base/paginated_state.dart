import 'working_state.dart';

abstract class PaginatedState {}

class PaginatedLoadingState<T> extends LoadedState<T>
    implements PaginatedState {
  PaginatedLoadingState(T data) : super(data);
}

class PaginatedErrorState<T> extends LoadedState<T> implements PaginatedState {
  final String message;

  const PaginatedErrorState(T data, this.message) : super(data);

  @override
  List<Object> get props => [...super.props, this.message];
}
