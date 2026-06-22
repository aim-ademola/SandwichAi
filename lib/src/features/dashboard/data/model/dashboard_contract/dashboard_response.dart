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

    return DashboardResponse(
      domain: domain,
      metrics: ((data['metrics'] as List?) ?? [])
          .whereType<Map>()
          .map((metric) => DashboardMetric.fromJson(metric.cast()))
          .toList(),
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
