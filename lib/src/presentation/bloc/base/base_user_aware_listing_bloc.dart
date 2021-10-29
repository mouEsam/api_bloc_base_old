import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/base_independant_listing_bloc.dart';

import 'base_listing_bloc.dart';
import 'user_dependant_mixin.dart';

abstract class BaseUserAwareListingBloc<Output, Filtering extends FilterType>
    extends BaseIndependentListingBloc<Output, Filtering>
    with UserDependantMixin<Output> {
  final BaseUserBloc userBloc;

  BaseUserAwareListingBloc(this.userBloc,
      {List<Stream<ProviderState>> sources = const [],
      Output? currentData,
      LifecycleObserver? lifecycleObserver})
      : super(
            currentData: currentData,
            sources: sources,
            lifecycleObserver: lifecycleObserver) {
    setUpUserListener();
  }
}
