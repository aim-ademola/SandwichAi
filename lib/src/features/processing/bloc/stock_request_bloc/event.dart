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

/// Generic action event — covers approve, cancel, complete, queue, reject
class PerformStockRequestAction extends StockRequestEvent {
  final String requestId;
  final StockRequestAction action;

  const PerformStockRequestAction({
    required this.requestId,
    required this.action,
  });

  @override
  List<Object?> get props => [requestId, action];
}

class LoadStockRequestStatus extends StockRequestEvent {
  final String requestId;

  const LoadStockRequestStatus({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

/// Enum representing all available actions on a stock request
enum StockRequestAction {
  approve,
  cancel,
  complete,
  queue,
  reject,
  process;

  String get endpoint => switch (this) {
    approve => 'approve',
    cancel => 'cancel',
    complete => 'complete',
    queue => 'queue',
    reject => 'reject',
    process => 'process',
  };

  String get label => switch (this) {
    approve => 'Approved',
    cancel => 'Cancelled',
    complete => 'Completed',
    queue => 'Queued',
    reject => 'Rejected',
    process => 'process',
  };

  String get successMessage => switch (this) {
    approve => 'Stock request approved successfully!',
    cancel => 'Stock request cancelled successfully!',
    complete => 'Stock request completed successfully!',
    queue => 'Stock request queued successfully!',
    reject => 'Stock request rejected successfully!',
    process => 'Stock request processed succssfully!',
  };
}
