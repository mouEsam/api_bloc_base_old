import 'dart:async';
import 'dart:math';

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:async/async.dart' as async;
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

class PaginatedInput<T> extends Equatable {
  final T input;
  final String? nextUrl;
  final int currentPage;

  const PaginatedInput(this.input, this.nextUrl, this.currentPage);

  @override
  get props => [this.input, this.nextUrl, this.currentPage];
}

class PaginatedData<T> extends Equatable {
  final Map<int, T> data;
  final bool isThereMore;
  final int currentPage;
  final String? nextPage;

  const PaginatedData(
      this.data, this.isThereMore, this.currentPage, this.nextPage);

  @override
  get props => [this.data, this.isThereMore, this.currentPage];
}

mixin PaginatedMixin<Output>
    on BaseConverterBloc<PaginatedInput<Output>, Output> {
  // IMPORTANT!
  Duration? get refreshInterval => null;

  int get startPage => 1;

  String? nextPage;

  int? _currentPage;

  int get currentPage => _currentPage ?? startPage;
  int get lastPage =>
      _paginatedData?.data.keys.fold(
          0, ((previousValue, element) => max(previousValue!, element))) ??
      2;

  bool get canGoBack => currentPage > startPage;
  bool get canGoForward => currentPage < lastPage || isThereMore;
  bool get isThereMore => _paginatedData?.isThereMore ?? true;

  PaginatedData<Output> get paginatedData => _paginatedData!;

  PaginatedData<Output>? _paginatedData;

  Stream<PaginatedData<Output>?> get paginatedStream => async.LazyStream(
      () => stateStream.map((event) => _paginatedData).distinct());

  @override
  void handleInput(event) {
    if (currentPage == event.currentPage) {
      nextPage = event.nextUrl;
    }
    super.handleInput(event);
  }

  @override
  @mustCallSuper
  void setData(newData) {
    final isThereMore = canGetMore(newData);
    final map = _paginatedData?.data ?? <int, Output>{};
    final newMap = Map.of(map);
    newMap[currentPage] = newData;
    _paginatedData = PaginatedData(newMap, isThereMore, currentPage, nextPage);
    super.setData(newData);
  }

  bool canGetMore(Output newData) {
    if (nextPage == null) {
      return false;
    } else if (newData == null) {
      return false;
    } else if (newData is Iterable) {
      return newData.isNotEmpty;
    } else if (newData is Map) {
      return newData.isNotEmpty;
    } else {
      try {
        dynamic d = newData;
        return d.count > 0;
      } catch (e) {
        return false;
      }
    }
  }

  Future<void> next() async {
    if (canGoForward) {
      _currentPage = currentPage + 1;
      final nextData = _paginatedData?.data[_currentPage!];
      if (nextData != null) {
        setData(nextData);
        emitLoaded();
      }
      return super.getData();
    }
  }

  Future<void> back() async {
    if (canGoBack) {
      _currentPage = _currentPage! - 1;
      final previousData = _paginatedData!.data[_currentPage!]!;
      setData(previousData);
      emitLoaded();
    }
  }

  void clean() {
    super.clean();
    _currentPage = startPage;
    _paginatedData = null;
    nextPage = null;
  }

  @override
  Future<void> reset() {
    clean();
    return super.reset();
  }

  @override
  Future<void> refresh() {
    clean();
    return super.refresh();
  }

  @override
  void handleErrorState(errorState) {
    if (currentPage != startPage) {
      _currentPage = _currentPage! - 1;
    } else {
      _currentPage = null;
    }
    if (!wasInitialized || safeData == null) {
      super.handleErrorState(errorState);
    } else {
      emit(ErrorGettingNextPageState<Output>(currentData, errorState.message));
    }
  }

  @override
  void handleLoadingState(loadingState) {
    if (!wasInitialized || safeData == null) {
      super.handleLoadingState(loadingState);
    } else {
      emit(LoadingNextPageState<Output>(currentData));
    }
  }

  @override
  void emitLoaded() {
    emit(PaginatedLoadedState(_paginatedData, currentData));
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
