import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:api_bloc_base/src/data/model/remote/params.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_flutter_transformer/dio_flutter_transformer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

enum RequestBodyType {
  FormData,
  Json,
}

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

  CacheOptions _cacheOptions;

  static CacheOptions createCacheOptions(
      {CacheOptions cacheOptions, CachePolicy cachePolicy}) {
    return CacheOptions(
      store: cacheOptions?.store ?? DbCacheStore(), // Required.
      policy: cachePolicy ??
          cacheOptions?.policy ??
          CachePolicy
              .requestFirst, // Default. Requests first and caches response.
      hitCacheOnErrorExcept: cacheOptions?.hitCacheOnErrorExcept ??
          [
            401,
            403
          ], // Optional. Returns a cached response on error if available but for statuses 401 & 403.
      priority: cacheOptions?.priority ??
          CachePriority
              .normal, // Optional. Default. Allows 3 cache levels and ease cleanup.
      maxStale: cacheOptions?.maxStale ??
          const Duration(
              days:
                  7), // Very optional. Overrides any HTTP directive to delete entry past this duration.
    );
  }

  BaseRestClient(this.baseUrl,
      {Iterable<Interceptor> interceptors = const [],
      CacheOptions cacheOptions,
      CachePolicy cachePolicy,
      BaseOptions options})
      : dio = Dio() {
    dio.interceptors.addAll(interceptors);
    _cacheOptions = createCacheOptions(
        cacheOptions: cacheOptions, cachePolicy: cachePolicy);
    dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions));
    if (options == null) {
      dio.options.connectTimeout = 15000;
      dio.options.headers[HttpHeaders.acceptHeader] = 'application/json';
      dio.options.receiveDataWhenStatusError = true;
      dio.options.validateStatus = (_) => true;
      // dio.transformer = CustomTransformer();
      dio.transformer = FlutterTransformer();
    } else {
      dio.options = options;
    }
  }

  RequestResult<T> request<T>(
    RequestMethod method,
    String path, {
    T mockedResult,
    CancelToken cancelToken,
    String authorizationToken,
    Params params,
    String subDomain,
    dynamic acceptedLanguage,
    CacheOptions options,
    ResponseType responseType = ResponseType.json,
    CachePolicy cachePolicy,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    Map<String, dynamic> queryParameters,
    RequestBodyType requestBodyType = RequestBodyType.FormData,
    T Function(Map<String, dynamic>) fromJson,
  }) {
    if (T == BaseApiResponse) {
      throw FlutterError(
          'T must be either be a generic encodable Type or a sub class of BaseApiResponse');
    }
    final progressController = StreamController<double>();
    if (params != null) {
      print(Map.fromEntries(
          params.toMap().entries.where((element) => element.value != null)));
    }
    cancelToken ??= CancelToken();
    extra ??= <String, dynamic>{};
    if (cachePolicy != null) {
      options = createCacheOptions(
          cacheOptions: options ?? _cacheOptions, cachePolicy: cachePolicy);
    }
    extra.addAll(options?.toExtra() ?? <String, dynamic>{});
    queryParameters ??= <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    headers ??= <String, dynamic>{};
    if (acceptedLanguage is Locale) {
      headers[HttpHeaders.acceptLanguageHeader] = acceptedLanguage.languageCode;
    } else if (acceptedLanguage != null) {
      headers[HttpHeaders.acceptLanguageHeader] = acceptedLanguage.toString();
    }
    if (authorizationToken != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $authorizationToken';
    }
    dynamic body;
    final formData = params?.toMap();
    // formData?.removeWhere((key, value) => value == null);
    if (formData != null && formData.isNotEmpty) {
      switch (requestBodyType) {
        case RequestBodyType.FormData:
          final _data = FormData();
          for (final entry in formData.entries) {
            if (entry.value != null) {
              if (entry.value is File) {
                final file = entry.value as File;
                _data.files.add(MapEntry(
                    entry.key,
                    MultipartFile.fromFileSync(file.path,
                        filename:
                            file.path.split(Platform.pathSeparator).last)));
              } else if (entry.value is List) {
                final list = entry.value as List;
                list.where((e) => e != null).forEach((value) =>
                    _data.fields.add(MapEntry(entry.key, value.toString())));
              } else {
                _data.fields.add(MapEntry(entry.key, entry.value.toString()));
              }
            }
          }
          body = _data;
          break;
        case RequestBodyType.Json:
          body = jsonEncode(formData);
      }
    }
    final _progressListener = (int count, int total) {
      final newCount = math.max(count, 0);
      final newTotal = math.max(total, 0);
      final double progress = newTotal == 0 ? 0.0 : (newCount / newTotal);
      if (!progressController.isClosed) {
        progressController.add(math.max(progress, 1.0));
      }
      if (progress == 1.0) {
        progressController.close();
      }
      return progress;
    };
    String newBaseUrl = baseUrl;
    if (subDomain != null) {
      var baseUri = Uri.tryParse(newBaseUrl);
      var splitHost = baseUri.host.split('.');
      if (splitHost.length >= 3) {
        splitHost[0] = subDomain;
      } else {
        splitHost.insert(0, subDomain);
      }
      final newHost = splitHost.join('.');
      baseUri = baseUri.replace(host: newHost);
      newBaseUrl = baseUri.toString();
    }
    Future<Response> result;
    if (mockedResult == null) {
      result = dio.request(path,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
          onReceiveProgress: _progressListener,
          onSendProgress: _progressListener,
          options: RequestOptions(
              method: method.method,
              headers: headers,
              extra: extra,
              responseType: responseType,
              baseUrl: newBaseUrl),
          data: body);
    } else {
      result = Future.value(Response(
        headers: Headers(),
        //isRedirect: false,
        extra: extra,
        request: RequestOptions(
            method: method.method,
            headers: headers,
            extra: extra,
            baseUrl: newBaseUrl),
        statusCode: 200,
        statusMessage: 'success',
      ));
      _progressListener(100, 100);
    }
    final response = result.then((result) {
      print(result.data);
      T value;
      if (mockedResult == null) {
        if (fromJson != null) {
          value = fromJson(result.data);
        } else {
          value = result.data;
        }
      } else {
        value = mockedResult;
      }
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
    response.whenComplete(() => progressController.close());
    return RequestResult(
      cancelToken: cancelToken,
      resultFuture: response,
      progress: progressController.stream
          .asBroadcastStream(onCancel: (sub) => sub.cancel()),
    );
  }

  RequestResult<T> download<T>(
    RequestMethod method,
    String path, {
    CancelToken cancelToken,
    String authorizationToken,
    Params params,
    String subDomain,
    dynamic acceptedLanguage,
    CacheOptions options,
    CachePolicy cachePolicy,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    Map<String, dynamic> queryParameters,
    RequestBodyType requestBodyType = RequestBodyType.FormData,
    T Function(Map<String, dynamic>) fromJson,
  }) {
    if (T == BaseApiResponse) {
      throw FlutterError(
          'T must be either be a generic encodable Type or a sub class of BaseApiResponse');
    }
    final progressController = StreamController<double>();
    if (params != null) {
      print(Map.fromEntries(
          params.toMap().entries.where((element) => element.value != null)));
    }
    cancelToken ??= CancelToken();
    extra ??= <String, dynamic>{};
    if (cachePolicy != null) {
      options = createCacheOptions(
          cacheOptions: options ?? _cacheOptions, cachePolicy: cachePolicy);
    }
    extra.addAll(options?.toExtra() ?? <String, dynamic>{});
    queryParameters ??= <String, dynamic>{};
    queryParameters.removeWhere((k, v) => v == null);
    headers ??= <String, dynamic>{};
    if (acceptedLanguage is Locale) {
      headers[HttpHeaders.acceptLanguageHeader] = acceptedLanguage.languageCode;
    } else if (acceptedLanguage != null) {
      headers[HttpHeaders.acceptLanguageHeader] = acceptedLanguage.toString();
    }
    if (authorizationToken != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $authorizationToken';
    }
    dynamic body;
    final formData = params?.toMap();
    // formData?.removeWhere((key, value) => value == null);
    if (formData != null && formData.isNotEmpty) {
      switch (requestBodyType) {
        case RequestBodyType.FormData:
          final _data = FormData();
          for (final entry in formData.entries) {
            if (entry.value != null) {
              if (entry.value is File) {
                final file = entry.value as File;
                _data.files.add(MapEntry(
                    entry.key,
                    MultipartFile.fromFileSync(file.path,
                        filename:
                            file.path.split(Platform.pathSeparator).last)));
              } else if (entry.value is List) {
                final list = entry.value as List;
                list.where((e) => e != null).forEach((value) =>
                    _data.fields.add(MapEntry(entry.key, value.toString())));
              } else {
                _data.fields.add(MapEntry(entry.key, entry.value.toString()));
              }
            }
          }
          body = _data;
          break;
        case RequestBodyType.Json:
          body = jsonEncode(formData);
      }
    }
    final _progressListener = (int count, int total) {
      final newCount = math.max(count, 0);
      final newTotal = math.max(total, 0);
      final double progress = newTotal == 0 ? 0.0 : (newCount / newTotal);
      progressController.add(math.max(progress, 1.0));
      return progress;
    };
    Future<Response<ResponseBody>> result = dio.download(path, null,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onReceiveProgress: _progressListener,
        options: RequestOptions(
            method: method.method,
            headers: headers,
            extra: extra,
            baseUrl: baseUrl),
        data: body);
    final _stream =
        result.asStream().asBroadcastStream(onCancel: (sub) => sub.cancel());
    _stream.listen((event) {},
        onDone: () => progressController.close(),
        onError: (e, s) => progressController.close(),
        cancelOnError: true);
    return RequestResult(
      cancelToken: cancelToken,
      progress: progressController.stream
          .asBroadcastStream(onCancel: (sub) => sub.cancel()),
    );
  }
}

class RequestResult<T> {
  final CancelToken cancelToken;
  final Future<Response<T>> resultFuture;
  final Stream<double> progress;

  const RequestResult({this.cancelToken, this.resultFuture, this.progress});
}

class CustomTransformer extends DefaultTransformer {
  @override
  get jsonDecodeCallback => (String json) => compute(jsonDecode, json);
}
