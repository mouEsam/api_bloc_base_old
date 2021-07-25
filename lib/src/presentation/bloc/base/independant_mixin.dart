import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../api_bloc_base.dart';
import '../base_provider/provider_state.dart' as provider;
import 'base_converter_bloc.dart';

export 'working_state.dart';

mixin IndependentMixin<Output> on BaseConverterBloc<Output, Output> {
  List<Stream<provider.ProviderState>>? get sources;

  Stream<provider.ProviderState<Output>> get source {
    Stream<provider.ProviderState<Output>> finalStream;
    final sources = this.sources!;
    if (sources.isNotEmpty) {
      final stream = CombineLatestStream.list(sources)
          .asBroadcastStream(onCancel: (sub) => sub.cancel());
      finalStream = CombineLatestStream.combine2<List, Output,
              provider.ProviderState<Output>>(stream, originalDataStream,
          (list, data) {
        provider.ProviderErrorState? error = list.firstWhere(
            (element) => element is provider.ProviderErrorState,
            orElse: () => null);
        if (error != null) {
          return provider.ProviderErrorState<Output>(error.message);
        }
        provider.ProviderLoadingState? loading = list.firstWhere(
            (element) => element is provider.ProviderLoadingState,
            orElse: () => null);
        if (loading != null) {
          return provider.ProviderLoadingState<Output>();
        }
        provider.InvalidatedState? invalidated = list.firstWhere(
            (element) => element is provider.InvalidatedState,
            orElse: () => null);
        if (invalidated != null) {
          return provider.InvalidatedState<Output>();
        }
        return provider.ProviderLoadedState<Output>(data);
      }).asBroadcastStream(onCancel: (sub) => sub.cancel());
    } else {
      finalStream = originalDataStream
          .map((data) => provider.ProviderLoadedState<Output>(data))
          .cast<provider.ProviderState<Output>>()
          .asBroadcastStream(onCancel: (sub) => sub.cancel());
    }
    return finalStream;
  }

  Output combineData(Output data) => data;

  @override
  void setData(Output newData) {
    final data = combineData(newData);
    _finalDataSubject.add(data);
    super.setData(data);
  }

  final _ownDataSubject = StreamController<Output>.broadcast();
  Stream<Output> get originalDataStream => _ownDataSubject.stream;

  final BehaviorSubject<Output> _finalDataSubject = BehaviorSubject<Output>();
  Stream<Output> get finalDataStream => _finalDataSubject.shareValue();

  Output Function(Output input) get converter => (data) => data;

  void clean() {
    super.clean();
    //_finalDataSubject.value = null;
  }

  Result<Either<ResponseEntity, Output>> get dataSource;

  Future<Output?> getData([bool refresh = false]) {
    super.getData(refresh);
    final data = dataSource;
    return handleDataRequest(data, refresh);
  }

  Future<Output?> handleDataRequest(
      Result<Either<ResponseEntity, Output>> result, bool refresh) async {
    if (!refresh) emitLoading();
    final future = await result.resultFuture!;
    return future.fold<Output?>(
      (l) {
        handleEvent(ProviderErrorState<Output>(l.message));
        return null;
      },
      (r) {
        if (!_ownDataSubject.isClosed) {
          _ownDataSubject.add(r);
        }
        return r;
      },
    );
  }

  @override
  Future<void> close() {
    _ownDataSubject.close();
    _finalDataSubject.drain().then((value) => _finalDataSubject.close());
    return super.close();
  }
}
