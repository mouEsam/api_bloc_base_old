import 'package:api_bloc_base/src/data/model/remote/response/base_api_response.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:collection/collection.dart' show IterableExtension;

abstract class Converter<IN, OUT> {
  const Converter();
  Type get inputType => IN;
  Type get outputType => OUT;
  bool acceptsInput(Type input) => input == inputType;
  bool returnsOutput(Type output) => output == outputType;
  List<Converter> get converters;
  OUT? convert(IN initialData);
  Converter? getConverter(Type inputType, Type outputType) {
    final converter = converters.firstWhereOrNull((element) =>
        element.acceptsInput(inputType) && element.returnsOutput(outputType));
    return converter;
  }

  X requireConverter<I, X>(I? input) {
    return resolveConverter(input)!;
  }

  X? resolveConverter<I, X>(I? input) {
    if (input == null) return null;
    final converter = getConverter(I, X);
    return converter?.convert(input);
  }

  List<X> resolveListConverter<X, Y>(List<Y>? input) {
    final converter = getConverter(Y, X);
    List<X> result = input
            ?.map((item) => converter?.convert(item))
            .whereType<X>()
            .toList() ??
        <X>[];
    return result;
  }
}

abstract class BaseResponseConverter<T extends BaseApiResponse, X>
    extends Converter<T, X> {
  final String Function(String)? handlePath;

  const BaseResponseConverter([this.handlePath]);

  X convert(T initialData);

  bool isErrorMessage(BaseApiResponse initialData) {
    return initialData.errors != null ||
        initialData.error != null ||
        initialData.message != null;
  }

  bool isSuccessMessage(BaseApiResponse initialData) {
    return initialData.success == true || initialData.success is String;
  }

  bool hasData(T initialData) {
    return initialData.data != null ||
        (initialData.success == true && !isErrorMessage(initialData)) ||
        (!isSuccessMessage(initialData) && !isErrorMessage(initialData));
  }

  ResponseEntity? response(BaseApiResponse initialData) {
    if (isSuccessMessage(initialData)) {
      return Success(initialData.message ??
          (initialData.success is String ? initialData.success : null));
    } else if (isErrorMessage(initialData)) {
      return Failure(
          initialData.message ?? initialData.error, initialData.errors);
    }
    return null;
  }
}

abstract class BaseModelConverter<Input, Output>
    extends Converter<Input, Output> {
  final bool failIfError;

  const BaseModelConverter([this.failIfError = false]);

  List<Converter> get converters => [];

  Output? convertSingle(Input? initialData) {
    Output? result;
    if (failIfError) {
      result = initialData == null ? null : convert(initialData);
    } else {
      try {
        result = initialData == null ? null : convert(initialData);
      } catch (e, s) {
        print(e);
        print(s);
        result = null;
      }
    }
    return result;
  }

  List<Output> convertList(List<Input?>? initialData) {
    final result = initialData
            ?.map((itemModel) => convertSingle(itemModel))
            .whereType<Output>()
            .toList() ??
        <Output>[];
    return result;
  }
}
