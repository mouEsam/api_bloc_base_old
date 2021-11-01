import 'package:api_bloc_base/api_bloc_base.dart';

mixin SameInputOutputMixin<Data> on BaseConverterBloc<Data, Data> {
  Data converter(Data input) => input;
}
