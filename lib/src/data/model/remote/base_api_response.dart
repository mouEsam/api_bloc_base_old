import 'package:json_annotation/json_annotation.dart';

import 'base_errors.dart';

export 'base_errors.dart';

part 'base_api_response.g.dart';

@JsonSerializable()
class BaseApiResponse {
  const BaseApiResponse(
    this.success,
    this.message,
    this.error,
    this.errors,
  );

  final String success;
  final String message;
  final String error;
  final BaseErrors errors;

  factory BaseApiResponse.fromJson(Map<String, dynamic> json) =>
      _$BaseApiResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BaseApiResponseToJson(this);
}
