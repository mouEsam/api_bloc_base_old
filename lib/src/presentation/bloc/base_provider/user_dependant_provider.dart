import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/user/base_user_bloc.dart';

import 'base_provider_bloc.dart';

abstract class UserDependantProvider<Data> extends BaseProviderBloc<Data> {
  final BaseUserBloc userBloc;
  String authToken;
  get userId => userBloc.currentUser?.id;
  StreamSubscription _subscription;

  UserDependantProvider(this.userBloc, {Data initialData})
      : super(initialDate: initialData, getOnCreate: false) {
    _subscription = userBloc.userStream.listen(
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
