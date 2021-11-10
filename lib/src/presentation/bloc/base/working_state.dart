import 'package:api_bloc_base/src/data/model/remote/params/base_errors.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

class BlocState<T> extends Equatable {
  const BlocState();

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [];
}

class LoadingState<T> extends BlocState<T> {}

class ErrorState<T> extends BlocState<T> {
  final String? message;

  const ErrorState(this.message);

  @override
  List<Object?> get props => [this.message];
}

class LoadedState<T> extends BlocState<T> {
  final T data;

  const LoadedState(this.data);

  @override
  List<Object?> get props => [this.data];
}

abstract class Operation {
  String get operationTag;
  bool get silent;
}

class OnGoingOperationState<T> extends LoadedState<T> implements Operation {
  final String? loadingMessage;
  final CancelToken? token;
  final Stream<double>? progress;
  final String operationTag;
  final bool silent;

  const OnGoingOperationState(T data,
      {required this.silent,
      required this.operationTag,
      this.loadingMessage,
      this.token,
      this.progress})
      : super(data);

  @override
  List<Object?> get props => [
        ...super.props,
        this.operationTag,
        this.loadingMessage,
        this.token,
        this.progress,
        this.silent
      ];
}

class FailedOperationState<T> extends LoadedState<T> implements Operation {
  final String operationTag;
  final Failure? failure;
  final Function()? retry;
  final bool silent;

  const FailedOperationState(T data,
      {required this.operationTag,
      required this.silent,
      this.failure,
      this.retry})
      : super(data);

  FailedOperationState.message(T data,
      {required this.operationTag,
      required this.silent,
      String? errorMessage,
      BaseErrors? errors,
      this.retry})
      : failure = Failure(errorMessage, errors),
        super(data);

  String? get message {
    final errors =
        failure?.errors?.errors.values.expand((element) => element).toList();
    if (errors != null && errors.isNotEmpty) {
      return errors.first;
    } else {
      return failure?.message;
    }
  }

  String? get errorMessage => failure?.message;
  BaseErrors? get errors => failure?.errors;

  @override
  List<Object?> get props => [
        ...super.props,
        this.operationTag,
        this.failure,
        this.retry,
        this.silent
      ];
}

class SuccessfulOperationState<T> extends LoadedState<T> implements Operation {
  final String operationTag;
  final String? successMessage;
  final bool silent;

  const SuccessfulOperationState(T data,
      {required this.operationTag, required this.silent, this.successMessage})
      : super(data);

  @override
  List<Object?> get props =>
      [...super.props, this.operationTag, this.successMessage, this.silent];
}
