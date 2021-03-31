import 'dart:async';

import 'package:api_bloc_base/src/data/model/remote/auth_params.dart';
import 'package:api_bloc_base/src/data/repository/base_repository.dart';
import 'package:api_bloc_base/src/data/source/local/user_defaults.dart';
import 'package:api_bloc_base/src/domain/entity/base_profile.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:api_bloc_base/src/presentation/bloc/base_provider/provider_state.dart'
    as provider;
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'base_user_state.dart';

abstract class BaseUserBloc<T extends BaseProfile>
    extends Cubit<BaseUserState> {
  Timer _timer;
  bool firstLoginEmit = true;

  final UserDefaults userDefaults;

  final _userAccount = BehaviorSubject<T>();

  StreamSubscription<T> _detailsSubscription;
  Stream<T> get userStream => _userAccount.shareValue();
  StreamSink<T> get userSink => _userAccount.sink;

  Stream<provider.ProviderState<T>> get profileStream =>
      userStream.map<provider.ProviderState<T>>((event) {
        if (event != null) {
          return provider.ProviderLoadedState(event);
        } else {
          return provider.ProviderLoadingState();
        }
      });

  T get currentUser => _userAccount.value;

  BaseUserBloc(this.userDefaults) : super(UserLoadingState()) {
    autoSignIn();
    listen((state) {
      _timer?.cancel();
      T user;
      if (state is SignedOutState) {
        _detailsSubscription?.cancel();
      } else if (state is BaseSignedInState) {
        user = state.userAccount;
        if (shouldProfileRefresh(state)) {
          _timer = Timer.periodic(Duration(seconds: 30), (_) => autoSignIn());
        }
      }
      _userAccount.add(user);
    });
  }

  bool shouldProfileRefresh(BaseSignedInState state) => true;

  Future<Either<ResponseEntity, T>> autoSignIn([bool silent = true]);

  Result<Either<ResponseEntity, T>> login(BaseAuthParams params);

  Result<ResponseEntity> changePassword(String oldPassword, String password);

  Future<ResponseEntity> get signOutApi;

  Future<ResponseEntity> signOut() async {
    final result = await signOutApi;
    final actualLogOut = () {
      userDefaults.setSignedAccount(null);
      userDefaults.setUserToken(null);
      handleUser(null);
    };
    if (result is Success ||
        (result is Failure && result is! InternetFailure)) {
      actualLogOut();
      return null;
    } else {
      return result;
    }
  }

  Result<ResponseEntity> offlineSignOut() {
    final one = userDefaults.setSignedAccount(null);
    final two = userDefaults.setUserToken(null);
    final result = Future.wait([one, two]).then((value) {
      handleUser(null);
      return Success();
    }).catchError((e, s) {
      print(e);
      print(s);
      return Failure(e.message);
    });
    return Result(resultFuture: result);
  }

  Future<void> handleUser(T user) async {
    print(user);
    if (user == null) {
      userDefaults.setSignedAccount(null);
      userDefaults.setUserToken(null);
      emit(SignedOutState());
    } else {
      if (user.active) {
        userDefaults.setSignedAccount(user);
        userDefaults.setUserToken(user.accessToken);
      }
      firstLoginEmit = isFirstLogin(user);
      emitSignedUser(user);
    }
  }

  bool isFirstLogin(BaseProfile user) {
    return firstLoginEmit;
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
