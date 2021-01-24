import 'package:api_bloc_base/src/data/model/remote/base_errors.dart';
import 'package:equatable/equatable.dart';

class BlocState<T> extends Equatable {
  const BlocState();

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [];
}

class LoadingState<T> extends BlocState<T> {}

class ErrorState<T> extends BlocState<T> {
  final String message;

  const ErrorState(this.message);

  @override
  List<Object> get props => [this.message];
}

class LoadedState<T> extends BlocState<T> {
  final T data;

  const LoadedState(this.data);

  @override
  List<Object> get props => [this.data];
}

abstract class Operation {
  String get operationTag;
}

class OnGoingOperationState<T> extends LoadedState<T> implements Operation {
  final String operationTag;
  final String loadingMessage;
  final Stream<double> progress;

  const OnGoingOperationState(
      {T data, this.loadingMessage, this.operationTag, this.progress})
      : super(data);

  @override
  List<Object> get props =>
      [...super.props, this.operationTag, this.loadingMessage, this.progress];
}

class FailedOperationState<T> extends LoadedState<T> implements Operation {
  final String operationTag;
  final String errorMessage;
  final BaseErrors errors;

  const FailedOperationState(
      {T data, this.operationTag, this.errorMessage, this.errors})
      : super(data);

  @override
  List<Object> get props =>
      [...super.props, this.operationTag, this.errorMessage];
}

class SuccessfulOperationState<T> extends LoadedState<T> implements Operation {
  final String operationTag;
  final String successMessage;

  const SuccessfulOperationState(
      {T data, this.operationTag, this.successMessage})
      : super(data);

  @override
  List<Object> get props =>
      [...super.props, this.operationTag, this.successMessage];
}
