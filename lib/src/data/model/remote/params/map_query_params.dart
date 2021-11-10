import 'package:api_bloc_base/src/data/model/remote/params/query_params.dart';

class MapQueryParams extends QueryParams {
  const MapQueryParams(this.map);

  final Map<String, dynamic> map;

  @override
  getQueryParams() => map;
}
