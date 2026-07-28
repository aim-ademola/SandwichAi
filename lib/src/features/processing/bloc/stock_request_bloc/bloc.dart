import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/stock_reuest_model.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/stock_request_repo.dart';

class StockRequestBloc extends Bloc<StockRequestEvent, StockRequestState> {
  final StockRequestRepositoryInterface _repository;
  String branchId = '';

  StockRequestBloc({required StockRequestRepositoryInterface repository})
    : _repository = repository,
      super(const StockRequestInitial()) {
    _getBranchId();
    on<LoadStockRequests>(_onLoadRequests);
    on<RefreshStockRequests>(_onRefreshRequests);
    on<CreateStockRequest>(_onCreateRequest);
    on<FilterRequestsByStatus>(_onFilterByStatus);
    on<LoadStockRequestDetails>(_onLoadDetails);
    on<LoadStockRequestStatus>(_onLoadStatus);
    on<PerformStockRequestAction>(_onPerformAction);
  }

  void _getBranchId() async {
    branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
  }

  // ─── List / Refresh ───────────────────────────────────────────────────────

  Future<void> _onLoadRequests(
    LoadStockRequests event,
    Emitter<StockRequestState> emit,
  ) async {
    try {
      emit(const StockRequestLoading());

      // ✅ Always resolve branchId from cache — never trust the event's value
      final resolvedBranchId = branchId.isNotEmpty
          ? branchId
          : await AuthCacheHelper.instance.getBranchID() ?? '';

      if (resolvedBranchId.isEmpty) {
        emit(
          const StockRequestError(
            error: 'Branch ID not found. Please log in again.',
            errorType: StockRequestErrorType.general,
          ),
        );
        return;
      }

      // Cache it for future calls
      branchId = resolvedBranchId;

      final response = await _repository.getStockRequests(
        branchId: resolvedBranchId,
        status: event.status,
      );

      await response.when(
        success: (data) async =>
            emit(_buildListState(data.data, event.status, event.department)),
        error: (error) async => emit(_buildError(error as String)),
      );
    } catch (_) {
      emit(_unexpectedError());
    }
  }

  Future<void> _onRefreshRequests(
    RefreshStockRequests event,
    Emitter<StockRequestState> emit,
  ) async {
    if (state is! StockRequestListLoaded) {
      add(LoadStockRequests(branchId: branchId, status: event.status));
      return;
    }

    emit(
      StockRequestRefreshing(
        currentRequests: (state as StockRequestListLoaded).requests,
      ),
    );

    // ✅ Same resolution logic
    final resolvedBranchId = branchId.isNotEmpty
        ? branchId
        : await AuthCacheHelper.instance.getBranchID() ?? '';

    try {
      final response = await _repository.getStockRequests(
        branchId: resolvedBranchId,
        status: event.status,
      );

      await response.when(
        success: (data) async =>
            emit(_buildListState(data.data, event.status, event.department)),
        error: (error) async => emit(_buildError(error as String)),
      );
    } catch (_) {
      emit(_unexpectedError());
    }
  }

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<void> _onCreateRequest(
    CreateStockRequest event,
    Emitter<StockRequestState> emit,
  ) async {
    try {
      emit(const StockRequestCreating());
      final response = await _repository.createStockRequest(event.request);

      await response.when(
        success: (data) async {
          emit(StockRequestCreated(request: data.data));
          add(LoadStockRequests(branchId: branchId));
        },
        error: (error) async => emit(_buildError(error as String)),
      );
    } catch (_) {
      emit(_unexpectedError());
    }
  }

  // ─── Details & Status ────────────────────────────────────────────────────

  Future<void> _onLoadDetails(
    LoadStockRequestDetails event,
    Emitter<StockRequestState> emit,
  ) async {
    try {
      emit(const StockRequestLoading());
      final response = await _repository.getStockRequestDetails(
        event.requestId,
      );

      await response.when(
        success: (data) async => emit(StockRequestDetailsLoaded(request: data)),
        error: (error) async => emit(_buildError(error as String)),
      );
    } catch (_) {
      emit(_unexpectedError());
    }
  }

