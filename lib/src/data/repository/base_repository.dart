import 'dart:async';

import 'package:api_bloc_base/src/data/model/remote/base_api_response.dart';
import 'package:api_bloc_base/src/data/service/converter.dart';
import 'package:api_bloc_base/src/data/source/remote/base_rest_client.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:dartz/dartz.dart' as z;
import 'package:dio/dio.dart';

class Result<T> {
  final CancelToken cancelToken;
  final Future<T> resultFuture;
  final Stream<double> progress;

  const Result({this.cancelToken, this.resultFuture, this.progress});
}

abstract class BaseRepository {
  const BaseRepository();

  BaseResponseConverter get converter;

  String get defaultError => 'Error';
  String get internetError => 'Internet Error';

  Result<z.Either<ResponseEntity, S>>
      handleFullResponse<T extends BaseApiResponse, S>(
    RequestResult<T> result, {
    BaseResponseConverter converter,
    void Function(T) interceptData,
    void Function(S) interceptResult,
    FutureOr<S> Function(S data) dataConverter,
    FutureOr<S> Function() failureRecovery,
  }) {
    converter ??= this.converter;
    final cancelToken = result.cancelToken;
    final future =
        result.resultFuture.then<z.Either<ResponseEntity, S>>((value) async {
      final data = value.data;
      S result;
      if (converter.hasData(data)) {
        interceptData?.call(data);
        result = converter.convert(data);
      } else if (failureRecovery != null) {
        result = await failureRecovery();
      }
      if (result != null) {
        if (dataConverter != null) {
          final temp = result;
          try {
            result = await dataConverter(result);
          } catch (e, s) {
            print(e);
            print(s);
            return z.Left<ResponseEntity, S>(Failure(
              defaultError,
            ));
          }
        }
        interceptResult?.call(result);
        return z.Right<ResponseEntity, S>(result);
      } else {
        print(data.runtimeType);
        print(data);
        return z.Left<ResponseEntity, S>(converter.response(data));
      }
    }).catchError((e, s) async {
      print(e);
      print(s);
      if (e is DioError && e.type == DioErrorType.CANCEL) {
        return z.Left<ResponseEntity, S>(
          Cancellation(),
        );
      }
      if (failureRecovery != null) {
        final result = await failureRecovery();
        if (result != null) {
          return z.Right<ResponseEntity, S>(result);
        }
      }
      return z.Left<ResponseEntity, S>(
        InternetFailure(internetError),
      );
    });
    return Result<z.Either<ResponseEntity, S>>(
        cancelToken: cancelToken,
        resultFuture: future,
        progress: result.progress);
  }

  Result<ResponseEntity> handleApiResponse<T extends BaseApiResponse>(
    RequestResult<T> result, {
    BaseResponseConverter converter,
    void Function(T) interceptData,
  }) {
    converter ??= this.converter;
    final cancelToken = result.cancelToken;
    final future = result.resultFuture.then<ResponseEntity>((value) async {
      final data = value.data;
      return converter.response(data);
    }).catchError((e, s) async {
      print(e);
      print(s);
      if (e is DioError && e.type == DioErrorType.CANCEL) {
        return Cancellation();
      }
      return InternetFailure(internetError);
    });
    return Result<ResponseEntity>(
        cancelToken: cancelToken,
        resultFuture: future,
        progress: result.progress);
  }
}
