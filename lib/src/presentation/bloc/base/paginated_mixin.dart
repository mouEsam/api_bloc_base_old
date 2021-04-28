import 'dart:async';

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:async/async.dart' as async;
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

class PaginatedData<T> extends Equatable {
  final T newData;
  final T allData;
  final int currentPage;

  const PaginatedData(this.newData, this.allData, this.currentPage);

  bool get isThereMore {
    bool isThereMore = newData != null;
    if (newData is Iterable) {
      Iterable d = newData as Iterable;
      isThereMore = d.isNotEmpty;
    } else if (newData is Map) {
      Map m = newData as Map;
      isThereMore = m.isNotEmpty;
    } else {
      try {
        dynamic d = newData;
        isThereMore = d.newLength > 0;
      } catch (e) {}
    }
    return isThereMore;
  }

  @override
  get props => [this.newData, this.allData, this.currentPage];
}

mixin PaginatedMixin<Input, Output> on BaseConverterBloc<Input, Output> {
  int get startPage => 1;

  int _currentPage;

  int get currentPage => _currentPage ?? startPage;

  bool get isThereMore => latestPage?.isThereMore ?? true;

  final _paginatedSubject = BehaviorSubject<PaginatedData<Output>>();
  PaginatedData<Output> get latestPage => _paginatedSubject.value;
  Stream<PaginatedData<Output>> get paginatedStream =>
      async.LazyStream(() => _paginatedSubject.shareValue());

  @override
  void setData(Output newData) {
    final data = appendData(newData, currentData);
    _paginatedSubject.value = PaginatedData(newData, data, currentPage);
    super.setData(data);
  }

  Output appendData(Output newData, Output oldData);

  Future<Output> next() {
    _currentPage++;
    return super.getData();
  }

  void clean() {
    super.clean();
    _currentPage = startPage;
    _paginatedSubject.value = null;
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
      _paginatedSubject.value = PaginatedData(null, currentData, currentPage);
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
    emit(PaginatedLoadedState(latestPage, currentData));
  }

  @override
  Future<void> close() {
    _paginatedSubject.drain().then((value) => _paginatedSubject.close());
    return super.close();
  }
}
