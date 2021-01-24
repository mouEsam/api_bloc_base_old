import 'package:json_annotation/json_annotation.dart';

part 'params.g.dart';

@JsonSerializable(createFactory: false)
class Params {
  Params();

  Map<String, dynamic> toMap() => _$ParamsToJson(this);
}
