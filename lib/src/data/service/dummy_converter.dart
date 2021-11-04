import 'package:api_bloc_base/api_bloc_base.dart';

import 'converter.dart';

class DummyConverter extends BaseResponseConverter<BaseApiResponse, dynamic> {
  const DummyConverter() : super();

  convert(initialData) {
    throw UnimplementedError();
  }

  @override
  get converters => throw UnimplementedError();
}
