import 'package:equatable/equatable.dart';

abstract class Credentials extends Equatable {
  const Credentials();

  @override
  bool? get stringify => true;
}
