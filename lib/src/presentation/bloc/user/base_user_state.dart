import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:equatable/equatable.dart';

abstract class BaseUserState extends Equatable {
  BaseUserState();

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [];
}

class LoadingState extends BaseUserState {
  LoadingState();

  @override
  List<Object> get props => [];
}

abstract class BaseSignedInState extends BaseUserState {
  final BaseProfile userAccount;

  BaseSignedInState(this.userAccount);

  @override
  List<Object> get props => [
        this.userAccount,
      ];
}

class SignedOutState extends BaseUserState {
  SignedOutState();
}
