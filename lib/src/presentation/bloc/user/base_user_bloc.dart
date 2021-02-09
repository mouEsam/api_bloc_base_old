import 'dart:async';

import 'package:api_bloc_base/src/data/model/remote/params.dart';
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

abstract class BaseUserBloc extends Cubit<BaseUserState> {
  Timer _timer;

  final UserDefaults userDefaults;

  final _userAccount = BehaviorSubject<BaseProfile>();

  StreamSubscription<BaseProfile> _detailsSubscription;
  Stream<BaseProfile> get userStream => _userAccount.shareValue();

  Stream<provider.ProviderState<BaseProfile>> get profileStream =>
      userStream.map<provider.ProviderState<BaseProfile>>((event) {
        if (event != null) {
          return provider.ProviderLoadedState(event);
        } else {
          return provider.ProviderLoadingState();
        }
      });

  BaseProfile get currentUser => _userAccount.value;
  bool firstLoginEmit = true;

  BaseUserBloc(this.userDefaults) : super(UserLoadingState()) {
    autoSignIn();
    listen((state) {
      _timer?.cancel();
      BaseProfile user;
      if (state is SignedOutState) {
        firstLoginEmit = true;
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

  Future<Either<ResponseEntity, BaseProfile>> autoSignIn([bool silent = true]);

  Result<Either<ResponseEntity, BaseProfile>> login<T extends Params>(T params);

  Result<ResponseEntity> changePassword(String oldPassword, String password);

  Future<ResponseEntity> get signOutApi;

  Future<ResponseEntity> signOut() async {
    final result = await signOutApi;
    final actualLogOut = () {
      userDefaults.setSignedAccount(null);
      userDefaults.setUserToken(null);
      _handleUser(null);
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
      _handleUser(null);
      return Success();
    }).catchError((e, s) {
      print(e);
      print(s);
      return Failure(e.message);
    });
    return Result(resultFuture: result);
  }

  Future<void> _handleUser(BaseProfile user) async {
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

  bool isFirstLogin(BaseProfile user);

  void emitSignedUser(BaseProfile user);

  @override
  Future<void> close() {
    _timer?.cancel();
    _detailsSubscription?.cancel();
    _userAccount.drain().then((value) => _userAccount.close());
    return super.close();
  }
}
