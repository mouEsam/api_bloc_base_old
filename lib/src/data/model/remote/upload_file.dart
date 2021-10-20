import 'dart:io';

import 'package:equatable/equatable.dart';

class UploadFile extends Equatable {
  final String fileName;
  final File file;

  const UploadFile(this.fileName, this.file);

  @override
  get props => [this.fileName, this.file];
}
