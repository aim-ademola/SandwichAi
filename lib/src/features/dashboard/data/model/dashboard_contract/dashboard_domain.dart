enum DashboardDomain { pos, procurement, processing, kitchen, stockControl }

extension DashboardDomainX on DashboardDomain {
  String get apiValue {
    switch (this) {
      case DashboardDomain.pos:
        return 'pos';
      case DashboardDomain.procurement:
        return 'procurement';
      case DashboardDomain.processing:
        return 'processing';
      case DashboardDomain.kitchen:
        return 'kitchen';
      case DashboardDomain.stockControl:
        return 'stock_control';
    }
  }

  String get title {
    switch (this) {
      case DashboardDomain.pos:
        return 'POS dashboard';
      case DashboardDomain.procurement:
        return 'Procurement dashboard';
      case DashboardDomain.processing:
        return 'Processing dashboard';
      case DashboardDomain.kitchen:
        return 'Kitchen dashboard';
      case DashboardDomain.stockControl:
        return 'Stock control dashboard';
    }
  }
}
