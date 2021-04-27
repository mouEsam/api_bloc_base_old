import 'package:api_bloc_base/api_bloc_base.dart';

import 'user_dependant_mixin.dart';

abstract class BaseUserAwareBloc<Output> extends BaseIndependentBloc<Output>
    with UserDependantMixin<Output> {
  final BaseUserBloc userBloc;

  BaseUserAwareBloc(this.userBloc,
      {List<Stream<ProviderState>> sources = const [], Output currentData})
      : super(currentData: currentData, sources: sources) {
    setUpUserListener();
  }
}
