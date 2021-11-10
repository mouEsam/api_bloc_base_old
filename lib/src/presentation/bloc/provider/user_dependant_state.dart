import 'package:api_bloc_base/api_bloc_base.dart';

import 'state.dart';

abstract class UserDependentProviderState {
  get tag;
}

class UserDependentProviderLoadedState<T> extends ProviderLoaded<T>
    implements UserDependentProviderState {
  final dynamic tag;

  const UserDependentProviderLoadedState(T data, this.tag) : super(data);

  @override
  get props => super.props..addAll([tag]);
}

class UserDependentProviderErrorState<T> extends ProviderError<T>
    implements UserDependentProviderState {
  final dynamic tag;

  const UserDependentProviderErrorState(ResponseEntity response, this.tag)
      : super(response);

  @override
  get props => super.props..addAll([tag]);
}
