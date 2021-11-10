import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:equatable/equatable.dart';

class FormBlocData<Data> extends Equatable {
  final Data data;
  final bool isEdit;

  const FormBlocData(this.data, this.isEdit);

  @override
  get props => [this.data, this.isEdit];
}

mixin FormMixin<Data> on BaseWorkingBloc<FormBlocData<Data>> {
  static const EDIT_OPERATION = "EDIT_OPERATION";

  late Data data;
  bool isEdit = false;

  get currentData => FormBlocData(data, isEdit);

  void editMode() {
    isEdit = true;
    emitLoaded();
  }

  void viewMode() {
    isEdit = false;
    emitLoaded();
  }

  Future<bool> Function()? get goBack {
    if (!isEdit) {
      return null;
    } else {
      return () async {
        isEdit = false;
        emitLoaded();
        return false;
      };
    }
  }
}
