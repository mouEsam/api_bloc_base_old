import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/independant_mixin.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../api_bloc_base.dart';
import '../base_provider/provider_state.dart' as provider;

export 'working_state.dart';

abstract class BaseIndependentListingBloc<Output, Filtering extends FilterType>
    extends BaseListingBloc<Output, Filtering>
    with IndependentMixin<Output, Output> {
  final List<Stream<provider.ProviderState>> sources;
  final LifecycleObserver? lifecycleObserver;

  get inputStream =>
      CombineLatestStream.combine3<Output, Filtering?, String, Output>(
              super.inputStream, filterStream, queryStream, (a, b, c) => a)
          .asBroadcastStream(onCancel: (sub) => sub.cancel());

  BaseIndependentListingBloc(
      {int searchDelayMillis = 1000,
      this.sources = const [],
      Output? currentData,
      this.lifecycleObserver})
      : super(currentData: currentData, searchDelayMillis: searchDelayMillis) {
    setIndependenceUp();
  }

  Output convertInput(Output output) => applyFilter(output, filter, query);
}
