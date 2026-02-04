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
    on<CompleteStockRequest>(_onCompleteRequest);
  }

  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  Future<void> _onLoadRequests(
    LoadStockRequests event,
    Emitter<StockRequestState> emit,
  ) async {
    try {
      emit(const StockRequestLoading());

      final response = await _repository.getStockRequests(
        branchId: branchId,
        status: event.status,
      );

      await response.when(
        success: (data) async {
          if (data.data.isEmpty) {
            emit(const StockRequestEmpty());
            return;
          }

          // Filter by department if provided
          var filteredData = data.data;
          if (event.department != null && event.department!.isNotEmpty) {
            filteredData = data.data
                .where((request) => request.department == event.department)
                .toList();
          }

          if (filteredData.isEmpty) {
            emit(const StockRequestEmpty());
            return;
          }

          final pending = filteredData
              .where(
                (request) =>
                    request.status == 'PENDING' || request.status == 'APPROVED',
              )
              .toList();

          final completed = filteredData
              .where(
                (request) =>
                    request.status == 'COMPLETED' ||
                    request.status == 'REJECTED',
              )
              .toList();

          emit(
            StockRequestListLoaded(
              requests: filteredData,
              pendingRequests: pending,
              completedRequests: completed,
              currentFilter: event.status,
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            StockRequestError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const StockRequestError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: StockRequestErrorType.general,
        ),
      );
    }
  }

  Future<void> _onRefreshRequests(
    RefreshStockRequests event,
    Emitter<StockRequestState> emit,
  ) async {
    if (state is! StockRequestListLoaded) {
      add(
        LoadStockRequests(
          branchId: branchId,
          status: event.status,
          department: event.department,
        ),
      );
      return;
    }

    final currentState = state as StockRequestListLoaded;
    emit(StockRequestRefreshing(currentRequests: currentState.requests));

    final response = await _repository.getStockRequests(
      branchId: branchId,
      status: event.status,
    );

    await response.when(
      success: (data) async {
        if (data.data.isEmpty) {
          emit(const StockRequestEmpty());
          return;
        }

        // Filter by department if provided
        var filteredData = data.data;
        if (event.department != null && event.department!.isNotEmpty) {
          filteredData = data.data
              .where((request) => request.department == event.department)
              .toList();
        }

        if (filteredData.isEmpty) {
          emit(const StockRequestEmpty());
          return;
        }

        final pending = filteredData
            .where(
              (request) =>
                  request.status == 'PENDING' || request.status == 'APPROVED',
            )
            .toList();

        final completed = filteredData
            .where(
              (request) =>
                  request.status == 'COMPLETED' || request.status == 'REJECTED',
            )
            .toList();

        emit(
          StockRequestListLoaded(
            requests: filteredData,
            pendingRequests: pending,
            completedRequests: completed,
            currentFilter: event.status,
          ),
        );
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(StockRequestError(error: error.toString(), errorType: errorType));
      },
    );
  }

  Future<void> _onCreateRequest(
    CreateStockRequest event,
    Emitter<StockRequestState> emit,
  ) async {
    try {
      emit(const StockRequestCreating());

      final response = await _repository.createStockRequest(
        event.request as CreateStockRequestRequest,
      );

      await response.when(
        success: (data) async {
          emit(StockRequestCreated(request: data.data));

          // Reload the list
          add(LoadStockRequests(branchId: branchId));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            StockRequestError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const StockRequestError(
          error: 'An unexpected error occurred while creating request.',
          errorType: StockRequestErrorType.general,
        ),
      );
    }
  }

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
        success: (data) async {
          emit(StockRequestDetailsLoaded(request: data));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            StockRequestError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const StockRequestError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: StockRequestErrorType.general,
        ),
      );
    }
  }

  Future<void> _onCompleteRequest(
    CompleteStockRequest event,
    Emitter<StockRequestState> emit,
  ) async {
    try {
      final response = await _repository.completeStockRequest(event.requestId);

      await response.when(
        success: (data) async {
          // Get current requests to pass along
          List<StockRequest> currentRequests = [];
          if (state is StockRequestListLoaded) {
            currentRequests = (state as StockRequestListLoaded).requests;
          }

          emit(
            StockRequestCompleted(
              request: data,
              message: 'Stock request completed successfully!',
              currentRequests: currentRequests,
            ),
          );

          // Small delay for user to see the success message
          await Future.delayed(const Duration(milliseconds: 800));

          // Get the current filter if available
          String? currentFilter;
          if (state is StockRequestCompleted) {
            // We need to track the filter separately or get it from somewhere
            // For now, just reload all
            currentFilter = null;
          }

          // Use RefreshStockRequests to reload without full loading spinner
          if (state is StockRequestListLoaded ||
              state is StockRequestCompleted) {
            add(
              RefreshStockRequests(branchId: branchId, status: currentFilter),
            );
          } else {
            add(LoadStockRequests(branchId: branchId, status: currentFilter));
          }
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            StockRequestError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const StockRequestError(
          error: 'An unexpected error occurred while completing request.',
          errorType: StockRequestErrorType.general,
        ),
      );
    }
  }

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

  StockRequestErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return StockRequestErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return StockRequestErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return StockRequestErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return StockRequestErrorType.validation;
    }

    return StockRequestErrorType.general;
  }
}
