// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_errors.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BaseErrors _$BaseErrorsFromJson(Map<String, dynamic> json) {
  return BaseErrors(
    (json['errors'] as Map<String, dynamic>).map(
      (k, e) =>
          MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
    ),
  );
}

Map<String, dynamic> _$BaseErrorsToJson(BaseErrors instance) =>
    <String, dynamic>{
      'errors': instance.errors,
    };
