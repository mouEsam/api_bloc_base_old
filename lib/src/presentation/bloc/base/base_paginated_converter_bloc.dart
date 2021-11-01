import '../base_provider/base_provider_bloc.dart';
import 'base_converter_bloc.dart';
import 'paginated_mixin.dart';

abstract class BasePaginatedConverterBloc<Output>
    extends BaseConverterBloc<PaginatedInput<Output>, Output>
    with PaginatedMixin<Output> {
  BasePaginatedConverterBloc(
      {BaseProviderBloc<PaginatedInput<Output>>? sourceBloc,
      Output? currentData})
      : super(currentData: currentData, sourceBloc: sourceBloc);
}
