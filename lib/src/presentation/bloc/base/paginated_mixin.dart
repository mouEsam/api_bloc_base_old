import 'dart:async';

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:async/async.dart' as async;
import 'package:equatable/equatable.dart';

class PaginatedData<T> extends Equatable {
  final Map<int, T> data;
  final bool isThereMore;
  final int currentPage;

  const PaginatedData(this.data, this.isThereMore, this.currentPage);

  @override
  get props => [this.data, this.isThereMore, this.currentPage];
}

mixin PaginatedMixin<Input, Output> on BaseConverterBloc<Input, Output> {
  int get startPage => 1;

  int _currentPage;

  int get currentPage => _currentPage ?? startPage;

  bool get isThereMore => paginatedData?.isThereMore ?? true;

  PaginatedData<Output> paginatedData;
  Stream<PaginatedData<Output>> get paginatedStream => async.LazyStream(
      () => stateStream.map((event) => paginatedData).distinct());

  @override
  void setData(Output newData) {
    final isThereMore = canGetMore(newData);
    final map = paginatedData?.data ?? <int, Output>{};
    final newMap = Map.of(map);
    newMap[currentPage] = newData;
    paginatedData = PaginatedData(newMap, isThereMore, currentPage);
    super.setData(newData);
  }

  bool canGetMore(Output newData) {
    if (newData == null) {
      return false;
    } else if (newData is Iterable) {
      return newData.isNotEmpty;
    } else if (newData is Map) {
      return newData.isNotEmpty;
    } else {
      try {
        dynamic d = newData;
        return d.newPageLength > 0;
      } catch (e) {
        return false;
      }
    }
  }

  Future<Output> next() {
    _currentPage++;
    return super.getData();
  }

  void clean() {
    super.clean();
    _currentPage = startPage;
    paginatedData = null;
  }

  @override
  Future<Output> reset() {
    clean();
    return super.reset();
  }

  @override
  Future<Output> refresh() {
    clean();
    return super.refresh();
  }

  @override
  void handleErrorState(errorState) {
    if (currentPage != startPage) {
      _currentPage--;
    } else {
      _currentPage = null;
    }
    if (currentData == null) {
      super.handleErrorState(errorState);
    } else {
      emit(ErrorGettingNextPageState<Output>(currentData, errorState.message));
    }
  }

  @override
  void handleLoadingState(loadingState) {
    if (currentData == null) {
      super.handleLoadingState(loadingState);
    } else {
      emit(LoadingNextPageState<Output>(currentData));
    }
  }

  @override
  void emitLoaded() {
    emit(PaginatedLoadedState(paginatedData, currentData));
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
