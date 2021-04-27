import 'package:api_bloc_base/api_bloc_base.dart';

import 'working_state.dart';

abstract class PaginatedState<T> {
  PaginatedData<T> get paginatedData;
}

class PaginatedLoadingState<T> extends LoadedState<T>
    implements PaginatedState<T> {
  final PaginatedData<T> paginatedData;

  PaginatedLoadingState(this.paginatedData, T data) : super(data);
}

class PaginatedErrorState<T> extends LoadedState<T>
    implements PaginatedState<T> {
  final String message;
  final PaginatedData<T> paginatedData;

  const PaginatedErrorState(this.paginatedData, T data, this.message)
      : super(data);

  @override
  List<Object> get props => [...super.props, this.message];
}
