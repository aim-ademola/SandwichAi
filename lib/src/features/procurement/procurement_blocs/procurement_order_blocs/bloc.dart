import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_order_repo.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_order_blocs/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_order_blocs/state.dart';

class ProcurementBloc extends Bloc<ProcurementEvent, ProcurementState> {
  final ProcurementRepositoryInterface _repository;
  String branchId = '';

  ProcurementBloc({required ProcurementRepositoryInterface repository})
    : _repository = repository,
      super(const ProcurementInitial()) {
    _getBranchId();
    on<LoadProcurementOrders>(_onLoadProcurementOrders);
    on<RefreshProcurementOrders>(_onRefreshProcurementOrders);
    on<FilterByStatus>(_onFilterByStatus);
  }

  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  Future<void> _onLoadProcurementOrders(
    LoadProcurementOrders event,
    Emitter<ProcurementState> emit,
  ) async {
    try {
      emit(const ProcurementLoading());

      final effectiveBranchId = event.branchId.isNotEmpty
          ? event.branchId
          : branchId;
      branchId = effectiveBranchId;
      final response = await _repository.getProcurementOrders(
        effectiveBranchId,
      );

      await response.when(
        success: (data) async {
          if (!data.isValid) {
            emit(
              const ProcurementError(
                error: 'No procurement orders found for this branch',
                errorType: ProcurementErrorType.validation,
              ),
            );
            return;
          }

          if (data.data.isEmpty) {
            emit(const ProcurementEmpty());
            return;
          }

          emit(
            ProcurementLoaded(
              response: data,
              selectedStatus: 'PENDING',
              filteredOrders: data.getByStatus('PENDING'),
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(ProcurementError(error: error.toString(), errorType: errorType));
        },
      );
    } catch (e) {
      emit(
        const ProcurementError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: ProcurementErrorType.general,
        ),
      );
    }
  }

  Future<void> _onRefreshProcurementOrders(
    RefreshProcurementOrders event,
    Emitter<ProcurementState> emit,
  ) async {
    if (state is! ProcurementLoaded) {
      add(LoadProcurementOrders(branchId: branchId));
      return;
    }

    final currentState = state as ProcurementLoaded;
    emit(
      ProcurementRefreshing(
        currentData: currentState.response,
        selectedStatus: currentState.selectedStatus,
      ),
    );

    final response = await _repository.getProcurementOrders(branchId);

    await response.when(
      success: (data) async {
        if (data.data.isEmpty) {
          emit(const ProcurementEmpty());
          return;
        }

        final filteredOrders = data.getByStatus(currentState.selectedStatus);

        emit(
          ProcurementLoaded(
            response: data,
            selectedStatus: currentState.selectedStatus,
            filteredOrders: filteredOrders,
          ),
        );
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(ProcurementError(error: error.toString(), errorType: errorType));
      },
    );
  }

  void _onFilterByStatus(FilterByStatus event, Emitter<ProcurementState> emit) {
    if (state is! ProcurementLoaded) return;

    final currentState = state as ProcurementLoaded;

    // Get filtered orders for the selected status
    final filteredOrders = currentState.response.getByStatus(event.status);

    emit(
      currentState.copyWith(
        selectedStatus: event.status,
        filteredOrders: filteredOrders,
      ),
    );
  }

  ProcurementErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return ProcurementErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return ProcurementErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return ProcurementErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return ProcurementErrorType.validation;
    }

    return ProcurementErrorType.general;
  }
}
