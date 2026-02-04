abstract class BranchStockDetailsEvent {
  const BranchStockDetailsEvent();
}

class LoadBranchStockDetails extends BranchStockDetailsEvent {
  final String stockId;

  const LoadBranchStockDetails({required this.stockId});
}

class RefreshBranchStockDetails extends BranchStockDetailsEvent {
  final String stockId;

  const RefreshBranchStockDetails({required this.stockId});
}
