import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/bulk_inventory_upload_model.dart';

abstract class BulkInventoryUploadEvent extends Equatable {
  const BulkInventoryUploadEvent();

  @override
  List<Object?> get props => [];
}

class UploadBulkInventoryFile extends BulkInventoryUploadEvent {
  final File file;
  final BulkInventoryUploadRequest request;

  const UploadBulkInventoryFile({required this.file, required this.request});

  @override
  List<Object?> get props => [file.path, request];
}

class ResetBulkInventoryUpload extends BulkInventoryUploadEvent {
  const ResetBulkInventoryUpload();
}
