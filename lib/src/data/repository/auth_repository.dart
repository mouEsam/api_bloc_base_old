import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:api_bloc_base/src/data/model/remote/response/base_user_response.dart';
import 'package:dartz/dartz.dart';

abstract class BaseAuthRepository<T extends BaseProfile>
    extends BaseRepository {
  final UserDefaults userDefaults;
  final BaseResponseConverter<BaseUserResponse, T> converter;

  const BaseAuthRepository(this.converter, this.userDefaults);

  String get noAccountSavedInError;
  BaseResponseConverter<BaseUserResponse, T> get refreshConverter => converter;

  RequestResult<BaseUserResponse> internalLogin(BaseAuthParams params);
  RequestResult<BaseUserResponse> refresh(T account);

  Result<Either<ResponseEntity, T>> login(BaseAuthParams params) {
    final result = internalLogin(params);
    return handleFullResponse<BaseUserResponse, T>(
      result,
      interceptResult: (result) {
        if (result.active == true && params.rememberMe) {
          userDefaults.setSignedAccount(result);
          userDefaults.setUserToken(result.accessToken);
        }
        print(result.toJson());
      },
    );
  }

  Result<Either<ResponseEntity, T>> autoLogin([T? profile]) {
    final savedProfile = Future(() async {
      return await userDefaults.signedAccount;
    })
        .catchError((e, s) => null)
        .then<Either<ResponseEntity, T>>((savedAccount) {
      final save = savedAccount != null;
      final account = savedAccount ?? profile;
      if (account is T) {
        final operation = refresh(account);
        final result = handleFullResponse<BaseUserResponse, T>(operation,
            converter: refreshConverter);
        return result.resultFuture.then((value) {
          value.forEach((r) {
            if (r.active == true && save) {
              userDefaults.setSignedAccount(r);
              userDefaults.setUserToken(r.accessToken);
            }
          });
          return value.leftMap((l) => RefreshFailure(l.message, account));
        });
      }
      return Left(NoAccountSavedFailure(noAccountSavedInError));
    });
    return Result(resultFuture: savedProfile);
  }

  Result<ResponseEntity> saveProfileIfShouldBeRemembered(T profile) {
    final Future<ResponseEntity> savedProfile =
        userDefaults.signedAccount.then<ResponseEntity>((oldProfile) async {
      if (oldProfile is T) {
        if (profile.active == true) {
          userDefaults.setSignedAccount(profile);
          userDefaults.setUserToken(profile.accessToken);
        }
      }
      return Success();
    }).catchError((e, s) => NoAccountSavedFailure(noAccountSavedInError));
    return Result(resultFuture: savedProfile);
  }

  Result<ResponseEntity> offlineSignOut() {
    final one = userDefaults.setSignedAccount(null);
    final two = userDefaults.setUserToken(null);
    final result = Future.wait([one, two]).then<ResponseEntity>((value) {
      return Success();
    }).catchError((e, s) {
      print(e);
      print(s);
      return Failure(e.response);
    });
    return Result(resultFuture: result);
  }

  Result<ResponseEntity> logout(T account);
}
