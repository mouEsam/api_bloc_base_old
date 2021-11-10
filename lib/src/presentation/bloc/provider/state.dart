import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:equatable/equatable.dart';

abstract class ProviderState<T> extends Equatable {
  const ProviderState();

  @override
  bool get stringify => true;

  @override
  get props => [];
}

class ProviderLoading<T> extends ProviderState<T> {}

class Invalidated<T> extends ProviderState<T> {}

class ProviderLoaded<T> extends ProviderState<T> {
  final T data;

  const ProviderLoaded(this.data);

  @override
  get props => [this.data];
}

class ProviderError<T> extends ProviderState<T> {
  final ResponseEntity response;

  const ProviderError(this.response);

  @override
  get props => [this.response];
}
