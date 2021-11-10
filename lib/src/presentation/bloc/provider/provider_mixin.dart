import 'dart:async';

import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:flutter/cupertino.dart';

import 'state.dart';

mixin ProviderMixin<Data> on BaseCubit<ProviderState<Data>> {
  @mustCallSuper
  Future<void> fetchData({bool refresh = false});
  Future<void> refreshData();
  void injectInput(Data input);

  ProviderState<Data> createLoadingState<Data>() {
    return ProviderLoading<Data>();
  }

  ProviderState<Data> createLoadedState<Data>(Data data) {
    return ProviderLoaded<Data>(data);
  }

  ProviderState<Data> createErrorState<Data>(ResponseEntity message) {
    return ProviderError<Data>(message);
  }

  void emitState(ProviderState<Data> state) {
    if (state is ProviderLoading<Data>) {
      emitLoading();
    } else if (state is ProviderLoaded<Data>) {
      emitLoaded(state.data);
    } else if (state is ProviderError<Data>) {
      emitError(state.response);
    }
  }

  void emitLoading() {
    emit(createLoadingState<Data>());
  }

  void emitLoaded(Data data) {
    emit(createLoadedState<Data>(data));
  }

  void invalidate() {
    emit(Invalidated<Data>());
  }

  void emitError(ResponseEntity response) {
    emit(createErrorState<Data>(response));
  }
}
