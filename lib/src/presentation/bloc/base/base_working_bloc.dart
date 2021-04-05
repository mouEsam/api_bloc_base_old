import 'dart:async';

import 'package:api_bloc_base/src/data/model/remote/base_api_response.dart';
import 'package:api_bloc_base/src/data/repository/base_repository.dart';
import 'package:api_bloc_base/src/domain/entity/entity.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:async/async.dart' as async;
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../base_provider/base_provider_bloc.dart' as provider;
import 'base_converter_bloc.dart';

export 'working_state.dart';

abstract class BaseWorkingBloc<Input, Output> extends Cubit<BlocState<Output>> {
  static const _DEFAULT_OPERATION = '_DEFAULT_OPERATION';

  String get notFoundMessage => 'foundNothing';
  String get loading => 'loading';
  String get defaultError => 'Error';

  Output currentData;

  StreamSubscription subscription;

  Stream<provider.ProviderState<Input>> get source => sourceBloc?.stateStream;

  final provider.BaseProviderBloc<Input> sourceBloc;

  final _eventsSubject = StreamController<provider.ProviderState<Input>>();
  StreamSink<provider.ProviderState<Input>> get eventSink =>
      _eventsSubject.sink;
  Stream<provider.ProviderState<Input>> get eventStream =>
      async.LazyStream(() => _eventsSubject.stream
          .asBroadcastStream(onCancel: (sub) => sub.cancel()));
  final _statesSubject = BehaviorSubject<BlocState<Output>>();
  Stream<BlocState<Output>> get stateStream =>
      async.LazyStream(() => _statesSubject.shareValue());

  Map<String, Tuple3<String, CancelToken, Stream<double>>> _operationStack = {};

  BaseWorkingBloc(this.currentData, {this.sourceBloc}) : super(LoadingState()) {
    listen((state) {
      _statesSubject.add(state);
    });
    subscription = eventStream.listen(handleEvent, onError: (e, s) {
      print(this);
      print(e);
      print(s);
      emit(ErrorState(defaultError));
    });
    source?.pipe(eventSink);
  }

  Output Function(Input input) get converter => null;

  void handleEvent(provider.ProviderState event) {
    if (event is provider.ProviderLoadingState<Input>) {
      emitLoading();
    } else if (event is provider.ProviderLoadedState<Input>) {
      handleData(event.data);
    } else if (event is provider.ProviderErrorState<Input>) {
      emit(ErrorState<Output>(event.message));
    }
  }

  @mustCallSuper
  void handleData(Input event) {
    if (event == null) {
      emit(ErrorState<Output>(notFoundMessage));
    } else {
      currentData = converter(event);
      emitLoaded();
    }
  }

  void emitLoading() {
    emit(LoadingState<Output>());
  }

  void interceptOperation<S>(Result<Either<ResponseEntity, S>> result,
      {void onSuccess(), void onFailure(), void onDate(S data)}) {
    result.resultFuture.then((value) {
      value.fold((l) {
        if (l is Success) {
          onSuccess?.call();
        } else if (l is Failure) {
          onFailure?.call();
        }
      }, (r) {
        onSuccess?.call();
        onDate?.call(r);
      });
    });
  }

  void interceptResponse(Result<ResponseEntity> result,
      {void onSuccess(), void onFailure()}) {
    result.resultFuture.then((value) {
      if (value is Success) {
        onSuccess?.call();
      } else if (value is Failure) {
        onFailure?.call();
      }
    });
  }

  void checkOperations() {
    if (_operationStack.isNotEmpty && state is! Operation) {
      final item = _operationStack.entries.first;
      startOperation(item.value.value1, item.value.value2, item.value.value3,
          operationTag: item.key);
    }
  }

  Future<T> handleDataOperation<T extends Entity>(
      Result<Either<ResponseEntity, T>> result,
      {String loadingMessage,
      String successMessage,
      String operationTag = _DEFAULT_OPERATION}) async {
    startOperation(loadingMessage, result.cancelToken, result.progress,
        operationTag: operationTag);
    final future = await result.resultFuture;
    return future.fold<T>(
      (l) {
        handleResponse(l, operationTag: operationTag);
        return null;
      },
      (r) {
        successfulOperation(
          successMessage,
          operationTag: operationTag,
        );
        return r;
      },
    );
  }

  Future<void> handleOperation(Result<ResponseEntity> result,
      {String loadingMessage,
      String successMessage,
      String operationTag = _DEFAULT_OPERATION}) async {
    startOperation(loadingMessage, result.cancelToken, result.progress,
        operationTag: operationTag);
    final future = await result.resultFuture;
    handleResponse(future, operationTag: operationTag);
  }

  void handleResponse(ResponseEntity l,
      {String operationTag = _DEFAULT_OPERATION,
      bool failure = true,
      bool success = true}) {
    if (l is Failure) {
      if (failure) {
        failedOperation(l.message,
            errors: l.errors, operationTag: operationTag);
      }
    } else if (l is Success) {
      if (success) {
        successfulOperation(l.message, operationTag: operationTag);
      }
    } else {
      removeOperation(operationTag: operationTag);
    }
  }

  void emitLoaded() {
    emit(LoadedState<Output>(currentData));
  }

  void startOperation(
      String message, CancelToken token, Stream<double> progress,
      {String operationTag = _DEFAULT_OPERATION}) {
    message ??= loading;
    emit(OnGoingOperationState(
      data: currentData,
      loadingMessage: message,
      operationTag: operationTag,
      progress: progress,
    ));
    _operationStack[operationTag] = Tuple3(message, token, progress);
    checkOperations();
  }

  void cancelOperation({String operationTag = _DEFAULT_OPERATION}) {
    emitLoaded();
    final tuple = _operationStack.remove(operationTag);
    if (tuple.value2?.isCancelled == false) {
      tuple.value2.cancel();
    }
    checkOperations();
  }

  void removeOperation({String operationTag = _DEFAULT_OPERATION}) {
    _operationStack.remove(operationTag);
    emitLoaded();
    checkOperations();
  }

  void successfulOperation(String message,
      {String operationTag = _DEFAULT_OPERATION}) {
    emit(SuccessfulOperationState(
        data: currentData,
        successMessage: message,
        operationTag: operationTag));
    _operationStack.remove(operationTag);
    checkOperations();
  }

  void failedOperation(String message,
      {BaseErrors errors, String operationTag = _DEFAULT_OPERATION}) {
    emit(FailedOperationState(
        data: currentData,
        errorMessage: message,
        operationTag: operationTag,
        errors: errors));
    _operationStack.remove(operationTag);
    checkOperations();
  }

  @mustCallSuper
  void getData() {
    emitLoading();
  }

  @override
  Future<void> close() {
    subscription?.cancel();
    _statesSubject.drain().then((value) => _statesSubject.close());
    _eventsSubject.close();
    return super.close();
  }
}
