import 'package:api_bloc_base/api_bloc_base.dart';

import '../base_provider/base_provider_bloc.dart';
import 'base_independant_bloc.dart';
import 'paginated_mixin.dart';

abstract class BasePaginatedBloc<Paginated extends PaginatedInput<Data>, Data>
    extends BaseIndependentBloc<Paginated, Data>
    with PaginatedMixin<Paginated, Data> {
  BasePaginatedBloc(
      {bool enableRetry = true,
      bool getOnCreate = true,
      List<Stream<ProviderState>> sources = const [],
      Data? currentData})
      : super(
            enableRetry: enableRetry,
            getOnCreate: getOnCreate,
            enableRefresh: false,
            currentData: currentData,
            sources: sources) {}
}
