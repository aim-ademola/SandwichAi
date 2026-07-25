import 'package:sandwich_ai/src/features/dashboard/data/model/dashboard_contract/dashboard_domain.dart';
import 'package:sandwich_ai/src/features/dashboard/data/model/dashboard_contract/dashboard_metric.dart';
import 'package:sandwich_ai/src/features/dashboard/data/model/dashboard_contract/dashboard_section.dart';

class DashboardResponse {
  final DashboardDomain domain;
  final List<DashboardMetric> metrics;
  final List<DashboardSection> sections;
  final DateTime? generatedAt;
  final Map<String, dynamic> rawData;

  const DashboardResponse({
    required this.domain,
    required this.metrics,
    required this.sections,
    this.generatedAt,
    required this.rawData,
  });

  factory DashboardResponse.fromJson(
    Map<String, dynamic> json, {
    required DashboardDomain domain,
  }) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final parsedMetrics = ((data['metrics'] as List?) ?? [])
        .whereType<Map>()
        .map((metric) => DashboardMetric.fromJson(metric.cast()))
        .toList();
    final metrics =
        domain == DashboardDomain.procurement && parsedMetrics.isEmpty
        ? _procurementOverviewMetrics(data)
        : parsedMetrics;

    return DashboardResponse(
      domain: domain,
      metrics: metrics,
      sections: ((data['sections'] as List?) ?? [])
          .whereType<Map>()
          .map((section) => DashboardSection.fromJson(section.cast()))
          .toList(),
      generatedAt: DateTime.tryParse(data['generatedAt']?.toString() ?? ''),
      rawData: data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domain': domain.apiValue,
      'metrics': metrics.map((metric) => metric.toJson()).toList(),
      'sections': sections.map((section) => section.toJson()).toList(),
      if (generatedAt != null) 'generatedAt': generatedAt!.toIso8601String(),
      'rawData': rawData,
    };
  }

  bool get isEmpty => metrics.isEmpty && sections.isEmpty;
}

List<DashboardMetric> _procurementOverviewMetrics(Map<String, dynamic> data) {
  final overview = _asMap(data['overview']);
  if (overview.isEmpty) return const [];

  final totalSpend = _asMap(overview['totalSpend']);
  final purchaseOrders = _asMap(overview['purchaseOrders']);
  final deliveriesCompleted = _asMap(overview['deliveriesCompleted']);

  return [
    DashboardMetric(
      key: 'totalSpend',
      label: 'Total Spend',
      value: _asNum(totalSpend['value']),
      unit: 'NGN',
      changePercent: _asNullableNum(totalSpend['percentageChange']),
      status: totalSpend['trend']?.toString(),
    ),
    DashboardMetric(
      key: 'purchaseOrders',
      label: 'Purchase Orders',
      value: _asNum(purchaseOrders['total']),
      previousValue: _asNullableNum(purchaseOrders['value']),
    ),
    DashboardMetric(
      key: 'deliveriesCompleted',
      label: 'Completed',
      value: _asNum(deliveriesCompleted['total']),
      changePercent: _asNullableNum(deliveriesCompleted['onTimeRate']),
    ),
  ];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

num? _asNullableNum(dynamic value) {
  if (value == null) return null;
  return _asNum(value);
}

num _asNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
