class ProcurementPerformanceResponse {
  final double totalSpend;
  final double averageDeliveryDays;
  final double onTimeDeliveryRate;
  final double qualityPassRate;
  final int totalOrders;
  final int completedOrders;
  final Map<String, dynamic> raw;

  const ProcurementPerformanceResponse({
    required this.totalSpend,
    required this.averageDeliveryDays,
    required this.onTimeDeliveryRate,
    required this.qualityPassRate,
    required this.totalOrders,
    required this.completedOrders,
    required this.raw,
  });

  factory ProcurementPerformanceResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']).isNotEmpty ? _asMap(json['data']) : json;
    return ProcurementPerformanceResponse(
      totalSpend: _double(data['totalSpend'] ?? data['totalAmount']),
      averageDeliveryDays: _double(data['averageDeliveryDays']),
      onTimeDeliveryRate: _double(data['onTimeDeliveryRate']),
      qualityPassRate: _double(data['qualityPassRate']),
      totalOrders: _int(data['totalOrders']),
      completedOrders: _int(data['completedOrders']),
      raw: json,
    );
  }
}

class ProcurementPerformanceRanking {
  final String supplierId;
  final String supplierName;
  final int rank;
  final double score;
  final double onTimeDeliveryRate;
  final double qualityPassRate;
  final double totalSpend;
  final Map<String, dynamic> raw;

  const ProcurementPerformanceRanking({
    required this.supplierId,
    required this.supplierName,
    required this.rank,
    required this.score,
    required this.onTimeDeliveryRate,
    required this.qualityPassRate,
    required this.totalSpend,
    required this.raw,
  });

  factory ProcurementPerformanceRanking.fromJson(Map<String, dynamic> json) {
    final supplier = _asMap(json['supplier']);
    return ProcurementPerformanceRanking(
      supplierId: _string(json['supplierId'] ?? supplier['id']),
      supplierName: _string(
        json['supplierName'] ?? supplier['businessName'] ?? supplier['name'],
      ),
      rank: _int(json['rank']),
      score: _double(json['score']),
      onTimeDeliveryRate: _double(json['onTimeDeliveryRate']),
      qualityPassRate: _double(json['qualityPassRate']),
      totalSpend: _double(json['totalSpend']),
      raw: json,
    );
  }
}

class ProcurementPerformanceRankingsResponse {
  final List<ProcurementPerformanceRanking> rankings;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> raw;

  const ProcurementPerformanceRankingsResponse({
    required this.rankings,
    required this.summary,
    required this.raw,
  });

  factory ProcurementPerformanceRankingsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final list = _extractList(json);
    return ProcurementPerformanceRankingsResponse(
      rankings: list
          .whereType<Map>()
          .map(
            (item) => ProcurementPerformanceRanking.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      summary: _asMap(json['summary']),
      raw: json,
    );
  }
}

List<dynamic> _extractList(Map<String, dynamic> json) {
  for (final key in const ['data', 'items', 'results', 'rankings']) {
    final value = json[key];
    if (value is List) return value;
  }
  final data = json['data'];
  if (data is Map) {
    for (final key in const ['items', 'results', 'rankings']) {
      final value = data[key];
      if (value is List) return value;
    }
  }
  return const [];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _string(dynamic value) => value?.toString() ?? '';

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
