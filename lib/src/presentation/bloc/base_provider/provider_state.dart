import 'package:equatable/equatable.dart';

class ProviderState<T> extends Equatable {
  const ProviderState();

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [];
}

class LoadingState<T> extends ProviderState<T> {}

class InvalidatedState<T> extends ProviderState<T> {}

class LoadedState<T> extends ProviderState<T> {
  final T data;

  const LoadedState(this.data);

  @override
  List<Object> get props => [this.data];
}

class ErrorState<T> extends ProviderState<T> {
  final String message;

  const ErrorState(this.message);

  @override
  List<Object> get props => [this.message];
}
