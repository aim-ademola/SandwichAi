class ProcurementRequestItem {
  final String itemId;
  final double currentStock;
  final double minLevel;
  final int qtyNeeded;
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
    return {
      'itemId': itemId,
      'currentStock': currentStock,
      'minLevel': minLevel,
      'qtyNeeded': qtyNeeded,
      'unitCost': unitCost,
      'notes': notes,
    };
  }

  factory ProcurementRequestItem.fromJson(Map<String, dynamic> json) {
    return ProcurementRequestItem(
      itemId: json['itemId'] as String,
      currentStock: (json['currentStock'] as num).toDouble(),
      minLevel: (json['minLevel'] as num).toDouble(),
      qtyNeeded: json['qtyNeeded'] as int,
      unitCost: (json['unitCost'] as num).toDouble(),
      notes: json['notes'] as String? ?? '',
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
    final json = {
      'branchId': branchId,
      'requestedBy': requestedBy,
      'requestingDepartment': requestingDepartment,
      'priority': priority,
      'urgencyLevel': urgencyLevel,
      'urgencyReason': urgencyReason,
      'expectedDelivery': expectedDelivery,
      'primaryCategory': primaryCategory,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
    };

    // Only include budgetId if it's not null
    if (budgetId != null && budgetId!.isNotEmpty) {
      json['budgetId'] = budgetId!;
    }

    return json;
  }

  factory CreateProcurementRequest.fromJson(Map<String, dynamic> json) {
    return CreateProcurementRequest(
      branchId: json['branchId'] as String,
      requestedBy: json['requestedBy'] as String,
      requestingDepartment: json['requestingDepartment'] as String,
      priority: json['priority'] as String,
      urgencyLevel: json['urgencyLevel'] as String,
      urgencyReason: json['urgencyReason'] as String,
      expectedDelivery: json['expectedDelivery'] as String,
      primaryCategory: json['primaryCategory'] as String,
      budgetId: json['budgetId'] as String?,
      notes: json['notes'] as String? ?? '',
      items: (json['items'] as List)
          .map((item) => ProcurementRequestItem.fromJson(item))
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

  factory ProcurementRequestResponse.fromJson(Map<String, dynamic> json) {
    return ProcurementRequestResponse(
      id: json['id'] as String,
      branchId: json['branchId'] as String,
      requestedBy: json['requestedBy'] as String,
      requestingDepartment: json['requestingDepartment'] as String,
      priority: json['priority'] as String,
      urgencyLevel: json['urgencyLevel'] as String,
      urgencyReason: json['urgencyReason'] as String,
      expectedDelivery: json['expectedDelivery'] as String,
      primaryCategory: json['primaryCategory'] as String,
      budgetId: json['budgetId'] as String?,
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String,
      items: (json['items'] as List)
          .map((item) => ProcurementRequestItem.fromJson(item))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
