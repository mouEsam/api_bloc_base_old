import 'dart:async';

import '../../../../api_bloc_base.dart';
import 'base_provider_bloc.dart';

mixin UserDependantProviderMixin<Data> on BaseProviderBloc<Data> {
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
            }
          }
        } else {
          authToken = null;
          stopRetries();
          _isAGo = false;
        }
      },
    );
  }

  bool shouldStart(BaseProfile user) => true;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
