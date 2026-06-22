import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/bulk_inventory_upload_model.dart';

abstract class BulkInventoryUploadState extends Equatable {
  const BulkInventoryUploadState();

  @override
  List<Object?> get props => [];
}

class BulkInventoryUploadInitial extends BulkInventoryUploadState {
  const BulkInventoryUploadInitial();
}

class BulkInventoryUploadInProgress extends BulkInventoryUploadState {
  final double progress;

  const BulkInventoryUploadInProgress({required this.progress});

  @override
  List<Object?> get props => [progress];
}

class BulkInventoryUploadSuccess extends BulkInventoryUploadState {
  final BulkInventoryUploadResponse response;

  const BulkInventoryUploadSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

class BulkInventoryUploadFailure extends BulkInventoryUploadState {
  final String message;

  const BulkInventoryUploadFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
