import 'package:api_bloc_base/api_bloc_base.dart';

import 'working_state.dart';

abstract class PaginatedState<T> {
  PaginatedData<T> get paginatedData;
}

class PaginatedLoadedState<T> extends LoadedState<T>
    implements PaginatedState<T> {
  final PaginatedData<T> paginatedData;

  const PaginatedLoadedState(this.paginatedData, T data) : super(data);
}

class LoadingStateWithPreviousData<T> extends LoadedState<T> {
  const LoadingStateWithPreviousData(T data) : super(data);
}

class ErrorStateWithPreviousData<T> extends LoadedState<T> {
  final String message;

  const ErrorStateWithPreviousData(T data, this.message) : super(data);

  @override
  List<Object> get props => [...super.props, this.message];
}
