import 'package:api_bloc_base/src/presentation/bloc/user/base_user_bloc.dart';

import 'base_provider_bloc.dart';
import 'lifecycle_observer.dart';
import 'user_dependant_mixin.dart';

abstract class UserDependantProvider<Data> extends BaseProviderBloc<Data>
    with UserDependantProviderMixin<Data> {
  final BaseUserBloc userBloc;

  UserDependantProvider(this.userBloc,
      {Data initialData, LifecycleObserver lifecycleObserver})
      : super(
            initialDate: initialData,
            getOnCreate: false,
            observer: lifecycleObserver) {
    setUpUserListener();
  }
}
