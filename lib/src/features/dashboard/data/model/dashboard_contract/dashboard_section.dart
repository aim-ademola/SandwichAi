import 'package:sandwich_ai/src/features/dashboard/data/model/dashboard_contract/dashboard_metric.dart';

class DashboardSection {
  final String key;
  final String title;
  final List<DashboardMetric> metrics;
  final List<Map<String, dynamic>> records;
  final Map<String, dynamic> rawData;

  const DashboardSection({
    required this.key,
    required this.title,
    required this.metrics,
    required this.records,
    required this.rawData,
  });

  factory DashboardSection.fromJson(Map<String, dynamic> json) {
    return DashboardSection(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      metrics: ((json['metrics'] as List?) ?? [])
          .whereType<Map>()
          .map((metric) => DashboardMetric.fromJson(metric.cast()))
          .toList(),
      records: ((json['records'] ?? json['items']) as List? ?? [])
          .whereType<Map>()
          .map((record) => record.cast<String, dynamic>())
          .toList(),
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'metrics': metrics.map((metric) => metric.toJson()).toList(),
      'records': records,
      'rawData': rawData,
    };
  }
}
