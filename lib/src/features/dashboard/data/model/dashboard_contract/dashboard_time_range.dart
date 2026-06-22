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
}
