import 'package:api_bloc_base/src/data/model/remote/response/base_api_response.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:collection/collection.dart' show IterableExtension;

abstract class BaseResponseConverter<T extends BaseApiResponse, X> {
  final String Function(String)? handlePath;

  const BaseResponseConverter([this.handlePath]);

  String get defaultErrorMessage => 'Error';

  List<BaseModelConverter> get converters;

  BaseModelConverter? getConverter(Type inputType, Type outputType) {
    print("$inputType $outputType");
    print(converters.map((e) => "${e.inputType} ${e.outputType}"));
    final converter = converters.firstWhereOrNull((element) =>
        element.acceptsInput(inputType) && element.returnsOutput(outputType));
    return converter;
  }

  X resolveConverter<I, X>(I? input) {
    final converter = getConverter(I, X)!;
    return converter.convert(input);
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

  bool isError(BaseApiResponse? initialData) {
    return initialData?.errors != null ||
        initialData?.error != null ||
        initialData?.message != null;
  }

  bool isSuccess(BaseApiResponse initialData) {
    return initialData.success != null;
  }

  bool hasData(BaseApiResponse initialData) {
    return !isError(initialData) && !isSuccess(initialData);
  }

  ResponseEntity? response(BaseApiResponse initialData) {
    if (isError(initialData)) {
      return Failure(
          initialData!.message ?? initialData.error ?? defaultErrorMessage,
          initialData.errors);
    } else if (isSuccess(initialData)) {
      return Success(initialData.success);
    }
    return null;
  }

  X convert(T initialData);
}

abstract class BaseModelConverter<Input, Output> {
  final bool failIfError;

  const BaseModelConverter([this.failIfError = false]);

  Type get inputType => Input;
  Type get outputType => Output;

  bool acceptsInput(Type input) => input == inputType;
  bool returnsOutput(Type output) => output == outputType;

  Output? convert(Input initialData);

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
