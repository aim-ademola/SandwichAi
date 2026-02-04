// lib/src/features/stock_control/bloc/processing_transfer_bloc/event.dart

import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/processing_transfer_model.dart';

abstract class ProcessingTransferEvent extends Equatable {
  const ProcessingTransferEvent();

  @override
  List<Object?> get props => [];
}

class CreateProcessingTransfer extends ProcessingTransferEvent {
  final ProcessingTransferRequest request;

  const CreateProcessingTransfer({required this.request});

  @override
  List<Object?> get props => [request];
}

class LoadProcessingTransfers extends ProcessingTransferEvent {
  final String branchId;
  final String? status;

  const LoadProcessingTransfers({required this.branchId, this.status});

  @override
  List<Object?> get props => [branchId, status];
}

class RefreshProcessingTransfers extends ProcessingTransferEvent {
  final String branchId;
  final String? status;

  const RefreshProcessingTransfers({required this.branchId, this.status});

  @override
  List<Object?> get props => [branchId, status];
}

class FilterTransfersByStatus extends ProcessingTransferEvent {
  final String status;

  const FilterTransfersByStatus({required this.status});

  @override
  List<Object?> get props => [status];
}

class ReceiveProcessingTransfer extends ProcessingTransferEvent {
  final String transferId;
  final ReceiveTransferRequest request;

  const ReceiveProcessingTransfer({
    required this.transferId,
    required this.request,
  });

  @override
  List<Object?> get props => [transferId, request];
}
