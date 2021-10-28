import 'package:json_annotation/json_annotation.dart';

import 'entity.dart';

abstract class BaseProfile extends Entity {
  const BaseProfile({
    required this.accessToken,
    this.refreshToken,
    this.expiration,
    required this.active,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiration;
  final bool active;

  @JsonKey(ignore: true)
  dynamic get id;

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [
        this.accessToken,
        this.refreshToken,
        this.expiration,
      ];

  Map<String, dynamic> toJson();
}
