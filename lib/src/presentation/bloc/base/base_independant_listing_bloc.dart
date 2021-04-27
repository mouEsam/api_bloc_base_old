import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/independant_mixin.dart';

import '../../../../api_bloc_base.dart';
import '../base_provider/provider_state.dart' as provider;

export 'working_state.dart';

abstract class BaseIndependentListingBloc<Output, Filtering extends FilterType>
    extends BaseListingBloc<Output, Filtering> with IndependentMixin<Output> {
  final List<Stream<provider.ProviderState>> sources;

  BaseIndependentListingBloc(
      {int searchDelayMillis = 1000,
      this.sources = const [],
      Output currentData})
      : super(currentData: currentData, searchDelayMillis: searchDelayMillis);
}
