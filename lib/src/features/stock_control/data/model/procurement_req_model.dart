class ProcurementRequestItem {
  final String itemId;
  final double currentStock;
  final double minLevel;
  final double qtyNeeded;
  final double unitCost;
  final String notes;

  const ProcurementRequestItem({
    required this.itemId,
    required this.currentStock,
    required this.minLevel,
    required this.qtyNeeded,
    required this.unitCost,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'itemId': itemId,
      'currentStock': currentStock,
      'minLevel': minLevel,
      'qtyNeeded': qtyNeeded,
      'unitCost': unitCost,
    };

    if (notes.trim().isNotEmpty) {
      json['notes'] = notes.trim();
    }

    return json;
  }

  factory ProcurementRequestItem.fromJson(Map<String, dynamic> json) {
    return ProcurementRequestItem(
      itemId: _string(
        json['itemId'] ?? json['stockItemId'] ?? json['item']?['id'],
      ),
      currentStock: _double(json['currentStock']),
      minLevel: _double(json['minLevel'] ?? json['minimumLevel']),
      qtyNeeded: _double(json['qtyNeeded'] ?? json['quantityNeeded']),
      unitCost: _double(json['unitCost']),
      notes: _string(json['notes']),
    );
  }
}

class CreateProcurementRequest {
  final String branchId;
  final String requestedBy;
  final String requestingDepartment;
  final String priority;
  final String urgencyLevel;
  final String urgencyReason;
  final String expectedDelivery;
  final String primaryCategory;
  final String? budgetId; // Optional field
  final String notes;
  final List<ProcurementRequestItem> items;

  const CreateProcurementRequest({
    required this.branchId,
    required this.requestedBy,
    required this.requestingDepartment,
    required this.priority,
    required this.urgencyLevel,
    required this.urgencyReason,
    required this.expectedDelivery,
    required this.primaryCategory,
    this.budgetId,
    required this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'branchId': branchId,
      'requestedBy': requestedBy,
      'requestingDepartment': requestingDepartment,
      'priority': priority,
      'urgencyLevel': urgencyLevel,
      'expectedDelivery': expectedDelivery,
      'primaryCategory': primaryCategory,
      'items': items.map((item) => item.toJson()).toList(),
    };

    if (urgencyReason.trim().isNotEmpty) {
      json['urgencyReason'] = urgencyReason.trim();
    }

    if (notes.trim().isNotEmpty) {
      json['notes'] = notes.trim();
    }

    if (budgetId != null && budgetId!.isNotEmpty) {
      json['budgetId'] = budgetId!;
    }

    return json;
  }

  factory CreateProcurementRequest.fromJson(Map<String, dynamic> json) {
    return CreateProcurementRequest(
      branchId: _string(json['branchId']),
      requestedBy: _string(json['requestedBy']),
      requestingDepartment: _string(json['requestingDepartment']),
      priority: _string(json['priority']),
      urgencyLevel: _string(json['urgencyLevel']),
      urgencyReason: _string(json['urgencyReason']),
      expectedDelivery: _string(json['expectedDelivery']),
      primaryCategory: _string(json['primaryCategory']),
      budgetId: _nullableString(json['budgetId']),
      notes: _string(json['notes']),
      items: _list(json['items'])
          .whereType<Map>()
          .map(
            (item) =>
                ProcurementRequestItem.fromJson(item.cast<String, dynamic>()),
          )
          .toList(),
    );
  }
}

class ProcurementRequestResponse {
  final String id;
  final String branchId;
  final String requestedBy;
  final String requestingDepartment;
  final String priority;
  final String urgencyLevel;
  final String urgencyReason;
  final String expectedDelivery;
  final String primaryCategory;
  final String? budgetId;
  final String notes;
  final String status;
  final List<ProcurementRequestItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProcurementRequestResponse({
    required this.id,
    required this.branchId,
    required this.requestedBy,
    required this.requestingDepartment,
    required this.priority,
    required this.urgencyLevel,
    required this.urgencyReason,
    required this.expectedDelivery,
    required this.primaryCategory,
    this.budgetId,
    required this.notes,
    required this.status,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProcurementRequestResponse.fromApi(dynamic data) {
    final root = _map(data);
    final payload = _map(root['data'] ?? root['request'] ?? root);
    return ProcurementRequestResponse.fromJson(payload);
  }

  factory ProcurementRequestResponse.fromJson(Map<String, dynamic> json) {
    final items = _list(
      json['items'] ??
          json['requestItems'] ??
          json['requestedItems'] ??
          json['procurementRequestItems'],
    );

    return ProcurementRequestResponse(
      id: _string(json['id']),
      branchId: _string(json['branchId']),
      requestedBy: _string(json['requestedBy']),
      requestingDepartment: _string(
        json['requestingDepartment'] ??
            json['department'] ??
            json['requestedByDepartment'],
      ),
      priority: _string(json['priority']),
      urgencyLevel: _string(json['urgencyLevel']),
      urgencyReason: _string(json['urgencyReason']),
      expectedDelivery: _string(json['expectedDelivery']),
      primaryCategory: _string(json['primaryCategory']),
      budgetId: _nullableString(json['budgetId']),
      notes: _string(json['notes']),
      status: _string(json['status']),
      items: items
          .whereType<Map>()
          .map(
            (item) =>
                ProcurementRequestItem.fromJson(item.cast<String, dynamic>()),
          )
          .toList(),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  throw const FormatException('Invalid procurement request response format');
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];

String _string(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

String? _nullableString(dynamic value) {
  final text = _string(value).trim();
  return text.isEmpty ? null : text;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(_string(value)) ?? 0;
}

DateTime _date(dynamic value) {
  return DateTime.tryParse(_string(value)) ?? DateTime.now();
}
