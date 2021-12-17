import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:api_bloc_base/src/presentation/bloc/user/base_user_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/user/base_user_state.dart';
import 'package:rxdart/rxdart.dart';

import 'base_provider_bloc.dart';
import 'lifecycle_observer.dart';

class BaseUserProvider<UserType extends BaseProfile>
    extends BaseProviderBloc<UserType> {
  String get notSignedInError => 'Not Signed In Error';

  final BaseUserBloc<UserType> userBloc;

  BaseUserProvider(this.userBloc, LifecycleObserver observer)
      : super(getOnCreate: true, observer: observer);

  @override
  get stateStream => userBloc.stream.map((userState) {
        if (userState is UserLoadingState) {
          return ProviderLoadingState<UserType>();
        } else if (userState is SignedOutState) {
          return ProviderErrorState<UserType>(notSignedInError);
        } else if (userState is BaseSignedInState<UserType>) {
          return ProviderLoadedState<UserType>(userState.userAccount);
        }
        return null;
      }).whereType<ProviderState<UserType>>();
    
    @override
  Future<void> refresh() {
      final oldState = state;
      emitLoading();
    return userBloc.autoSignIn(true).then((value) {
        emit(oldState);
        return userBloc.currentUser;
    });
  }
}
