// lib/src/features/stock_control/bloc/processing_transfer_bloc/bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/processing_transfrer_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/processing_transfrer_bloc/state.dart';

import 'package:sandwich_ai/src/features/stock_control/data/repo/processing_transfer_repo.dart';

class ProcessingTransferBloc
    extends Bloc<ProcessingTransferEvent, ProcessingTransferState> {
  final ProcessingTransferRepositoryInterface _repository;
  String branchId = '';

  ProcessingTransferBloc({
    required ProcessingTransferRepositoryInterface repository,
  }) : _repository = repository,
       super(const ProcessingTransferInitial()) {
    _getBranchId();
    on<CreateProcessingTransfer>(_onCreateTransfer);
    on<LoadProcessingTransfers>(_onLoadTransfers);
    on<RefreshProcessingTransfers>(_onRefreshTransfers);
    on<FilterTransfersByStatus>(_onFilterByStatus);
    on<ReceiveProcessingTransfer>(_onReceiveTransfer);
  }

  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  Future<void> _onReceiveTransfer(
    ReceiveProcessingTransfer event,
    Emitter<ProcessingTransferState> emit,
  ) async {
    try {
      emit(const ProcessingTransferReceiving());

      final response = await _repository.receiveTransfer(
        transferId: event.transferId,
        request: event.request,
      );

      await response.when(
        success: (data) async {
          emit(ProcessingTransferReceived(transfer: data));

          add(LoadProcessingTransfers(branchId: branchId));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            ProcessingTransferError(
              error: error.toString(),
              errorType: errorType,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        const ProcessingTransferError(
          error: 'An unexpected error occurred while receiving transfer.',
          errorType: ProcessingTransferErrorType.general,
        ),
      );
    }
  }

  Future<void> _onCreateTransfer(
    CreateProcessingTransfer event,
    Emitter<ProcessingTransferState> emit,
  ) async {
    try {
      emit(const ProcessingTransferCreating());

      final response = await _repository.createTransfer(event.request);

      await response.when(
        success: (data) async {
          emit(ProcessingTransferCreated(transfer: data));

          add(LoadProcessingTransfers(branchId: branchId));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            ProcessingTransferError(
              error: error.toString(),
              errorType: errorType,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        const ProcessingTransferError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: ProcessingTransferErrorType.general,
        ),
      );
    }
  }

  Future<void> _onLoadTransfers(
    LoadProcessingTransfers event,
    Emitter<ProcessingTransferState> emit,
  ) async {
    try {
      emit(const ProcessingTransferLoading());

      final response = await _repository.getTransfers(
        branchId: branchId,
        status: event.status,
      );

      await response.when(
        success: (data) async {
          if (data.isEmpty) {
            emit(const ProcessingTransferEmpty());
            return;
          }

          final pending = data
              .where(
                (transfer) =>
                    transfer.status == 'PENDING' ||
                    transfer.status == 'IN_TRANSIT',
              )
              .toList();

          final completed = data
              .where(
                (transfer) =>
                    transfer.status == 'RECEIVED' ||
                    transfer.status == 'REJECTED',
              )
              .toList();

          emit(
            ProcessingTransferListLoaded(
              transfers: data,
              pendingTransfers: pending,
              completedTransfers: completed,
              currentFilter: event.status,
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            ProcessingTransferError(
              error: error.toString(),
              errorType: errorType,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        const ProcessingTransferError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: ProcessingTransferErrorType.general,
        ),
      );
    }
  }

  Future<void> _onRefreshTransfers(
    RefreshProcessingTransfers event,
    Emitter<ProcessingTransferState> emit,
  ) async {
    if (state is! ProcessingTransferListLoaded) {
      add(LoadProcessingTransfers(branchId: branchId, status: event.status));
      return;
    }

    final currentState = state as ProcessingTransferListLoaded;
    emit(
      ProcessingTransferRefreshing(currentTransfers: currentState.transfers),
    );

    final response = await _repository.getTransfers(
      branchId: branchId,
      status: event.status,
    );

    await response.when(
      success: (data) async {
        if (data.isEmpty) {
          emit(const ProcessingTransferEmpty());
          return;
        }

        final pending = data
            .where(
              (transfer) =>
                  transfer.status == 'PENDING' ||
                  transfer.status == 'IN_TRANSIT',
            )
            .toList();

        final completed = data
            .where(
              (transfer) =>
                  transfer.status == 'RECEIVED' ||
                  transfer.status == 'REJECTED',
            )
            .toList();

        emit(
          ProcessingTransferListLoaded(
            transfers: data,
            pendingTransfers: pending,
            completedTransfers: completed,
            currentFilter: event.status,
          ),
        );
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(
          ProcessingTransferError(
            error: error.toString(),
            errorType: errorType,
          ),
        );
      },
    );
  }

  void _onFilterByStatus(
    FilterTransfersByStatus event,
    Emitter<ProcessingTransferState> emit,
  ) {
    if (state is! ProcessingTransferListLoaded) return;

    add(LoadProcessingTransfers(branchId: branchId, status: event.status));
  }

  ProcessingTransferErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return ProcessingTransferErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return ProcessingTransferErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return ProcessingTransferErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return ProcessingTransferErrorType.validation;
    }

    return ProcessingTransferErrorType.general;
  }
}
