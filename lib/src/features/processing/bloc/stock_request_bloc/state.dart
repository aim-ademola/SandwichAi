import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/processing/data/model/stock_reuest_model.dart';

enum StockRequestErrorType { network, timeout, server, validation, general }

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

class StockRequestEmpty extends StockRequestState {
  const StockRequestEmpty();
}

class StockRequestListLoaded extends StockRequestState {
  final List<StockRequest> requests;
  final List<StockRequest> pendingRequests;
  final List<StockRequest> completedRequests;
  final String? currentFilter;
  final String? currentDepartmentFilter;

  const StockRequestListLoaded({
    required this.requests,
    required this.pendingRequests,
    required this.completedRequests,
    this.currentDepartmentFilter,
    this.currentFilter,
  });

  @override
  List<Object?> get props => [
    requests,
    pendingRequests,
    completedRequests,
    currentFilter,
    currentDepartmentFilter,
  ];
}

class StockRequestRefreshing extends StockRequestState {
  final List<StockRequest> currentRequests;

  const StockRequestRefreshing({required this.currentRequests});

  @override
  List<Object?> get props => [currentRequests];
}

class StockRequestCreating extends StockRequestState {
  const StockRequestCreating();
}

class StockRequestCreated extends StockRequestState {
  final StockRequest request;

  const StockRequestCreated({required this.request});

  @override
  List<Object?> get props => [request];
}

class StockRequestDetailsLoaded extends StockRequestState {
  final StockRequest request;

  const StockRequestDetailsLoaded({required this.request});

  @override
  List<Object?> get props => [request];
}

class StockRequestCompleting extends StockRequestState {
  final String requestId;

  const StockRequestCompleting({required this.requestId});

  @override
  List<Object?> get props => [requestId];
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
  List<Object?> get props => [request, message, currentRequests];
}

class StockRequestError extends StockRequestState {
  final String error;
  final StockRequestErrorType errorType;

  const StockRequestError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}
