import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:equatable/equatable.dart';

abstract class BaseUserState extends Equatable {
  const BaseUserState();

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [];
}

class UserLoadingState extends BaseUserState {
  const UserLoadingState();

  @override
  List<Object> get props => [];
}

abstract class BaseSignedInState<T extends BaseProfile> extends BaseUserState {
  final T userAccount;

  const BaseSignedInState(this.userAccount);

  @override
  List<Object> get props => [
        this.userAccount,
      ];
}

class SignedOutState extends BaseUserState {
  const SignedOutState();
}
