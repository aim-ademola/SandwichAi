import 'package:intl/intl.dart';

class BranchStockDetails {
  final String id;
  final String itemId;
  final String branchId;
  final String organizationId;
  final String currentStock;
  final String reorderLevel;
  final String maxLevel;
  final String unitCost;
  final String totalValue;
  final String status;
  final DateTime? expiryDate;
  final DateTime lastUpdated;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ItemInfo item;
  final BranchInfo branch;

  BranchStockDetails({
    required this.id,
    required this.itemId,
    required this.branchId,
    required this.organizationId,
    required this.currentStock,
    required this.reorderLevel,
    required this.maxLevel,
    required this.unitCost,
    required this.totalValue,
    required this.status,
    this.expiryDate,
    required this.lastUpdated,
    required this.createdAt,
    required this.updatedAt,
    required this.item,
    required this.branch,
  });

  factory BranchStockDetails.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    return BranchStockDetails(
      id: data['id'] as String,
      itemId: data['itemId'] as String,
      branchId: data['branchId'] as String,
      organizationId: data['organizationId'] as String,
      currentStock: _stringValue(data['currentStock']),
      reorderLevel: _stringValue(data['reorderLevel']),
      maxLevel: _stringValue(data['maxLevel']),
      unitCost: _stringValue(data['unitCost']),
      totalValue: _stringValue(data['totalValue']),
      status: _stringValue(data['status'], fallback: 'UNKNOWN'),
      expiryDate: data['expiryDate'] != null
          ? DateTime.parse(data['expiryDate'] as String)
          : null,
      lastUpdated: DateTime.parse(data['lastUpdated'] as String),
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      item: ItemInfo.fromJson(data['item'] as Map<String, dynamic>),
      branch: BranchInfo.fromJson(data['branch'] as Map<String, dynamic>),
    );
  }

  // Calculated properties
  double get currentStockValue => double.tryParse(currentStock) ?? 0.0;
  double get reorderLevelValue => double.tryParse(reorderLevel) ?? 0.0;
  double get maxLevelValue => double.tryParse(maxLevel) ?? 0.0;
  double get unitCostValue => double.tryParse(unitCost) ?? 0.0;
  double get totalValueValue => double.tryParse(totalValue) ?? 0.0;

  // Stock percentage relative to max level
  double get stockPercentage {
    if (maxLevelValue == 0) return 0.0;
    return (currentStockValue / maxLevelValue) * 100;
  }

  // Check if stock is below reorder level
  bool get isBelowReorderLevel => currentStockValue <= reorderLevelValue;

  // Check if stock is critical (below 10% of max level)
  bool get isCritical => stockPercentage <= 10;

  // Check if expiring soon (within 7 days)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry >= 0;
  }

  // Formatted values
  String get formattedUnitCost {
    final formatter = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    return formatter.format(unitCostValue);
  }

  String get formattedTotalValue {
    final formatter = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    return formatter.format(totalValueValue);
  }

  String get formattedLastUpdated {
    final formatter = DateFormat('MMM dd, yyyy - hh:mm a');
    return formatter.format(lastUpdated);
  }

  String? get formattedExpiryDate {
    if (expiryDate == null) return null;
    final formatter = DateFormat('MMM dd, yyyy');
    return formatter.format(expiryDate!);
  }
}

class ItemInfo {
  final String id;
  final String itemName;
  final String category;
  final String unit;
  final String? description;
  final String sku;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemInfo({
    required this.id,
    required this.itemName,
    required this.category,
    required this.unit,
    this.description,
    required this.sku,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemInfo.fromJson(Map<String, dynamic> json) {
    return ItemInfo(
      id: json['id'] as String,
      itemName: _stringValue(json['itemName']),
      category: _stringValue(json['category']),
      unit: _stringValue(json['unit']),
      description: _nullableString(json['description']),
      sku: _stringValue(json['sku']),
      organizationId: json['organizationId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}

String _stringValue(dynamic value, {String fallback = '0'}) {
  final text = _nullableString(value);
  return text ?? fallback;
}

class BranchInfo {
  final String id;
  final String name;
  final String branchCode;

  BranchInfo({required this.id, required this.name, required this.branchCode});

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      id: json['id'] as String,
      name: _stringValue(json['name'], fallback: ''),
      branchCode: _stringValue(json['branch_code'], fallback: ''),
    );
  }
}
