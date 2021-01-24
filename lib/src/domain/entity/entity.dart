import 'package:equatable/equatable.dart';

abstract class Entity extends Equatable {
  const Entity();
  List<String> get serverSuccessMessages => null;
}
