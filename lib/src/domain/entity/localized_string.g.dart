// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'localized_string.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalizedString _$LocalizedStringFromJson(Map<String, dynamic> json) {
  return LocalizedString(
    json['default_lang'] as String,
    Map<String, String>.from(json['data'] as Map),
  );
}

Map<String, dynamic> _$LocalizedStringToJson(LocalizedString instance) =>
    <String, dynamic>{
      'default_lang': instance.defaultLang,
      'data': instance.data,
    };
