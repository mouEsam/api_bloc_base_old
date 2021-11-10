import 'package:equatable/equatable.dart';

abstract class ProviderState<T> extends Equatable {
  const ProviderState();

  @override
  bool get stringify => true;

  @override
  get props => [];
}

class ProviderLoadingState<T> extends ProviderState<T> {}

class InvalidatedState<T> extends ProviderState<T> {}

class ProviderLoadedState<T> extends ProviderState<T> {
  final T data;

  const ProviderLoadedState(this.data);

  @override
  get props => [this.data];
}

class ProviderErrorState<T> extends ProviderState<T> {
  final String? message;

  const ProviderErrorState(this.message);

  @override
  get props => [this.message];
}
