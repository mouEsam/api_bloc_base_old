import 'package:api_bloc_base/src/data/model/remote/response/base_api_response.dart';

abstract class BaseUserResponse extends BaseApiResponse {
  const BaseUserResponse(
      String? success, String? message, String? error, BaseErrors? errors)
      : super(success, message, error, errors);
}
