import 'package:api_bloc_base/api_bloc_base.dart';

import 'base_listing_bloc.dart';

abstract class BaseUserAwareListingBloc<Output, Filtering extends FilterType>
    extends BaseListingBloc<Output, Filtering> with UserDependantMixin<Output> {
  final BaseUserBloc userBloc;

  BaseUserAwareListingBloc(this.userBloc,
      {List<Stream<ProviderState>> sources = const [], Output currentData})
      : super(currentData: currentData, sources: sources) {
    setUpUserListener();
  }
}
