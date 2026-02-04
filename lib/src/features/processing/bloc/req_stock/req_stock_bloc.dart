import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/processing/data/model/req_stock_model.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/req_stock.dart'
    show StockRequestRepositoryInterface;

abstract class StockRequestEvent {}

class LoadStockRequests extends StockRequestEvent {
  final String branchId;
  final String? status;

  LoadStockRequests({required this.branchId, this.status});
}

class RefreshStockRequests extends StockRequestEvent {
  final String branchId;
  final String? status;

  RefreshStockRequests({required this.branchId, this.status});
}

class CreateStockRequest extends StockRequestEvent {
  final CreateStockRequestRequest request;

  CreateStockRequest({required this.request});
}

class FilterRequestsByStatus extends StockRequestEvent {
  final String? status;

  FilterRequestsByStatus({this.status});
}

class LoadStockRequestDetails extends StockRequestEvent {
  final String requestId;

  LoadStockRequestDetails({required this.requestId});
}

class CompleteStockRequest extends StockRequestEvent {
  final String requestId;

  CompleteStockRequest({required this.requestId});
}

abstract class StockRequestState extends Equatable {
  const StockRequestState();

  @override
  List<Object?> get props => [];
}

class StockRequestInitial extends StockRequestState {
  const StockRequestInitial();
}

class StockRequestLoading extends StockRequestState {
  const StockRequestLoading();
}

class StockRequestListLoaded extends StockRequestState {
  final List<StockRequest> requests;
  final List<StockRequest> pendingRequests;
  final List<StockRequest> completedRequests;
  final String? currentFilter;

  const StockRequestListLoaded({
    required this.requests,
    required this.pendingRequests,
    required this.completedRequests,
    this.currentFilter,
  });

  @override
  List<Object?> get props => [
    requests,
    pendingRequests,
    completedRequests,
    currentFilter,
  ];
}

class StockRequestRefreshing extends StockRequestState {
  final List<StockRequest> currentRequests;

  const StockRequestRefreshing({required this.currentRequests});

  @override
  List<Object> get props => [currentRequests];
}

class StockRequestEmpty extends StockRequestState {
  const StockRequestEmpty();
}

class StockRequestCreating extends StockRequestState {
  const StockRequestCreating();
}

class StockRequestCreated extends StockRequestState {
  final StockRequest request;

  const StockRequestCreated({required this.request});

  @override
  List<Object> get props => [request];
}

class StockRequestDetailsLoaded extends StockRequestState {
  final StockRequest request;

  const StockRequestDetailsLoaded({required this.request});

  @override
  List<Object> get props => [request];
}

class StockRequestCompleted extends StockRequestState {
  final StockRequest request;
  final String message;
  final List<StockRequest> currentRequests;

  const StockRequestCompleted({
    required this.request,
    required this.message,
    required this.currentRequests,
  });

  @override
  List<Object> get props => [request, message, currentRequests];
}

enum StockRequestErrorType { network, timeout, server, validation, general }

class StockRequestError extends StockRequestState {
  final String error;
  final StockRequestErrorType errorType;

  const StockRequestError({
    required this.error,
    this.errorType = StockRequestErrorType.general,
  });

  @override
  List<Object> get props => [error, errorType];
}

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

          final pending = data.data
              .where(
                (request) =>
                    request.status == 'PENDING' || request.status == 'APPROVED',
              )
              .toList();

          final completed = data.data
              .where(
                (request) =>
                    request.status == 'COMPLETED' ||
                    request.status == 'REJECTED',
              )
              .toList();

          emit(
            StockRequestListLoaded(
              requests: data.data,
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
      add(LoadStockRequests(branchId: branchId, status: event.status));
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

        final pending = data.data
            .where(
              (request) =>
                  request.status == 'PENDING' || request.status == 'APPROVED',
            )
            .toList();

        final completed = data.data
            .where(
              (request) =>
                  request.status == 'COMPLETED' || request.status == 'REJECTED',
            )
            .toList();

        emit(
          StockRequestListLoaded(
            requests: data.data,
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

      final response = await _repository.createStockRequest(event.request);

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

    add(LoadStockRequests(branchId: branchId, status: event.status));
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
