import 'package:json_annotation/json_annotation.dart';

import 'entity.dart';

abstract class BaseProfile extends Entity {
  const BaseProfile({
    this.accessToken,
    this.active,
  });

  final String accessToken;
  final bool active;

  @JsonKey(ignore: true)
  dynamic get id;

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [
        this.accessToken,
      ];

  Map<String, dynamic> toJson();
}
