import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:api_bloc_base/src/presentation/bloc/user/base_user_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import 'lifecycle_observer.dart';
import 'provider.dart';

class SimpleUserProvider<UserType extends BaseProfile>
    extends ProviderBloc<UserType> {
  String get notSignedInError => 'Not Signed In Error';

  final BaseUserBloc<UserType> userBloc;

  SimpleUserProvider(this.userBloc, LifecycleObserver appLifecycleObserver)
      : super(
            getOnCreate: true,
            streamDataSource: Right(userBloc.userStream.whereType<UserType>()),
            appLifecycleObserver: appLifecycleObserver);
}
