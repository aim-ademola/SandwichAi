// data/model/waste_logs_model.dart

class WasteLogRequest {
  final String branchId;
  final String itemName;
  final String itemId;
  final int quantity;
  final String unit;
  final String reason;
  final double valueLost;
  final String notes;
  final String recordedBy;

  WasteLogRequest({
    required this.branchId,
    required this.itemName,
    required this.itemId,
    required this.quantity,
    required this.unit,
    required this.reason,
    required this.valueLost,
    required this.notes,
    required this.recordedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'itemName': itemName,
      'itemId': itemId,
      'quantity': quantity,
      'unit': unit,
      'reason': reason,
      'valueLost': valueLost,
      'notes': notes,
      'recordedBy': recordedBy,
    };
  }
}

enum WasteReason {
  SPOILAGE,
  SHRINKAGE,
  THEFT,
  OVERUSE,
  POOR_STORAGE,
  EXPIRED,
  DAMAGED,
  OTHERS,
}

extension WasteReasonExtension on WasteReason {
  String get displayName {
    switch (this) {
      case WasteReason.SPOILAGE:
        return 'Spoilage';
      case WasteReason.SHRINKAGE:
        return 'Shrinkage';
      case WasteReason.THEFT:
        return 'Theft';
      case WasteReason.OVERUSE:
        return 'Overuse';
      case WasteReason.POOR_STORAGE:
        return 'Poor Storage';
      case WasteReason.EXPIRED:
        return 'Expired';
      case WasteReason.DAMAGED:
        return 'Damaged';
      case WasteReason.OTHERS:
        return 'Others';
    }
  }

  String get value => name;
}

class BranchInfo {
  final String id;
  final String name;
  final String branchCode;
  final String address;
  final String city;
  final String state;
  final String country;

  BranchInfo({
    required this.id,
    required this.name,
    required this.branchCode,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
  });

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      branchCode: json['branch_code'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

class ItemInfo {
  final String id;
  final String itemName;
  final String category;
  final String unit;
  final String description;
  final String sku;

  ItemInfo({
    required this.id,
    required this.itemName,
    required this.category,
    required this.unit,
    required this.description,
    required this.sku,
  });

  factory ItemInfo.fromJson(Map<String, dynamic> json) {
    return ItemInfo(
      id: json['id'] ?? '',
      itemName: json['itemName'] ?? '',
      category: json['category'] ?? '',
      unit: json['unit'] ?? '',
      description: json['description'] ?? '',
      sku: json['sku'] ?? '',
    );
  }
}

class WasteLogItem {
  final String id;
  final String branchId;
  final String organizationId;
  final DateTime date;
  final String itemName;
  final String itemId;
  final String quantity;
  final String unit;
  final String reason;
  final String valueLost;
  final String notes;
  final String recordedBy;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final BranchInfo branch;
  final ItemInfo item;

  WasteLogItem({
    required this.id,
    required this.branchId,
    required this.organizationId,
    required this.date,
    required this.itemName,
    required this.itemId,
    required this.quantity,
    required this.unit,
    required this.reason,
    required this.valueLost,
    required this.notes,
    required this.recordedBy,
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.branch,
    required this.item,
  });

  factory WasteLogItem.fromJson(Map<String, dynamic> json) {
    return WasteLogItem(
      id: json['id'] ?? '',
      branchId: json['branchId'] ?? '',
      organizationId: json['organizationId'] ?? '',
      date: DateTime.parse(json['date']),
      itemName: json['itemName'] ?? '',
      itemId: json['itemId'] ?? '',
      quantity: json['quantity']?.toString() ?? '0',
      unit: json['unit'] ?? '',
      reason: json['reason'] ?? '',
      valueLost: json['valueLost']?.toString() ?? '0',
      notes: json['notes'] ?? '',
      recordedBy: json['recordedBy'] ?? '',
      verifiedBy: json['verifiedBy'],
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      branch: BranchInfo.fromJson(json['branch']),
      item: ItemInfo.fromJson(json['item']),
    );
  }

  bool get isVerified => verifiedBy != null;

  double get valueLostAsDouble => double.tryParse(valueLost) ?? 0.0;

  int get quantityAsInt => int.tryParse(quantity) ?? 0;
}

class WasteLogsResponse {
  final List<WasteLogItem> logs;
  final int totalCount;
  final double totalValueLost;

  WasteLogsResponse({
    required this.logs,
    required this.totalCount,
    required this.totalValueLost,
  });

  factory WasteLogsResponse.fromJson(List<dynamic> json) {
    final logs = json
        .map((e) => WasteLogItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final totalValueLost = logs.fold<double>(
      0.0,
      (sum, item) => sum + item.valueLostAsDouble,
    );

    return WasteLogsResponse(
      logs: logs,
      totalCount: logs.length,
      totalValueLost: totalValueLost,
    );
  }

  bool get isValid => logs.isNotEmpty;
}
