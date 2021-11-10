import 'package:api_bloc_base/src/presentation/bloc/base/base_bloc.dart';

mixin ErrorMixin<State> on BaseCubit<State> {
  String get defaultErrorMessage;

  String extractErrorMessage(e) {
    try {
      return e.message;
    } catch (_) {
      return defaultErrorMessage;
    }
  }
}
