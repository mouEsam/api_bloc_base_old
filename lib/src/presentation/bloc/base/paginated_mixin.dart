import 'package:api_bloc_base/api_bloc_base.dart';

mixin PaginatedMixin<Data> on BaseConverterBloc<dynamic, Data> {
  int get startPage => 1;

  int _currentPage;

  int get currentPage => _currentPage ?? startPage;

  @override
  void setData(Data newData) {
    final data = appendData(newData, currentData);
    super.setData(data);
  }

  Data appendData(Data newData, Data oldData);

  @override
  Future<Data> reset() {
    _currentPage = startPage;
    return super.reset();
  }

  @override
  Future<Data> refresh() {
    _currentPage = startPage;
    return super.refresh();
  }
}
