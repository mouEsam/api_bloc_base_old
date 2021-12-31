import 'package:api_bloc_base/src/data/model/remote/params/base_errors.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import 'base_profile.dart';

class ResponseEntity extends Equatable {
  final String? message;

  const ResponseEntity(this.message);

  @override
  List<Object?> get props => [this.message];
}

class Success extends ResponseEntity {
  const Success([String? message = '']) : super(message);

  @override
  List<Object?> get props => [...super.props];
}

class Failure extends ResponseEntity {
  final int? errorCode;
  final BaseErrors? errors;

  const Failure(String? message, [this.errorCode, this.errors]) : super(message);

  @override
  List<Object?> get props => [...super.props, this.errors];
}

class InternetFailure extends Failure {
  final DioError dioError;
  const InternetFailure(String message, this.dioError, [int? errorCode, BaseErrors? errors])
      : super(message, null, errors);

  @override
  List<Object?> get props => [...super.props, this.dioError];
}

class Cancellation extends ResponseEntity {
  const Cancellation() : super(null);

  @override
  List<Object?> get props => [...super.props];
}

class NoAccountSavedFailure extends Failure {
  const NoAccountSavedFailure(String message, [BaseErrors? errors])
      : super(message, null, errors);

  @override
  get props => [...super.props];
}

class RefreshFailure<T extends BaseProfile> extends Failure {
  final T oldProfile;

  const RefreshFailure(String? message, this.oldProfile, [BaseErrors? errors])
      : super(message, null, errors);

  @override
  get props => [...super.props, this.oldProfile];
}

class LoginFailure<T extends BaseProfile> extends Failure {
  final T oldProfile;

  const RefreshFailure(String? message, this.oldProfile, [BaseErrors? errors])
      : super(message, null, errors);

  @override
  get props => [...super.props, this.oldProfile];
}
