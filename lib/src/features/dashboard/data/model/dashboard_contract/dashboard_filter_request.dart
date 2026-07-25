import 'package:sandwich_ai/src/features/dashboard/data/model/dashboard_contract/dashboard_domain.dart';
import 'package:sandwich_ai/src/features/dashboard/data/model/dashboard_contract/dashboard_time_range.dart';

class DashboardFilterRequest {
  final DashboardDomain domain;
  final String organizationId;
  final String? branchId;
  final DashboardTimeRange range;
  final DateTime? startDate;
  final DateTime? endDate;

  const DashboardFilterRequest({
    required this.domain,
    required this.organizationId,
    this.branchId,
    this.range = DashboardTimeRange.today,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toQueryParameters() {
    if (domain == DashboardDomain.procurement) {
      return {
        'organizationId': organizationId,
        if (branchId != null && branchId!.isNotEmpty) 'branchId': branchId,
        if (range != DashboardTimeRange.custom)
          'timePeriod': range.procurementValue,
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
      };
    }

    return {
      'organizationId': organizationId,
      if (branchId != null && branchId!.isNotEmpty) 'branchId': branchId,
      'range': range.apiValue,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
    };
  }
}
