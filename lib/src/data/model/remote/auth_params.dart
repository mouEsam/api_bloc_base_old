import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_params.g.dart';

@JsonSerializable(createFactory: false)
class AuthParams extends Params {
  const AuthParams();

  Map<String, dynamic> toMap() => _$AuthParamsToJson(this);
}
