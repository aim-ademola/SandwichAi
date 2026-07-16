class ReorderSuggestion {
  final String branchStockId;
  final String itemId;
  final String itemName;
  final String branchId;
  final double currentStock;
  final double reorderLevel;
  final double suggestedQty;
  final String urgency;
  final Map<String, dynamic> raw;

  const ReorderSuggestion({
    required this.branchStockId,
    required this.itemId,
    required this.itemName,
    required this.branchId,
    required this.currentStock,
    required this.reorderLevel,
    required this.suggestedQty,
    required this.urgency,
    required this.raw,
  });

  factory ReorderSuggestion.fromJson(Map<String, dynamic> json) {
    final item = _asMap(json['item']);
    return ReorderSuggestion(
      branchStockId: _string(
        json['branchStockId'] ?? json['stockId'] ?? json['id'],
      ),
      itemId: _string(json['itemId'] ?? item['id']),
      itemName: _string(json['itemName'] ?? item['itemName'] ?? item['name']),
      branchId: _string(json['branchId']),
      currentStock: _double(json['currentStock']),
      reorderLevel: _double(json['reorderLevel']),
      suggestedQty: _double(json['suggestedQty'] ?? json['quantityNeeded']),
      urgency: _string(json['urgency'] ?? json['priority']),
      raw: json,
    );
  }
}

class ReorderSuggestionsResponse {
  final List<ReorderSuggestion> suggestions;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> raw;

  const ReorderSuggestionsResponse({
    required this.suggestions,
    required this.summary,
    required this.raw,
  });

  factory ReorderSuggestionsResponse.fromJson(Map<String, dynamic> json) {
    final list = _extractList(json);
    return ReorderSuggestionsResponse(
      suggestions: list
          .whereType<Map>()
          .map(
            (item) =>
                ReorderSuggestion.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      summary: _asMap(json['summary']),
      raw: json,
    );
  }
}

class ReorderReportResponse {
  final String branchId;
  final List<ReorderSuggestion> items;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> raw;

  const ReorderReportResponse({
    required this.branchId,
    required this.items,
    required this.summary,
    required this.raw,
  });

  factory ReorderReportResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']).isNotEmpty ? _asMap(json['data']) : json;
    final list = _extractList(data);
    return ReorderReportResponse(
      branchId: _string(data['branchId']),
      items: list
          .whereType<Map>()
          .map(
            (item) =>
                ReorderSuggestion.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      summary: _asMap(data['summary']),
      raw: json,
    );
  }
}

class ReorderAcknowledgeResponse {
  final bool success;
  final String message;
  final Map<String, dynamic> raw;

  const ReorderAcknowledgeResponse({
    required this.success,
    required this.message,
    required this.raw,
  });

  factory ReorderAcknowledgeResponse.fromJson(Map<String, dynamic> json) =>
      ReorderAcknowledgeResponse(
        success: json['success'] == true,
        message: _string(json['message']),
        raw: json,
      );
}

List<dynamic> _extractList(Map<String, dynamic> json) {
  for (final key in const ['data', 'items', 'results', 'suggestions']) {
    final value = json[key];
    if (value is List) return value;
  }
  final data = json['data'];
  if (data is Map) {
    for (final key in const ['items', 'results', 'suggestions']) {
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
