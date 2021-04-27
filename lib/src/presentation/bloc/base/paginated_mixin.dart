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

  @override
  get props => [this.newData, this.allData, this.currentPage];
}

mixin PaginatedMixin<Input, Output> on BaseConverterBloc<Input, Output> {
  int get startPage => 1;

  int _currentPage;

  int get currentPage => _currentPage ?? startPage;

  final _paginatedSubject = BehaviorSubject<PaginatedData<Output>>();
  Stream<PaginatedData<Output>> get paginatedStream =>
      async.LazyStream(() => _paginatedSubject.shareValue());

  @override
  void setData(Output newData) {
    final data = appendData(newData, currentData);
    _paginatedSubject.add(PaginatedData(newData, data, currentPage));
    super.setData(data);
  }

  Output appendData(Output newData, Output oldData);

  Future<Output> next() {
    _currentPage++;
    return super.getData();
  }

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
    if (currentPage != startPage) {
      _currentPage--;
    } else {
      _currentPage = null;
    }
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

  @override
  Future<void> close() {
    _paginatedSubject.drain().then((value) => _paginatedSubject.close());
    return super.close();
  }
}
