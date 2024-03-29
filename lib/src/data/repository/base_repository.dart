import 'dart:async';

import 'package:api_bloc_base/src/data/model/remote/response/base_api_response.dart';
import 'package:api_bloc_base/src/data/service/converter.dart';
import 'package:api_bloc_base/src/data/source/remote/base_rest_client.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:dartz/dartz.dart' as z;
import 'package:dio/dio.dart';

class Result<T> {
  final CancelToken? cancelToken;
  final Future<T> resultFuture;
  final Stream<double>? progress;

  const Result({this.cancelToken, required this.resultFuture, this.progress});
}

abstract class BaseRepository {
  const BaseRepository();

  BaseResponseConverter get converter;

  String get defaultError => 'Error';
  String get internetError => 'Internet Error';

  Result<z.Either<ResponseEntity, S>>
      handleFullResponse<T extends BaseApiResponse, S>(
    RequestResult<T> result, {
    BaseResponseConverter<T, S>? converter,
    void Function(T)? interceptData,
    void Function(S)? interceptResult,
    FutureOr<S> Function(S data)? dataConverter,
    FutureOr<S> Function()? failureRecovery,
  }) {
    final _converter = converter ??
        (this.converter as BaseResponseConverter<BaseApiResponse, S>);
    final cancelToken = result.cancelToken;
    final future =
        result.resultFuture!.then<z.Either<ResponseEntity, S>>((value) async {
      final data = value.data;
      S? result;
      if (data != null) {
        if (_converter.hasData(data)) {
          interceptData?.call(data);
          result = _converter.convert(data);
        } else if (failureRecovery != null) {
          result = await failureRecovery();
        }
      }
      if (result != null) {
        if (dataConverter != null) {
          try {
            result = await (dataConverter(result));
          } catch (e, s) {
            print(e);
            print(s);
            return z.Left<ResponseEntity, S>(Failure(
              defaultError,
            ));
          }
        }
        interceptResult?.call(result!);
        return z.Right<ResponseEntity, S>(result!);
      } else {
        print(data.runtimeType);
        print(data);
        return z.Left<ResponseEntity, S>(_converter.response(data!)!);
      }
    }).catchError((e, s) async {
      print("Exception caught");
      print(e);
      print(s);
      if (e is DioError && e.type == DioErrorType.cancel) {
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
      if (e is DioError) {
        switch (e.type) {
          case DioErrorType.connectTimeout:
          case DioErrorType.sendTimeout:
          case DioErrorType.receiveTimeout:
            return z.Left<ResponseEntity, S>(
              InternetFailure(e.message, e),
            );
          case DioErrorType.response:
            return z.Left<ResponseEntity, S>(
              Failure(e.message, e.response?.statusCode),
            );
          case DioErrorType.other:
            break;
        }
      }
      return z.Left<ResponseEntity, S>(
        Failure(defaultError),
      );
    });
    return Result<z.Either<ResponseEntity, S>>(
        cancelToken: cancelToken,
        resultFuture: future,
        progress: result.progress);
  }

  Result<ResponseEntity> handleApiResponse<T extends BaseApiResponse>(
    RequestResult<T> result, {
    BaseResponseConverter? converter,
    void Function(T)? interceptData,
  }) {
    final _converter = converter ?? this.converter;
    final cancelToken = result.cancelToken;
    final future = result.resultFuture!.then<ResponseEntity>((value) async {
      final data = value.data!;
      interceptData?.call(data);
      return _converter.response(data)!;
    }).catchError((e, s) async {
      print("Exception caught");
      print(e);
      print(s);
      if (e is DioError) {
        switch (e.type) {
          case DioErrorType.cancel:
            return Cancellation();
          case DioErrorType.connectTimeout:
          case DioErrorType.sendTimeout:
          case DioErrorType.receiveTimeout:
            return InternetFailure(e.message, e);
          case DioErrorType.response:
            return Failure(e.message, e.response?.statusCode);
          case DioErrorType.other:
            break;
        }
      }
      return Failure(defaultError);
    });
    return Result<ResponseEntity>(
        cancelToken: cancelToken,
        resultFuture: future,
        progress: result.progress);
  }

  Result<z.Either<ResponseEntity, S>> handleOperation<S>(
    RequestResult<S> result, {
    void Function(S?)? interceptResult,
  }) {
    final cancelToken = result.cancelToken;
    final future =
        result.resultFuture!.then<z.Either<ResponseEntity, S>>((value) async {
      final data = value.data;
      interceptResult?.call(data);
      return z.Right<ResponseEntity, S>(data!);
    }).catchError((e, s) async {
      print("Exception caught");
      print(e);
      print(s);
      if (e is DioError) {
        switch (e.type) {
          case DioErrorType.cancel:
            return z.Left<ResponseEntity, S>(
              Cancellation(),
            );
          case DioErrorType.connectTimeout:
          case DioErrorType.sendTimeout:
          case DioErrorType.receiveTimeout:
            return z.Left<ResponseEntity, S>(
              InternetFailure(e.message, e),
            );
          case DioErrorType.response:
            return z.Left<ResponseEntity, S>(
              Failure(e.message, e.response?.statusCode),
            );
          case DioErrorType.other:
            break;
        }
      }
      return z.Left<ResponseEntity, S>(
        Failure(e.message, e.response?.statusCode),
      );
    });
    return Result<z.Either<ResponseEntity, S>>(
        cancelToken: cancelToken,
        resultFuture: future,
        progress: result.progress);
  }

  FutureOr<z.Either<Failure, T>> tryWork<T>(FutureOr<T> work(),
      [String? customErrorIfNoMessage,
      Failure createFailure(String message)?]) {
    try {
      final workSync = work();
      if (workSync is Future<T>) {
        Future<T> workAsync = workSync;
        return workAsync
            .then<z.Either<Failure, T>>((value) => z.Right<Failure, T>(value))
            .catchError((e, s) {
          print("Exception caught");
          print(e);
          print(s);
          return handleError<T>(e,
              createFailure: createFailure,
              customErrorIfNoMessage: customErrorIfNoMessage);
        });
      } else {
        T result = workSync;
        return z.Right(result);
      }
    } catch (e, s) {
      print("Exception caught");
      print(e);
      print(s);
      return handleError<T>(e,
          createFailure: createFailure,
          customErrorIfNoMessage: customErrorIfNoMessage);
    }
  }

  z.Left<Failure, T> handleError<T>(error,
      {String? customErrorIfNoMessage,
      Failure createFailure(String message)?}) {
    String? message = getErrorMessage(error, customErrorIfNoMessage);
    createFailure ??= (message) => Failure(message);
    return z.Left(createFailure(message!));
  }

  FutureOr<ResponseEntity> tryWorkWithResponse(FutureOr work(),
      [String? customErrorIfNoMessage]) async {
    try {
      await work();
      return Success();
    } catch (e, s) {
      print(e);
      print(s);
      return Failure(getErrorMessage(e, customErrorIfNoMessage));
    }
  }

  String? getErrorMessage(error, [String? customErrorIfNoMessage]) {
    String? message;
    try {
      message = error.message;
    } catch (e, s) {
      message ??= customErrorIfNoMessage ?? defaultError;
    }
    return message;
  }
}
