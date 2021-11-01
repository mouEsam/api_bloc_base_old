import '../base_provider/base_provider_bloc.dart';
import 'base_converter_bloc.dart';
import 'paginated_mixin.dart';

abstract class BasePaginatedConverterBloc<Input, Output>
    extends BaseConverterBloc<PaginatedInput<Input>, Output>
    with PaginatedMixin<Input, Output> {
  BasePaginatedConverterBloc(
      {BaseProviderBloc<PaginatedInput<Input>>? sourceBloc,
      Output? currentData})
      : super(currentData: currentData, sourceBloc: sourceBloc);
}
