import 'dart:async';

import 'package:api_bloc_base/src/data/repository/base_repository.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

import 'state.dart';

mixin ProviderMixin<Data> on BaseCubit<ProviderState<Data>> {
  @mustCallSuper
  Future<void> fetchData({bool refresh = false});
  Future<void> refreshData();
  void injectInput(Data input);
  void clean();

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

  void interceptOperation<S>(Result<Either<ResponseEntity, S>> result,
      {void onSuccess()?, void onFailure()?, void onDate(S data)?}) {
    result.resultFuture.then((value) {
      value.fold((l) {
        if (l is Success) {
          onSuccess?.call();
        } else if (l is Failure) {
          onFailure?.call();
        }
      }, (r) {
        if (onDate != null) {
          onDate(r);
        } else if (onSuccess != null) {
          onSuccess();
        }
      });
    });
  }

  void interceptResponse(Result<ResponseEntity> result,
      {void onSuccess()?, void onFailure()?}) {
    result.resultFuture.then((value) {
      if (value is Success) {
        onSuccess?.call();
      } else if (value is Failure) {
        onFailure?.call();
      }
    });
  }

  Stream<ProviderState<Out>> transformStream<Out>(
      {Out? outData, Stream<Out>? outStream}) {
    return stream.flatMap<ProviderState<Out>>((value) {
      if (value is ProviderLoading<Data>) {
        return Stream.value(ProviderLoading<Out>());
      } else if (value is ProviderError<Data>) {
        return Stream.value(ProviderError<Out>(value.response));
      } else if (value is Invalidated<Data>) {
        return Stream.value(Invalidated<Out>());
      } else {
        if (outData != null) {
          return Stream.value(ProviderLoaded<Out>(outData));
        } else if (outStream != null) {
          return outStream.map((event) => ProviderLoaded<Out>(event));
        }
        return Stream.empty();
      }
    }).asBroadcastStream(onCancel: ((sub) => sub.cancel()));
  }
}
