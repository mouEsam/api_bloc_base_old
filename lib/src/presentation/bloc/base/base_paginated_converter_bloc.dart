import '../base_provider/base_provider_bloc.dart';
import 'base_converter_bloc.dart';
import 'paginated_mixin.dart';

abstract class BasePaginatedConverterBloc<
        Paginated extends PaginatedInput<Data>,
        Data> extends BaseConverterBloc<Paginated, Data>
    with PaginatedMixin<Paginated, Data> {
  BasePaginatedConverterBloc(
      {BaseProviderBloc<Paginated>? sourceBloc, Data? currentData})
      : super(currentData: currentData, sourceBloc: sourceBloc);
}
