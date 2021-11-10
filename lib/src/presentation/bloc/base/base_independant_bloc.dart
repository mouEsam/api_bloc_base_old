import 'dart:async';

import '../../../../api_bloc_base.dart';
import '../base_provider/provider_state.dart' as provider;
import 'base_converter_bloc.dart';
import 'independant_mixin.dart';

export 'working_state.dart';

abstract class BaseIndependentBloc<Input, Output>
    extends BaseConverterBloc<Input, Output>
    with IndependentMixin<Input, Output> {
  final List<Stream<provider.ProviderState>> sources;
  final LifecycleObserver? lifecycleObserver;

  BaseIndependentBloc(
      {bool enableRetry = true,
      bool enableRefresh = true,
      bool getOnCreate = true,
      this.sources = const [],
      Output? currentData,
      this.lifecycleObserver})
      : super(getOnCreate: getOnCreate, currentData: currentData) {
    setIndependenceUp(getOnCreate, enableRetry, enableRefresh);
    // finalDataStream.listen(super.handleData);
  }
}
