import 'package:equatable/equatable.dart';

abstract class Entity extends Equatable {
  const Entity();

  get stringify => true;

  List<String>? get serverSuccessMessages => null;
}
