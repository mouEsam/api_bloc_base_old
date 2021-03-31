import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_params.g.dart';

@JsonSerializable(createFactory: false)
class BaseAuthParams extends Params {
  const BaseAuthParams();

  Map<String, dynamic> toMap() => _$BaseAuthParamsToJson(this);
}
