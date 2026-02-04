// lib/src/features/stock_control/bloc/processing_transfer_bloc/state.dart

import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/processing_transfer_model.dart';

abstract class ProcessingTransferState extends Equatable {
  const ProcessingTransferState();

  @override
  List<Object?> get props => [];
}

class ProcessingTransferInitial extends ProcessingTransferState {
  const ProcessingTransferInitial();
}

class ProcessingTransferLoading extends ProcessingTransferState {
  const ProcessingTransferLoading();
}

class ProcessingTransferCreating extends ProcessingTransferState {
  const ProcessingTransferCreating();
}

class ProcessingTransferCreated extends ProcessingTransferState {
  final ProcessingTransferResponse transfer;

  const ProcessingTransferCreated({required this.transfer});

  @override
  List<Object?> get props => [transfer];
}

class ProcessingTransferListLoaded extends ProcessingTransferState {
  final List<ProcessingTransferResponse> transfers;
  final List<ProcessingTransferResponse> pendingTransfers;
  final List<ProcessingTransferResponse> completedTransfers;
  final String? currentFilter;

  const ProcessingTransferListLoaded({
    required this.transfers,
    required this.pendingTransfers,
    required this.completedTransfers,
    this.currentFilter,
  });

  @override
  List<Object?> get props => [
    transfers,
    pendingTransfers,
    completedTransfers,
    currentFilter,
  ];

  ProcessingTransferListLoaded copyWith({
    List<ProcessingTransferResponse>? transfers,
    List<ProcessingTransferResponse>? pendingTransfers,
    List<ProcessingTransferResponse>? completedTransfers,
    String? currentFilter,
  }) {
    return ProcessingTransferListLoaded(
      transfers: transfers ?? this.transfers,
      pendingTransfers: pendingTransfers ?? this.pendingTransfers,
      completedTransfers: completedTransfers ?? this.completedTransfers,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class ProcessingTransferRefreshing extends ProcessingTransferState {
  final List<ProcessingTransferResponse> currentTransfers;

  const ProcessingTransferRefreshing({required this.currentTransfers});

  @override
  List<Object?> get props => [currentTransfers];
}

class ProcessingTransferEmpty extends ProcessingTransferState {
  const ProcessingTransferEmpty();
}

class ProcessingTransferError extends ProcessingTransferState {
  final String error;
  final ProcessingTransferErrorType errorType;

  const ProcessingTransferError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}

enum ProcessingTransferErrorType {
  network,
  timeout,
  server,
  validation,
  general,
}

class ProcessingTransferReceiving extends ProcessingTransferState {
  const ProcessingTransferReceiving();

  @override
  List<Object?> get props => [];
}

class ProcessingTransferReceived extends ProcessingTransferState {
  final ProcessingTransferResponse transfer;

  const ProcessingTransferReceived({required this.transfer});

  @override
  List<Object?> get props => [transfer];
}
