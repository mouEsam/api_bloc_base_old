import '../params/base_errors.dart';

export '../params/base_errors.dart';

abstract class BaseApiResponse<D> {
  const BaseApiResponse(
    this.data,
    this.success,
    this.message,
    this.error,
    this.errors,
  );

  final dynamic success;
  final D? data;
  final String? message;
  final String? error;
  final BaseErrors? errors;
}
