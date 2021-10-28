// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BaseApiResponse _$BaseApiResponseFromJson(Map<String, dynamic> json) {
  return BaseApiResponse(
    json['success'] as String?,
    json['message'] as String?,
    json['error'] as String?,
    json['errors'] == null
        ? null
        : BaseErrors.fromJson(json['errors'] as Map<String, dynamic>?),
  );
}

Map<String, dynamic> _$BaseApiResponseToJson(BaseApiResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'error': instance.error,
      'errors': instance.errors?.toJson(),
    };
