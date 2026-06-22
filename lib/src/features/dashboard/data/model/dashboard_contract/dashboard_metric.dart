class DashboardMetric {
  final String key;
  final String label;
  final num value;
  final String? unit;
  final num? previousValue;
  final num? changePercent;
  final String? status;

  const DashboardMetric({
    required this.key,
    required this.label,
    required this.value,
    this.unit,
    this.previousValue,
    this.changePercent,
    this.status,
  });

  factory DashboardMetric.fromJson(Map<String, dynamic> json) {
    return DashboardMetric(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      value: _asNum(json['value']),
      unit: json['unit']?.toString(),
      previousValue: json['previousValue'] == null
          ? null
          : _asNum(json['previousValue']),
      changePercent: json['changePercent'] == null
          ? null
          : _asNum(json['changePercent']),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'value': value,
      if (unit != null) 'unit': unit,
      if (previousValue != null) 'previousValue': previousValue,
      if (changePercent != null) 'changePercent': changePercent,
      if (status != null) 'status': status,
    };
  }
}

num _asNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
