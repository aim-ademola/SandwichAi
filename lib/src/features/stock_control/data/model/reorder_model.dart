import 'package:intl/intl.dart';

class ReorderSuggestion {
  final String branchStockId;
  final String itemId;
  final String itemName;
  final String category;
  final String branchId;
  final String branchName;
  final String supplierId;
  final String supplierName;
  final double currentStock;
  final double reorderLevel;
  final double suggestedQty;
  final double? suggestedQtyInPurchaseUnit;
  final ReorderPurchaseConfig? purchaseConfig;
  final double? estimatedUnitCost;
  final double? estimatedTotalCost;
  final int? daysUntilStockout;
  final String unit;
  final String urgency;
  final Map<String, dynamic> raw;

  const ReorderSuggestion({
    required this.branchStockId,
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.branchId,
    required this.branchName,
    required this.supplierId,
    required this.supplierName,
    required this.currentStock,
    required this.reorderLevel,
    required this.suggestedQty,
    required this.suggestedQtyInPurchaseUnit,
    required this.purchaseConfig,
    required this.estimatedUnitCost,
    required this.estimatedTotalCost,
    required this.daysUntilStockout,
    required this.unit,
    required this.urgency,
    required this.raw,
  });

  factory ReorderSuggestion.fromJson(Map<String, dynamic> json) {
    final item = _asMap(json['item']);
    final supplier = _asMap(json['supplier']);
    final branch = _asMap(json['branch']);
    final purchaseConfigMap = _asMap(json['purchaseConfig']);
    return ReorderSuggestion(
      branchStockId: _string(
        json['branchStockId'] ?? json['stockId'] ?? json['id'],
      ),
      itemId: _string(json['itemId'] ?? item['id']),
      itemName: _string(json['itemName'] ?? item['itemName'] ?? item['name']),
      category: _string(json['category'] ?? item['category']),
      branchId: _string(json['branchId'] ?? branch['id']),
      branchName: _string(json['branchName'] ?? branch['name']),
      supplierId: _string(json['supplierId'] ?? supplier['id']),
      supplierName: _string(
        json['supplierName'] ??
            supplier['businessName'] ??
            supplier['supplierName'] ??
            supplier['name'],
      ),
      currentStock: _double(json['currentStock']),
      reorderLevel: _double(json['reorderLevel']),
      suggestedQty: _double(
        json['suggestedOrderQty'] ??
            json['suggestedQty'] ??
            json['quantityNeeded'],
      ),
      suggestedQtyInPurchaseUnit: _nullableDouble(
        json['suggestedOrderInPurchaseUnit'] ??
            json['suggestedQtyInPurchaseUnit'],
      ),
      purchaseConfig: purchaseConfigMap.isEmpty
          ? null
          : ReorderPurchaseConfig.fromJson(purchaseConfigMap),
      estimatedUnitCost: _nullableDouble(json['estimatedUnitCost']),
      estimatedTotalCost: _nullableDouble(
        json['estimatedOrderValue'] ?? json['estimatedTotalCost'],
      ),
      daysUntilStockout: _nullableInt(json['daysUntilStockout']),
      unit: _string(
        json['unit'] ??
            json['uom'] ??
            json['unitOfMeasurement'] ??
            item['unit'] ??
            item['uom'] ??
            item['unitOfMeasurement'],
      ),
      urgency: _string(json['urgency'] ?? json['priority']),
      raw: json,
    );
  }

  String get currentStockDisplay => _quantityWithUnit(currentStock, unit);
  String get reorderLevelDisplay => _quantityWithUnit(reorderLevel, unit);
  String get suggestedQtyDisplay => _quantityWithUnit(suggestedQty, unit);
  String get purchaseQtyDisplay {
    final config = purchaseConfig;
    final qty = suggestedQtyInPurchaseUnit;
    if (config == null || qty == null) return '';
    return _quantityWithUnit(qty, config.displayUnit);
  }
}

class ReorderPurchaseConfig {
  final String unitName;
  final String abbreviation;
  final double conversionFactor;
  final Map<String, dynamic> raw;

  const ReorderPurchaseConfig({
    required this.unitName,
    required this.abbreviation,
    required this.conversionFactor,
    required this.raw,
  });

  factory ReorderPurchaseConfig.fromJson(Map<String, dynamic> json) {
    return ReorderPurchaseConfig(
      unitName: _string(json['unitName']),
      abbreviation: _string(json['abbreviation']),
      conversionFactor: _double(json['conversionFactor']),
      raw: json,
    );
  }

  String get displayUnit {
    if (abbreviation.trim().isNotEmpty) return abbreviation;
    return unitName;
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

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String _quantityWithUnit(double value, String unit) {
  final pattern = value % 1 == 0 ? '#,##0' : '#,##0.##';
  final formatted = NumberFormat(pattern).format(value);
  final trimmedUnit = unit.trim();
  return trimmedUnit.isEmpty ? formatted : '$formatted $trimmedUnit';
}
