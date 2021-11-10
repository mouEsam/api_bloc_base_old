import 'dart:async';
import 'dart:math';

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:async/async.dart' as async;
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

abstract class PaginatedInput<T> extends Equatable {
  final T input;
  final String? nextUrl;
  final int currentPage;

  const PaginatedInput(this.input, this.nextUrl, this.currentPage);

  @override
  get props => [this.input, this.nextUrl, this.currentPage];
}

class PaginatedOutput<T> extends Equatable {
  final Map<int, T> data;
  final bool isThereMore;
  final int currentPage;
  final String? nextPage;

  const PaginatedOutput(
      this.data, this.isThereMore, this.currentPage, this.nextPage);

  @override
  get props => [this.data, this.isThereMore, this.currentPage];
}

mixin PaginatedMixin<Paginated extends PaginatedInput<Output>, Output>
    on BaseConverterBloc<Paginated, Output> {
  static const int startPage = 1;

  PaginatedOutput<Output> get empty =>
      const PaginatedOutput({}, false, startPage, null);

  Paginated? lastInput;

  int? _currentPage;

  int get currentPage => _currentPage ?? startPage;
  int get lastPage => paginatedData.data.keys.fold(
      startPage, ((previousValue, element) => max(previousValue, element)));

  bool get canGoBack => currentPage > startPage;
  bool get canGoForward => currentPage < lastPage || isThereMore;
  bool get isThereMore => paginatedData.isThereMore;

  late PaginatedOutput<Output> paginatedData = empty;

  Stream<PaginatedOutput<Output>?> get paginatedStream => async.LazyStream(
      () => stateStream.map((event) => paginatedData).distinct());

  @override
  @mustCallSuper
  void handleInput(event) {
    if (currentPage == event.currentPage) {
      lastInput = event;
    }
    super.handleInput(event);
  }

  @override
  Output convertInput(input) {
    return input.input;
  }

  @override
  @mustCallSuper
  void setData(newData) {
    final isThereMore = canGetMore(newData);
    final map = paginatedData.data;
    final newMap = Map.of(map);
    newMap[currentPage] = newData;
    paginatedData =
        PaginatedOutput(newMap, isThereMore, currentPage, lastInput?.nextUrl);
    super.setData(newData);
  }

  bool canGetMore(Output newData) {
    if (lastInput?.nextUrl == null) {
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
      final nextData = paginatedData.data[_currentPage!];
      if (nextData != null) {
        setData(nextData);
        emitLoaded();
      } else {
        getData(true);
      }
    }
  }

  Future<void> back() async {
    if (canGoBack) {
      _currentPage = _currentPage! - 1;
      final previousData = paginatedData.data[_currentPage!]!;
      setData(previousData);
      emitLoaded();
    }
  }

  void clean() {
    super.clean();
    _currentPage = startPage;
    paginatedData = empty;
    lastInput = null;
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
    emit(PaginatedLoadedState(paginatedData, currentData));
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
