import 'package:api_bloc_base/api_bloc_base.dart';

mixin PaginatedMixin<Input, Output> on BaseConverterBloc<Input, Output> {
  int get startPage => 1;

  int _currentPage;

  int get currentPage => _currentPage ?? startPage;

  @override
  void setData(Output newData) {
    final data = appendData(newData, currentData);
    super.setData(data);
  }

  Output appendData(Output newData, Output oldData);

  @override
  Future<Output> reset() {
    _currentPage = startPage;
    currentData = null;
    return super.reset();
  }

  @override
  Future<Output> refresh() {
    _currentPage = startPage;
    currentData = null;
    return super.refresh();
  }

  @override
  void handleErrorState(errorState) {
    if (currentData == null) {
      super.handleErrorState(errorState);
    } else {
      emit(PaginatedErrorState<Output>(currentData, errorState.message));
    }
  }

  @override
  void handleLoadingState(loadingState) {
    if (currentData == null) {
      super.handleLoadingState(loadingState);
    } else {
      emit(PaginatedLoadingState<Output>(currentData));
    }
  }
}
