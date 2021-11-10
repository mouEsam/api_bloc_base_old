import 'dart:async';

import '../../../../api_bloc_base.dart';
import 'base_provider_bloc.dart';
import 'user_dependant_state.dart';

mixin UserDependantProviderMixin<Data> on BaseProviderBloc<Data> {
  DateTime? _lastLogin;
  BaseUserBloc? get userBloc => null;
  String? authToken;
  get userId => userBloc!.currentUser?.id;
  String get requireAuthToken => authToken!;
  StreamSubscription? _subscription;

  bool _isAGo = false;

  bool get isAGo => _isAGo;

  void setUpUserListener() {
    _subscription = userBloc!.userStream.listen(
      (user) {
        final newToken = user?.accessToken;
        if (newToken != null) {
          if (newToken != authToken) {
            authToken = newToken;
            if (shouldStart(user!)) {
              startTries();
              _isAGo = true;
              _lastLogin = DateTime.now();
              print("starting");
            }
          }
        } else {
          authToken = null;
          stopRetries();
          _isAGo = false;
          print("stopping");
        }
      },
    );
  }

  bool shouldStart(BaseProfile user) => true;

  ProviderState<Data> createLoadedState<Data>(Data data) {
    return UserDependentProviderLoadedState<Data>(data, _lastLogin);
  }

  ProviderState<Data> createErrorState<Data>(String? message) {
    return UserDependentProviderErrorState<Data>(message, _lastLogin);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