  Future<void> _onLoadStatus(
    LoadStockRequestStatus event,
    Emitter<StockRequestState> emit,
  ) async {
    try {
      final response = await _repository.getStockRequestStatus(event.requestId);

      await response.when(
        success: (data) async => emit(
          StockRequestStatusLoaded(
            requestId: event.requestId,
            status: data['status']?.toString() ?? '',
          ),
        ),
        error: (error) async => emit(_buildError(error as String)),
      );
    } catch (_) {
      emit(_unexpectedError());
    }
  }

  // ─── Generic Action ───────────────────────────────────────────────────────

  Future<void> _onPerformAction(
    PerformStockRequestAction event,
    Emitter<StockRequestState> emit,
  ) async {
    final currentRequests = _currentRequests();

    // Optimistically show in-progress state so the UI can reflect it immediately
    emit(
      StockRequestActionInProgress(
        requestId: event.requestId,
        action: event.action,
        currentRequests: currentRequests,
      ),
    );

    try {
      final response = await _repository.performAction(
        event.requestId,
        event.action,
      );

      await response.when(
        success: (data) async {
          emit(
            StockRequestActionSuccess(
              request: data,
              action: event.action,
              message: event.action.successMessage,
              currentRequests: currentRequests,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 800));

          // Silently refresh the list
          add(RefreshStockRequests(branchId: branchId));
        },
        error: (error) async => emit(_buildError(error as String)),
      );
    } catch (_) {
      emit(_unexpectedError());
    }
  }

  // ─── Filter ───────────────────────────────────────────────────────────────

  void _onFilterByStatus(
    FilterRequestsByStatus event,
    Emitter<StockRequestState> emit,
  ) {
    if (state is! StockRequestListLoaded) return;
    add(
      LoadStockRequests(
        branchId: branchId,
        status: event.status,
        department: event.department,
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  List<StockRequest> _currentRequests() {
    if (state is StockRequestListLoaded) {
      return (state as StockRequestListLoaded).requests;
    }
    if (state is StockRequestActionInProgress) {
      return (state as StockRequestActionInProgress).currentRequests;
    }
    return [];
  }

  StockRequestState _buildListState(
    List<StockRequest> data,
    String? status,
    String? department,
  ) {
    var filtered = data;
    if (department != null && department.isNotEmpty) {
      final normalizedDepartment = _normalizeFilterValue(department);
      filtered = data.where((request) {
        return _normalizeFilterValue(request.department) ==
            normalizedDepartment;
      }).toList();
    }

    final pending = filtered
        .where((r) => r.status == 'PENDING' || r.status == 'APPROVED')
        .toList();
    final completed = filtered
        .where((r) => r.status == 'COMPLETED' || r.status == 'REJECTED')
        .toList();

    return StockRequestListLoaded(
      requests: filtered,
      pendingRequests: pending,
      completedRequests: completed,
      currentFilter: status,
    );
  }

  String _normalizeFilterValue(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  StockRequestError _buildError(String error) {
    return StockRequestError(
      error: error,
      errorType: _determineErrorType(error),
    );
  }

  StockRequestError _unexpectedError() => const StockRequestError(
    error: 'An unexpected error occurred. Please try again.',
    errorType: StockRequestErrorType.general,
  );

  StockRequestErrorType _determineErrorType(String error) {
    final e = error.toLowerCase();
    if (e.contains('network') ||
        e.contains('connection') ||
        e.contains('internet')) {
      return StockRequestErrorType.network;
    }
    if (e.contains('timeout')) return StockRequestErrorType.timeout;
    if (e.contains('server') || e.contains('500') || e.contains('503')) {
      return StockRequestErrorType.server;
    }
    if (e.contains('format') || e.contains('validation')) {
      return StockRequestErrorType.validation;
    }
    return StockRequestErrorType.general;
  }
}
