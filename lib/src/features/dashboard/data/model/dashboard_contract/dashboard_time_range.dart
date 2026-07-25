enum DashboardTimeRange { today, week, month, custom }

extension DashboardTimeRangeX on DashboardTimeRange {
  String get apiValue {
    switch (this) {
      case DashboardTimeRange.today:
        return 'today';
      case DashboardTimeRange.week:
        return 'week';
      case DashboardTimeRange.month:
        return 'month';
      case DashboardTimeRange.custom:
        return 'custom';
    }
  }

  String get procurementValue {
    switch (this) {
      case DashboardTimeRange.today:
        return 'DAILY';
      case DashboardTimeRange.week:
        return 'WEEKLY';
      case DashboardTimeRange.month:
        return 'MONTHLY';
      case DashboardTimeRange.custom:
        return 'MONTHLY';
    }
  }
}
