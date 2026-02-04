abstract class ProcurementEvent {
  const ProcurementEvent();
}

class LoadProcurementOrders extends ProcurementEvent {
  final String branchId;

  const LoadProcurementOrders({required this.branchId});
}

class RefreshProcurementOrders extends ProcurementEvent {
  const RefreshProcurementOrders();
}

class FilterByStatus extends ProcurementEvent {
  final String status;

  const FilterByStatus({required this.status});
}
