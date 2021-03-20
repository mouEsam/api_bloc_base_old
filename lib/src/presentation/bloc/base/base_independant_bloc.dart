import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../api_bloc_base.dart';
import 'base_converter_bloc.dart';

export 'working_state.dart';

abstract class BaseIndependentBloc<Output>
    extends BaseConverterBloc<Output, Output> {
  BaseIndependentBloc({Output currentData}) : super(currentData: currentData);

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
        handleData(r);
        return r;
      },
    );
  }
}
