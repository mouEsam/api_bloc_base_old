import 'dart:async';

import '../../../../api_bloc_base.dart';
import 'base_provider_bloc.dart';

mixin UserDependantProviderMixin<Data> on BaseProviderBloc<Data> {
  BaseUserBloc? get userBloc => null;
  String? authToken;
  get userId => userBloc!.currentUser?.id;
  String get requireAuthToken => authToken!;
  StreamSubscription? _subscription;

  void setUpUserListener() {
    _subscription = userBloc!.userStream.listen(
      (user) {
        final newToken = user?.accessToken;
        if (newToken != null) {
          if (newToken != authToken) {
            authToken = newToken;
            startTries();
          }
        } else {
          authToken = null;
          stopRetries();
        }
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
