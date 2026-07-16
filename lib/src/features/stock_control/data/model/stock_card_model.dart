class StockExpiryItem {
  final String id;
  final String branchId;
  final String itemId;
  final String itemName;
  final String batchId;
  final String batchNumber;
  final double quantity;
  final String unit;
  final DateTime? expiryDate;
  final int daysUntilExpiry;
  final String status;
  final Map<String, dynamic> raw;

  const StockExpiryItem({
    required this.id,
    required this.branchId,
    required this.itemId,
    required this.itemName,
    required this.batchId,
    required this.batchNumber,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.daysUntilExpiry,
    required this.status,
    required this.raw,
  });

  factory StockExpiryItem.fromJson(Map<String, dynamic> json) {
    final item = _asMap(json['item']);
    return StockExpiryItem(
      id: _string(json['id']),
      branchId: _string(json['branchId']),
      itemId: _string(json['itemId'] ?? item['id']),
      itemName: _string(json['itemName'] ?? item['itemName'] ?? item['name']),
      batchId: _string(json['batchId']),
      batchNumber: _string(json['batchNumber'] ?? json['batchNo']),
      quantity: _double(json['quantity'] ?? json['currentStock']),
      unit: _string(json['unit'] ?? item['unit']),
      expiryDate: _date(json['expiryDate']),
      daysUntilExpiry: _int(json['daysUntilExpiry']),
      status: _string(json['status']),
      raw: json,
    );
  }
}

class StockExpiryReport {
  final String message;
  final List<StockExpiryItem> items;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> raw;

  const StockExpiryReport({
    required this.message,
    required this.items,
    required this.summary,
    required this.raw,
  });

  factory StockExpiryReport.fromJson(Map<String, dynamic> json) {
    final list = _extractList(json);
    return StockExpiryReport(
      message: _string(json['message']),
      items: list
          .whereType<Map>()
          .map(
            (item) => StockExpiryItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      summary: _asMap(json['summary']),
      raw: json,
    );
  }
}

class StockExpirySummary {
  final int expired;
  final int expiringSoon;
  final int expiringThisWeek;
  final int expiringThisMonth;
  final Map<String, dynamic> raw;

  const StockExpirySummary({
    required this.expired,
    required this.expiringSoon,
    required this.expiringThisWeek,
    required this.expiringThisMonth,
    required this.raw,
  });

  factory StockExpirySummary.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']).isNotEmpty ? _asMap(json['data']) : json;
    return StockExpirySummary(
      expired: _int(data['expired']),
      expiringSoon: _int(data['expiringSoon']),
      expiringThisWeek: _int(data['expiringThisWeek']),
      expiringThisMonth: _int(data['expiringThisMonth']),
      raw: json,
    );
  }
}

class StockBatch {
  final String id;
  final String batchNumber;
  final String branchId;
  final String itemId;
  final double quantity;
  final String unit;
  final DateTime? expiryDate;
  final String status;
  final Map<String, dynamic> raw;

  const StockBatch({
    required this.id,
    required this.batchNumber,
    required this.branchId,
    required this.itemId,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.status,
    required this.raw,
  });

  factory StockBatch.fromJson(Map<String, dynamic> json) => StockBatch(
    id: _string(json['id'] ?? json['batchId']),
    batchNumber: _string(json['batchNumber'] ?? json['batchNo']),
    branchId: _string(json['branchId']),
    itemId: _string(json['itemId']),
    quantity: _double(json['quantity'] ?? json['currentStock']),
    unit: _string(json['unit']),
    expiryDate: _date(json['expiryDate']),
    status: _string(json['status']),
    raw: json,
  );
}

class StockBatchUpdateRequest {
  final String? batchNumber;
  final double? quantity;
  final DateTime? expiryDate;
  final String? status;
  final String? notes;

  const StockBatchUpdateRequest({
    this.batchNumber,
    this.quantity,
    this.expiryDate,
    this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    if (batchNumber != null) 'batchNumber': batchNumber,
    if (quantity != null) 'quantity': quantity,
    if (expiryDate != null) 'expiryDate': _formatDate(expiryDate!),
    if (status != null) 'status': status,
    if (notes != null) 'notes': notes,
  };
}

class StockMovementTrend {
  final DateTime? date;
  final String itemId;
  final String itemName;
  final double inQty;
  final double outQty;
  final double netQty;
  final Map<String, dynamic> raw;

  const StockMovementTrend({
    required this.date,
    required this.itemId,
    required this.itemName,
    required this.inQty,
    required this.outQty,
    required this.netQty,
    required this.raw,
  });

  factory StockMovementTrend.fromJson(Map<String, dynamic> json) =>
      StockMovementTrend(
        date: _date(json['date'] ?? json['movementDate']),
        itemId: _string(json['itemId']),
        itemName: _string(json['itemName']),
        inQty: _double(json['inQty'] ?? json['stockIn']),
        outQty: _double(json['outQty'] ?? json['stockOut']),
        netQty: _double(json['netQty'] ?? json['netMovement']),
        raw: json,
      );
}

class StockMovementTrendsResponse {
  final List<StockMovementTrend> trends;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> raw;

  const StockMovementTrendsResponse({
    required this.trends,
    required this.summary,
    required this.raw,
  });

  factory StockMovementTrendsResponse.fromJson(Map<String, dynamic> json) {
    final list = _extractList(json);
    return StockMovementTrendsResponse(
      trends: list
          .whereType<Map>()
          .map(
            (item) =>
                StockMovementTrend.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      summary: _asMap(json['summary']),
      raw: json,
    );
  }
}

List<dynamic> _extractList(Map<String, dynamic> json) {
  for (final key in const ['data', 'items', 'results', 'batches', 'trends']) {
    final value = json[key];
    if (value is List) return value;
  }
  final data = json['data'];
  if (data is Map) {
    for (final key in const ['items', 'results', 'batches', 'trends']) {
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

DateTime? _date(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
