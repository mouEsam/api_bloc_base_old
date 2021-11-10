import 'package:json_annotation/json_annotation.dart';

part 'base_errors.g.dart';

@JsonSerializable()
class BaseErrors {
  const BaseErrors([this.errors = const {}]);

  final Map<String, List<String>> errors;

  factory BaseErrors.fromJson(Map<String, dynamic> json) =>
      _$BaseErrorsFromJson(json);
  Map<String, dynamic> toJson() => _$BaseErrorsToJson(this);
}
