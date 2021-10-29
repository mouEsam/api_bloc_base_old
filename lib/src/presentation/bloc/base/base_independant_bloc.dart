import 'dart:async';

import '../../../../api_bloc_base.dart';
import '../base_provider/provider_state.dart' as provider;
import 'base_converter_bloc.dart';
import 'independant_mixin.dart';

export 'working_state.dart';

abstract class BaseIndependentBloc<Output>
    extends BaseConverterBloc<Output, Output> with IndependentMixin<Output> {
  final List<Stream<provider.ProviderState>>? sources;
  final LifecycleObserver? lifecycleObserver;

  BaseIndependentBloc(
      {this.sources = const [], Output? currentData, this.lifecycleObserver})
      : super(currentData: currentData) {
    setIndependenceUp();
    // finalDataStream.listen(super.handleData);
  }
}
