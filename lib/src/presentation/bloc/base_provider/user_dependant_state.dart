import 'package:api_bloc_base/src/presentation/bloc/base_provider/provider_state.dart';

abstract class UserDependentProviderState {
  get tag;
}

class UserDependentProviderLoadedState<T> extends ProviderLoadedState<T>
    implements UserDependentProviderState {
  final dynamic tag;

  const UserDependentProviderLoadedState(T data, this.tag) : super(data);

  @override
  get props => super.props..addAll([tag]);
}

class UserDependentProviderErrorState<T> extends ProviderErrorState<T>
    implements UserDependentProviderState {
  final dynamic tag;

  const UserDependentProviderErrorState(String? message, this.tag)
      : super(message);

  @override
  get props => super.props..addAll([tag]);
}
