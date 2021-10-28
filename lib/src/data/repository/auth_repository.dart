import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:dartz/dartz.dart';

abstract class BaseAuthRepository<T extends BaseProfile>
    extends BaseRepository {
  final UserDefaults userDefaults;

  const BaseAuthRepository(this.userDefaults);

  String get noAccountSavedInError;

  Result<Either<ResponseEntity, T>> login(BaseAuthParams params);

  RequestResult<BaseApiResponse> refresh(T account);

  Result<Either<ResponseEntity, T>> autoLogin() {
    final savedProfile = userDefaults.signedAccount
        .catchError((e, s) => null)
        .then<Either<ResponseEntity, T>>((account) {
      if (account is T) {
        final operation = refresh(account);
        final result = handleFullResponse<BaseApiResponse, T>(operation);
        return result.resultFuture.then((value) {
          value.forEach((r) {
            if (r.active == true) {
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

  Result<ResponseEntity> offlineSignOut() {
    final one = userDefaults.setSignedAccount(null);
    final two = userDefaults.setUserToken(null);
    final result = Future.wait([one, two]).then<ResponseEntity>((value) {
      return Success();
    }).catchError((e, s) {
      print(e);
      print(s);
      return Failure(e.message);
    });
    return Result(resultFuture: result);
  }

  Result<ResponseEntity> logout(T account);
}
