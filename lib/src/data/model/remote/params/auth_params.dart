import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:json_annotation/json_annotation.dart';

abstract class BaseAuthParams extends Params {
  @JsonKey(ignore: true)
  final bool rememberMe;

  const BaseAuthParams(this.rememberMe);

  Map<String, dynamic> toMap();
}
