abstract class SupplierStatsEvent {
  const SupplierStatsEvent();
}

class LoadSupplierStats extends SupplierStatsEvent {
  const LoadSupplierStats();
}

class RefreshSupplierStats extends SupplierStatsEvent {
  const RefreshSupplierStats();
}

class ResetSupplierStats extends SupplierStatsEvent {
  const ResetSupplierStats();
}
