import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../../../api_bloc_base.dart';

export 'working_state.dart';

abstract class FilterType {}

abstract class BaseListingBloc<Output, Filtering extends FilterType>
    extends BaseConverterBloc<Output, Output> {
  final int searchDelayMillis;

  get inputStream =>
      CombineLatestStream.combine3<Output, Filtering?, String, Output>(
              super.inputStream, filterStream, queryStream, (a, b, c) => a)
          .asBroadcastStream(onCancel: (sub) => sub.cancel());

  BaseListingBloc(
      {this.searchDelayMillis = 1000,
      BaseProviderBloc<Output>? sourceBloc,
      Output? currentData})
      : super(sourceBloc: sourceBloc, currentData: currentData);

  Output convertInput(Output output) => applyFilter(output, filter, query);

  Output applyFilter(Output output, Filtering? filter, String query) {
    return output;
  }

  final _filterSubject = BehaviorSubject<Filtering?>()..value = null;
  Stream<Filtering?> get filterStream => _filterSubject.shareValue();
  Filtering? get filter => _filterSubject.valueOrNull;
  set filter(Filtering? filter) {
    _filterSubject.add(filter);
  }

  final _querySubject = BehaviorSubject<String>()..value = '';
  Stream<String> get queryStream => _querySubject
      .shareValue()
      .debounceTime(Duration(milliseconds: searchDelayMillis));
  String get query => _querySubject.value;
  set query(String query) {
    _querySubject.add(query);
  }

  @override
  Future<void> close() {
    _filterSubject.close();
    _querySubject.close();
    return super.close();
  }
}
