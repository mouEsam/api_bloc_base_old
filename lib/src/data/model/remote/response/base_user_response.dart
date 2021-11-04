import 'package:api_bloc_base/src/data/model/remote/response/base_api_response.dart';

abstract class BaseUserResponse<D> extends BaseApiResponse<D> {
  const BaseUserResponse(D? data, dynamic success, String? message,
      String? error, BaseErrors? errors)
      : super(data, success, message, error, errors);
}
