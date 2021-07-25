import '../base_provider/base_provider_bloc.dart';
import 'base_independant_bloc.dart';
import 'paginated_mixin.dart';

abstract class BasePaginatedBloc<Data> extends BaseIndependentBloc<Data>
    with PaginatedMixin<Data, Data> {
  BasePaginatedBloc({List<Stream<ProviderState>>? sources, Data? currentData})
      : super(currentData: currentData, sources: sources);
}
