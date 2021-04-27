import 'package:api_bloc_base/api_bloc_base.dart';

mixin PaginatedMixin<Data> on BaseConverterBloc<dynamic, Data> {
  int get startPage => 1;

  int _currentPage;

  int get currentPage => _currentPage ?? startPage;

  @override
  void setData(Data newData) {
    final data = appendData(newData, currentData);
    super.setData(data);
  }

  Data appendData(Data newData, Data oldData);

  @override
  Future<Data> reset() {
    _currentPage = startPage;
    currentData = null;
    return super.reset();
  }

  @override
  Future<Data> refresh() {
    _currentPage = startPage;
    currentData = null;
    return super.refresh();
  }

  @override
  void handleErrorState(errorState) {
    if (currentData == null) {
      super.handleErrorState(errorState);
    } else {
      emit(PaginatedErrorState<Data>(currentData, errorState.message));
    }
  }

  @override
  void handleLoadingState(loadingState) {
    if (currentData == null) {
      super.handleLoadingState(loadingState);
    } else {
      emit(PaginatedLoadingState<Data>(currentData));
    }
  }
}