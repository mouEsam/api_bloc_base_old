import 'package:api_bloc_base/api_bloc_base.dart';

class SimplePaginatedInput extends PaginatedInput {
  SimplePaginatedInput(input, String? nextUrl, int currentPage)
      : super(input, nextUrl, currentPage);
}
