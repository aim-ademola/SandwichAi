import 'package:sandwich_ai/src/features/procurement/data/model/procurement_order_model.dart';

enum ProcurementErrorType { network, timeout, server, validation, general }

abstract class ProcurementState {
  const ProcurementState();
}

class ProcurementInitial extends ProcurementState {
  const ProcurementInitial();
}

class ProcurementLoading extends ProcurementState {
  const ProcurementLoading();
}

class ProcurementRefreshing extends ProcurementState {
  final ProcurementResponse currentData;
  final String selectedStatus;

  const ProcurementRefreshing({
    required this.currentData,
    required this.selectedStatus,
  });
}

class ProcurementLoaded extends ProcurementState {
  final ProcurementResponse response;
  final String selectedStatus;
  final List<ProcurementRequest> filteredOrders;

  const ProcurementLoaded({
    required this.response,
    required this.selectedStatus,
    required this.filteredOrders,
  });

  ProcurementLoaded copyWith({
    ProcurementResponse? response,
    String? selectedStatus,
    List<ProcurementRequest>? filteredOrders,
  }) {
    return ProcurementLoaded(
      response: response ?? this.response,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      filteredOrders: filteredOrders ?? this.filteredOrders,
    );
  }

  int get pendingCount =>
      response.data.where((req) => req.status == 'PENDING').length;
  int get approvedCount =>
      response.data.where((req) => req.status == 'APPROVED').length;
  int get rejectedCount =>
      response.data.where((req) => req.status == 'REJECTED').length;
  int get completedCount =>
      response.data.where((req) => req.status == 'COMPLETED').length;
}

class ProcurementEmpty extends ProcurementState {
  const ProcurementEmpty();
}

class ProcurementError extends ProcurementState {
  final String error;
  final ProcurementErrorType errorType;

  const ProcurementError({required this.error, required this.errorType});
}
