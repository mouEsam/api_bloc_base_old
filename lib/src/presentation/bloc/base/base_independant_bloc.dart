import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../api_bloc_base.dart';
import '../base_provider/provider_state.dart' as provider;
import 'base_converter_bloc.dart';

export 'working_state.dart';

abstract class BaseIndependentBloc<Output>
    extends BaseConverterBloc<Output, Output> {
  final List<Stream<provider.ProviderState>> sources;

  BaseIndependentBloc({this.sources = const [], Output currentData})
      : super(currentData: currentData) {
    Stream<Output> finalStream;
    if (sources.isNotEmpty) {
      final stream = CombineLatestStream.list(sources).asBroadcastStream();
      finalStream = CombineLatestStream.combine2<dynamic, Output, Output>(
              stream, _ownDataSubject, combineData)
          .asBroadcastStream();
    } else {
      finalStream = _ownDataSubject
          .map((event) => combineData([], event))
          .asBroadcastStream();
    }
    finalStream.doOnEach((notification) => emitLoading()).listen(handleData);
  }

  Output combineData(List events, Output data) {
    return data;
  }

  final _ownDataSubject = BehaviorSubject<Output>();

  Output Function(Output input) get converter => (data) => data;
  Result<Either<ResponseEntity, Output>> get dataSource;

  void getData() {
    super.getData();
    final data = dataSource;
    handleDataRequest(data);
  }

  Future<Output> handleDataRequest(
      Result<Either<ResponseEntity, Output>> result) async {
    emitLoading();
    final future = await result.resultFuture;
    return future.fold<Output>(
      (l) {
        return null;
      },
      (r) {
        _ownDataSubject.add(r);
        return r;
      },
    );
  }

  @override
  Future<void> close() {
    _ownDataSubject.drain().then((value) => _ownDataSubject.close());
    return super.close();
  }
}
