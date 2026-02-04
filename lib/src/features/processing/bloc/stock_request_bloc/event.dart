import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/processing/data/model/stock_reuest_model.dart';

abstract class StockRequestEvent extends Equatable {
  const StockRequestEvent();

  @override
  List<Object?> get props => [];
}

class LoadStockRequests extends StockRequestEvent {
  final String branchId;
  final String? status;
  final String? department;

  const LoadStockRequests({
    required this.branchId,
    this.status,
    this.department,
  });

  @override
  List<Object?> get props => [branchId, status, department];
}

class RefreshStockRequests extends StockRequestEvent {
  final String branchId;
  final String? status;
  final String? department;

  const RefreshStockRequests({
    required this.branchId,
    this.status,
    this.department,
  });

  @override
  List<Object?> get props => [branchId, status, department];
}

class CreateStockRequest extends StockRequestEvent {
  final StockRequest request;

  const CreateStockRequest({required this.request});

  @override
  List<Object?> get props => [request];
}

class FilterRequestsByStatus extends StockRequestEvent {
  final String? status;
  final String? department;

  const FilterRequestsByStatus({this.status, this.department});

  @override
  List<Object?> get props => [status, department];
}

class LoadStockRequestDetails extends StockRequestEvent {
  final String requestId;

  const LoadStockRequestDetails({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

class CompleteStockRequest extends StockRequestEvent {
  final String requestId;

  const CompleteStockRequest({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}
