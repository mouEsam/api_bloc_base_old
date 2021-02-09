import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:api_bloc_base/src/data/model/remote/params.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

enum RequestMethod {
  POST,
  GET,
  PUT,
  DELETE,
}

extension on RequestMethod {
  String get method {
    switch (this) {
      case RequestMethod.GET:
        return 'GET';
      case RequestMethod.POST:
        return 'POST';
      case RequestMethod.PUT:
        return 'PUT';
      case RequestMethod.DELETE:
        return 'DELETE';
    }
  }
}

class BaseRestClient {
  final String baseUrl;
  final Dio dio;

  BaseRestClient(this.baseUrl) : dio = Dio() {
    dio.options.connectTimeout = 15000;
    dio.options.headers[HttpHeaders.acceptHeader] = 'application/json';
    dio.options.receiveDataWhenStatusError = true;
    dio.options.validateStatus = (_) => true;
  }

  RequestResult<T> request<T>(
    RequestMethod method,
    String path, {
    CancelToken cancelToken,
    String authorizationToken,
    Params params,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    Map<String, dynamic> queryParameters,
    T Function(Map<String, dynamic>) fromJson,
  }) {
    if (T == BaseApiResponse) {
      throw FlutterError('T must be a sub class of BaseApiResponse');
    }
    final progressController = StreamController<double>();
    if (params != null) {
      print(Map.fromEntries(
          params.toMap().entries.where((element) => element.value != null)));
    }
    cancelToken ??= CancelToken();
    extra ??= <String, dynamic>{};
    queryParameters ??= <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    headers ??= <String, dynamic>{};
    if (authorizationToken != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $authorizationToken';
    }
    final _data = FormData();
    final formData = params?.toMap();
    // formData?.removeWhere((key, value) => value == null);
    if (formData != null && formData.isNotEmpty) {
      for (final entry in formData.entries) {
        if (entry.value != null) {
          if (entry.value is File) {
            final file = entry.value as File;
            // final fileToUpload = MultipartFile.fromBytes(file.readAsBytesSync(),
            //     filename: file.name);
            // _data.files.add(MapEntry(entry.key, fileToUpload));
            _data.files.add(MapEntry(
                entry.key,
                MultipartFile.fromFileSync(file.path,
                    filename: file.path.split(Platform.pathSeparator).last)));
          } else if (entry.value is List) {
            final list = entry.value as List;
            list.where((e) => e != null).forEach((value) =>
                _data.fields.add(MapEntry(entry.key, value.toString())));
          } else {
            _data.fields.add(MapEntry(entry.key, entry.value.toString()));
          }
        }
      }
    }
    final _progressListener = (int count, int total) {
      final newCount = math.max(count, 0);
      final newTotal = math.max(total, 0);
      final double progress = newTotal == 0 ? 0.0 : (newCount / newTotal);
      progressController.add(progress);
      return progress;
    };
    final result = dio.request<Map<String, dynamic>>(path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onReceiveProgress: _progressListener,
        onSendProgress: _progressListener,
        options: RequestOptions(
            method: method.method,
            headers: headers,
            extra: extra,
            baseUrl: baseUrl),
        data: _data);
    final response = result.then((result) {
      print(result.data);
      final T value = fromJson?.call(result.data) ?? result.data;
      return Response<T>(
          data: value,
          extra: result.extra,
          headers: result.headers,
          isRedirect: result.isRedirect,
          redirects: result.redirects,
          request: result.request,
          statusCode: result.statusCode,
          statusMessage: result.statusMessage);
    });
    final _stream = response.asStream().asBroadcastStream();
    _stream.listen((event) {},
        onDone: () => progressController.close(),
        onError: (e, s) => progressController.close(),
        cancelOnError: true);
    return RequestResult(
      cancelToken: cancelToken,
      resultFuture: response,
      progress: progressController.stream.asBroadcastStream(),
    );
  }
}

class RequestResult<T> {
  final CancelToken cancelToken;
  final Future<Response<T>> resultFuture;
  final Stream<double> progress;

  const RequestResult({this.cancelToken, this.resultFuture, this.progress});
}
