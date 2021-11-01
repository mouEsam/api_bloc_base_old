import 'package:api_bloc_base/api_bloc_base.dart';

import 'user_dependant_mixin.dart';

abstract class BaseUserAwareBloc<Input, Output>
    extends BaseIndependentBloc<Input, Output>
    with UserDependantMixin<Input, Output> {
  final BaseUserBloc userBloc;

  BaseUserAwareBloc(this.userBloc,
      {List<Stream<ProviderState>> sources = const [],
      Output? currentData,
      LifecycleObserver? lifecycleObserver})
      : super(
            currentData: currentData,
            sources: sources,
            lifecycleObserver: lifecycleObserver) {
    setUpUserListener();
    setIndependenceUp();
  }
}
