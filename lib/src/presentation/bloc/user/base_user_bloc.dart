import 'dart:async';

import 'package:api_bloc_base/src/data/repository/auth_repository.dart';
import 'package:api_bloc_base/src/data/repository/base_repository.dart';
import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:api_bloc_base/src/domain/entity/credentials.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';
import 'package:api_bloc_base/src/presentation/bloc/base_provider/provider_state.dart'
    as provider;
import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';

import 'base_user_state.dart';

abstract class BaseUserBloc<T extends BaseProfile>
    extends BaseCubit<BaseUserState> {
  final BaseAuthRepository<T> authRepository;

  Timer? _timer;

  final BehaviorSubject<T?> _userAccount = BehaviorSubject<T?>();

  StreamSubscription<T>? _detailsSubscription;
  Stream<T?> get userStream => _userAccount.shareValue();
  StreamSink<T?> get userSink => _userAccount.sink;

  Stream<provider.ProviderState<T>> get profileStream =>
      userStream.map<provider.ProviderState<T>>((event) {
        if (event != null) {
          return provider.ProviderLoadedState(event);
        } else {
          return provider.ProviderLoadingState();
        }
      });

  T? get currentUser => _userAccount.value;

  BaseUserBloc(this.authRepository) : super(UserLoadingState()) {
    autoSignIn();
    stream.listen((state) {
      _timer?.cancel();
      T? user;
      if (state is SignedOutState) {
        _detailsSubscription?.cancel();
      } else if (state is BaseSignedInState<T>) {
        user = state.userAccount;
        final refreshDuration = shouldProfileRefresh(user);
        if (refreshDuration != null) {
          setRefreshTimer(refreshDuration);
        }
      }
      _userAccount.add(user);
    });
  }

  void setRefreshTimer(Duration refreshDuration) {
    _timer = Timer.periodic(refreshDuration, (_) => autoSignIn(true));
  }

  Duration? shouldProfileRefresh(T state) => Duration(seconds: 30);

  Future<Either<ResponseEntity, T>> autoSignIn([bool silent = true]) async {
    if (!silent) {
      emit(UserLoadingState());
    }
    final result = await authRepository.autoLogin().resultFuture;
    result.fold((l) {
      if (l is RefreshFailure<T>) {
        handleFailedRefresh(l.oldProfile, silent);
      } else {
        handleUser(null);
      }
    }, (user) => handleUser(user));
    return result;
  }

  void handleFailedRefresh(T oldAccount, bool silent) {
    final isValid = oldAccount.expiration?.isAfter(DateTime.now());
    if (isValid != false) {
      handleUser(oldAccount);
    } else {
      if (silent) {
        setRefreshTimer(Duration(seconds: 5));
      } else {
        emit(TokenRefreshFailedState(oldAccount));
      }
    }
  }

  Result<Either<ResponseEntity, T>> login(Credentials params);

  Result<ResponseEntity> changePassword(String oldPassword, String password);

  Result<ResponseEntity> signOut() {
    final op = authRepository.logout(currentUser!);
    op.resultFuture.then((result) {
      if (result is Success ||
          (result is Failure && result is! InternetFailure)) {
        handleUser(null);
        return Success();
      } else {
        return result;
      }
    });
    return op;
  }

  Result<ResponseEntity> offlineSignOut() {
    final op = authRepository.offlineSignOut();
    op.resultFuture.then((result) {
      if (result is Success ||
          (result is Failure && result is! InternetFailure)) {
        handleUser(null);
        return Success();
      } else {
        return result;
      }
    });
    return op;
  }

  Future<void> handleUser(T? user) async {
    print(user);
    if (user == null) {
      emit(SignedOutState());
    } else {
      emitSignedUser(user);
    }
  }

  void emitSignedUser(T user);

  @override
  Future<void> close() {
    _timer?.cancel();
    _detailsSubscription?.cancel();
    _userAccount.drain().then((value) => _userAccount.close());
    return super.close();
  }
}
