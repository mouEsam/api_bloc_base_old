import 'package:api_bloc_base/api_bloc_base.dart';

import 'working_state.dart';

abstract class PaginatedState<T> {
  PaginatedOutput<T> get paginatedData;
}

class PaginatedLoadedState<T> extends LoadedState<T>
    implements PaginatedState<T> {
  final PaginatedOutput<T> paginatedData;

  const PaginatedLoadedState(this.paginatedData, T data) : super(data);

  @override
  List<Object?> get props => super.props..addAll([this.paginatedData]);
}

class LoadingNextPageState<T> extends LoadedState<T> {
  const LoadingNextPageState(T data) : super(data);
}

class ErrorGettingNextPageState<T> extends LoadedState<T> {
  final String? message;

  const ErrorGettingNextPageState(T data, this.message) : super(data);

  @override
  List<Object?> get props => [...super.props, this.message];
}
