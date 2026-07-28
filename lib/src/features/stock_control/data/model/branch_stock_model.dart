class BranchStockResponse {
  final String message;
  final List<BranchStockItem> data;
  final StockSummary summary;

  BranchStockResponse({
    required this.message,
    required this.data,
    required this.summary,
  });

  factory BranchStockResponse.fromJson(Map<String, dynamic> json) {
    return BranchStockResponse(
      message: json['message'] ?? '',
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => BranchStockItem.fromJson(item))
              .toList() ??
          [],
      summary: StockSummary.fromJson(json['summary'] ?? {}),
    );
  }

  bool get isValid => data.isNotEmpty;

  // Get unique categories from items
  List<String> get categories {
    final categorySet = <String>{};
    for (var item in data) {
      if (item.item.category.isNotEmpty) {
        categorySet.add(item.item.category);
      }
    }
    return categorySet.toList()..sort();
  }

  // Get items by category
  List<BranchStockItem> getItemsByCategory(String category) {
    if (category == 'All') return data;
    return data.where((item) => item.item.category == category).toList();
  }

  // Get items by status
  List<BranchStockItem> getItemsByStatus(ItemStatus status) {
    return data.where((item) => item.itemStatus == status).toList();
  }

  // Get all items with any alert status
  List<BranchStockItem> get itemsWithAlerts {
    return data.where((item) => item.itemStatus != null).toList();
  }
}

class BranchStockItem {
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
  final String? expiryDate;
  final String lastUpdated;
  final String createdAt;
  final String updatedAt;
  final bool allowNegativeStock;
  final bool isLocked;
  final String? lockReason;
  final String? lockedAt;
  final String? lockedBy;
  final String? lockedUntil;
  final String? nearExpiryAlertSentAt;
  final String? negativeStockNote;
  final double reservedStock;
  final int batchCount;
  final int expiringBatchCount;
  final String? nearestExpiryDate;
  final String storageLocation;
  final List<StockBatch> batches;
  final ItemDetails item;

  BranchStockItem({
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
    this.allowNegativeStock = false,
    this.isLocked = false,
    this.lockReason,
    this.lockedAt,
    this.lockedBy,
    this.lockedUntil,
    this.nearExpiryAlertSentAt,
    this.negativeStockNote,
    this.reservedStock = 0,
    this.batchCount = 0,
    this.expiringBatchCount = 0,
    this.nearestExpiryDate,
    this.storageLocation = '',
    this.batches = const [],
    required this.item,
  });

  factory BranchStockItem.fromJson(Map<String, dynamic> json) {
    final batches =
        (json['batches'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(StockBatch.fromJson)
            .toList() ??
        [];

    return BranchStockItem(
      id: json['id'] ?? '',
      itemId: json['itemId'] ?? '',
      branchId: json['branchId'] ?? '',
      organizationId: json['organizationId'] ?? '',
      currentStock: json['currentStock']?.toString() ?? '0',
      reorderLevel: json['reorderLevel']?.toString() ?? '0',
      maxLevel: json['maxLevel']?.toString() ?? '0',
      unitCost: json['unitCost']?.toString() ?? '0',
      totalValue: json['totalValue']?.toString() ?? '0',
      status: json['status'] ?? '',
      expiryDate: json['expiryDate'],
      lastUpdated: json['lastUpdated'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      allowNegativeStock: json['allowNegativeStock'] == true,
      isLocked: json['isLocked'] == true,
      lockReason: json['lockReason'],
      lockedAt: json['lockedAt'],
      lockedBy: json['lockedBy'],
      lockedUntil: json['lockedUntil'],
      nearExpiryAlertSentAt: json['nearExpiryAlertSentAt'],
      negativeStockNote: json['negativeStockNote'],
      reservedStock: _toDouble(json['reservedStock']),
      batchCount: _toInt(json['batchCount'], fallback: batches.length),
      expiringBatchCount: _toInt(json['expiringBatchCount']),
      nearestExpiryDate: json['nearestExpiryDate'],
      storageLocation: _firstString(json, const [
        'storage',
        'storageLocation',
        'storageType',
        'location',
        'storageName',
        'storageCondition',
        'storageConditions',
      ]),
      batches: batches,
      item: ItemDetails.fromJson(json['item'] ?? {}),
    );
  }

  // Helper to get current stock as double
  double get currentStockValue => double.tryParse(currentStock) ?? 0;

  // Helper to get reorder level as double
  double get reorderLevelValue => double.tryParse(reorderLevel) ?? 0;

  // Helper to get max level as double
  double get maxLevelValue => double.tryParse(maxLevel) ?? 0;

  // Helper to get unit cost as double
  double get unitCostValue => double.tryParse(unitCost) ?? 0;

  // Helper to get total value as double
  double get totalValueValue => double.tryParse(totalValue) ?? 0;

  // Check if stock is at or below reorder level
  bool get isAtOrBelowReorder {
    if (reorderLevelValue == 0) return false;
    return currentStockValue <= reorderLevelValue;
  }

  // Check if stock is near reorder level (within 20% above)
  bool get isNearReorder {
    if (reorderLevelValue == 0) return false;
    final threshold = reorderLevelValue * 1.2;
    return currentStockValue <= threshold &&
        currentStockValue > reorderLevelValue;
  }

  // Check if out of stock
  bool get isOutOfStock => currentStockValue == 0;

  // Calculate stock percentage relative to max level
  double get stockPercentage {
    if (maxLevelValue == 0) return 0;
    return (currentStockValue / maxLevelValue * 100).clamp(0, 100);
  }

  // Calculate stock percentage relative to reorder level
  double get stockToReorderPercentage {
    if (reorderLevelValue == 0) return 100;
    return (currentStockValue / reorderLevelValue * 100).clamp(0, 200);
  }

  // Calculate days until expiry
  int get daysUntilExpiry {
    final effectiveExpiryDate = batchExpiryDate;
    if (effectiveExpiryDate == null) return 999;
    try {
      final expiry = DateTime.parse(effectiveExpiryDate);
      final now = DateTime.now();
      return expiry.difference(now).inDays;
    } catch (e) {
      return 999;
    }
  }

  String? get batchExpiryDate {
    if (nearestExpiryDate != null) return nearestExpiryDate;

    final batchExpiryDates =
        batches
            .map((batch) => batch.expiryDate)
            .whereType<String>()
            .map(DateTime.tryParse)
            .whereType<DateTime>()
            .toList()
          ..sort();

    if (batchExpiryDates.isEmpty) return null;
    return batchExpiryDates.first.toIso8601String();
  }

  // Check if expired
  bool get isExpired {
    if (batchExpiryDate == null) return false;
    return daysUntilExpiry <= 0;
  }

  // Check if expiring soon (within 30 days)
  bool get isExpiringSoon {
    if (batchExpiryDate == null) return false;
    return daysUntilExpiry > 0 && daysUntilExpiry <= 30;
  }

  // Convert status string to ItemStatus enum with priority logic
  ItemStatus? get itemStatus {
    // Priority: expired > out of stock > low stock > near reorder > use soon

    // Check if expired (highest priority)
    final normalizedStatus = status.toUpperCase();

    if (isExpired || normalizedStatus == 'EXPIRED') {
      return ItemStatus.expired;
    }

    // Check if out of stock
    if (isOutOfStock || normalizedStatus == 'OUT_OF_STOCK') {
      return ItemStatus.outOfStock;
    }

    // Check if at or below reorder level
    if (isAtOrBelowReorder || normalizedStatus == 'LOW_STOCK') {
      return ItemStatus.lowStock;
    }

    // Check if near reorder level
    if (isNearReorder) {
      return ItemStatus.nearReorder;
    }

    // Check if expiring soon
    if (isExpiringSoon) {
      return ItemStatus.useSoon;
    }

    return null;
  }

  // Use backend storage wording first, then the backend category as display text.
  String get storage {
    if (storageLocation.trim().isNotEmpty) return storageLocation.trim();
    if (item.storageLocation.trim().isNotEmpty) {
      return item.storageLocation.trim();
    }
    return item.category.trim();
  }

  // Convert to CatalogItem format for UI
  CatalogItem toCatalogItem() {
    return CatalogItem(
      id: id,
      itemId: itemId,
      name: item.itemName,
      quantity: currentStockValue,
      unit: item.unit,
      expiryDays: daysUntilExpiry,
      storage: storage,
      batches: batchCount,
      category: item.category,
      status: itemStatus,
      reorderLevel: reorderLevelValue,
      maxLevel: maxLevelValue,
      isNearReorder: isNearReorder,
      unitCost: unitCostValue,
      totalValue: totalValueValue,
      stockPercentage: stockToReorderPercentage,
      sku: item.sku,
      description: item.description,
      isLocked: isLocked,
      lockReason: lockReason,
      allowNegativeStock: allowNegativeStock,
      reservedStock: reservedStock,
      expiringBatchCount: expiringBatchCount,
      nearestExpiryDate: batchExpiryDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'branchId': branchId,
      'organizationId': organizationId,
      'currentStock': currentStock,
      'reorderLevel': reorderLevel,
      'maxLevel': maxLevel,
      'unitCost': unitCost,
      'totalValue': totalValue,
      'status': status,
      'expiryDate': expiryDate,
      'lastUpdated': lastUpdated,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'allowNegativeStock': allowNegativeStock,
      'isLocked': isLocked,
      'lockReason': lockReason,
      'lockedAt': lockedAt,
      'lockedBy': lockedBy,
      'lockedUntil': lockedUntil,
      'nearExpiryAlertSentAt': nearExpiryAlertSentAt,
      'negativeStockNote': negativeStockNote,
      'reservedStock': reservedStock,
      'batchCount': batchCount,
      'expiringBatchCount': expiringBatchCount,
      'nearestExpiryDate': nearestExpiryDate,
      'storageLocation': storageLocation,
      'batches': batches.map((batch) => batch.toJson()).toList(),
      'item': item.toJson(),
    };
  }
}

class StockBatch {
  final String id;
  final String organizationId;
  final String branchId;
  final String itemId;
  final String grnId;
  final String grnItemId;
  final String batchCode;
  final double quantity;
  final double remainingQty;
  final double? unitCost;
  final String? expiryDate;
  final String receivedAt;
  final String receivedBy;
  final String status;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  StockBatch({
    required this.id,
    required this.organizationId,
    required this.branchId,
    required this.itemId,
    required this.grnId,
    required this.grnItemId,
    required this.batchCode,
    required this.quantity,
    required this.remainingQty,
    this.unitCost,
    this.expiryDate,
    required this.receivedAt,
    required this.receivedBy,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StockBatch.fromJson(Map<String, dynamic> json) {
    return StockBatch(
      id: json['id'] ?? '',
      organizationId: json['organizationId'] ?? '',
      branchId: json['branchId'] ?? '',
      itemId: json['itemId'] ?? '',
      grnId: json['grnId'] ?? '',
      grnItemId: json['grnItemId'] ?? '',
      batchCode: json['batchCode'] ?? '',
      quantity: _toDouble(json['quantity']),
      remainingQty: _toDouble(json['remainingQty']),
      unitCost: json['unitCost'] == null ? null : _toDouble(json['unitCost']),
      expiryDate: json['expiryDate'],
      receivedAt: json['receivedAt'] ?? '',
      receivedBy: json['receivedBy'] ?? '',
      status: json['status'] ?? '',
      notes: json['notes'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'branchId': branchId,
      'itemId': itemId,
      'grnId': grnId,
      'grnItemId': grnItemId,
      'batchCode': batchCode,
      'quantity': quantity,
      'remainingQty': remainingQty,
      'unitCost': unitCost,
      'expiryDate': expiryDate,
      'receivedAt': receivedAt,
      'receivedBy': receivedBy,
      'status': status,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class ItemDetails {
  final String id;
  final String itemName;
  final String category;
  final String unit;
  final String description;
  final String sku;
  final String storageLocation;
  final String organizationId;
  final String createdAt;
  final String updatedAt;

  ItemDetails({
    required this.id,
    required this.itemName,
    required this.category,
    required this.unit,
    required this.description,
    required this.sku,
    this.storageLocation = '',
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemDetails.fromJson(Map<String, dynamic> json) {
    return ItemDetails(
      id: json['id'] ?? '',
      itemName: json['itemName'] ?? '',
      category: json['category'] ?? '',
      unit: json['unit'] ?? '',
      description: json['description'] ?? '',
      sku: json['sku'] ?? '',
      storageLocation: _firstString(json, const [
        'storage',
        'storageLocation',
        'storageType',
        'location',
        'storageName',
        'storageCondition',
        'storageConditions',
      ]),
      organizationId: json['organizationId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'category': category,
      'unit': unit,
      'description': description,
      'sku': sku,
      'storageLocation': storageLocation,
      'organizationId': organizationId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class StockSummary {
  final int totalItems;
  final int inStock;
  final int lowStock;
  final int outOfStock;
  final int expired;
  final int locked;
  final int totalValue;
  final int itemsWithExpiringBatches;

  StockSummary({
    required this.totalItems,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.expired,
    this.locked = 0,
    required this.totalValue,
    this.itemsWithExpiringBatches = 0,
  });

  factory StockSummary.fromJson(Map<String, dynamic> json) {
    return StockSummary(
      totalItems: int.tryParse(json['totalItems']?.toString() ?? '0') ?? 0,
      inStock: int.tryParse(json['inStock']?.toString() ?? '0') ?? 0,
      lowStock: int.tryParse(json['lowStock']?.toString() ?? '0') ?? 0,
      outOfStock: int.tryParse(json['outOfStock']?.toString() ?? '0') ?? 0,
      expired: int.tryParse(json['expired']?.toString() ?? '0') ?? 0,
      locked: int.tryParse(json['locked']?.toString() ?? '0') ?? 0,
      totalValue: int.tryParse(json['totalValue']?.toString() ?? '0') ?? 0,
      itemsWithExpiringBatches:
          int.tryParse(json['itemsWithExpiringBatches']?.toString() ?? '0') ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalItems': totalItems,
      'inStock': inStock,
      'lowStock': lowStock,
      'outOfStock': outOfStock,
      'expired': expired,
      'locked': locked,
      'totalValue': totalValue,
      'itemsWithExpiringBatches': itemsWithExpiringBatches,
    };
  }

  // Get percentage of items in stock
  double get inStockPercentage {
    if (totalItems == 0) return 0;
    return (inStock / totalItems * 100).clamp(0, 100);
  }

  // Get percentage of low stock items
  double get lowStockPercentage {
    if (totalItems == 0) return 0;
    return (lowStock / totalItems * 100).clamp(0, 100);
  }
}

// Enums for UI
enum ItemStatus {
  useSoon, // Expiring within 30 days
  lowStock, // At or below reorder level
  expired, // Past expiry date
  nearReorder, // Within 20% above reorder level
  outOfStock, // Zero quantity
}

// Extension to get display properties for ItemStatus
extension ItemStatusExtension on ItemStatus {
  String get label {
    switch (this) {
      case ItemStatus.useSoon:
        return 'Use Soon';
      case ItemStatus.lowStock:
        return 'Low Stock';
      case ItemStatus.expired:
        return 'Expired';
      case ItemStatus.nearReorder:
        return 'Near Reorder';
      case ItemStatus.outOfStock:
        return 'Out of Stock';
    }
  }

  String get description {
    switch (this) {
      case ItemStatus.useSoon:
        return 'Expires within 30 days';
      case ItemStatus.lowStock:
        return 'Stock at or below reorder level';
      case ItemStatus.expired:
        return 'Item has expired';
      case ItemStatus.nearReorder:
        return 'Stock approaching reorder level';
      case ItemStatus.outOfStock:
        return 'No stock available';
    }
  }

  int get priority {
    switch (this) {
      case ItemStatus.expired:
        return 5;
      case ItemStatus.outOfStock:
        return 4;
      case ItemStatus.lowStock:
        return 3;
      case ItemStatus.nearReorder:
        return 2;
      case ItemStatus.useSoon:
        return 1;
    }
  }
}

// CatalogItem class for UI compatibility
class CatalogItem {
  final String id;
  final String itemId;
  final String name;
  final double quantity;
  final String unit;
  final int expiryDays;
  final String storage;
  final int batches;
  final String category;
  final ItemStatus? status;
  final double reorderLevel;
  final double maxLevel;
  final bool isNearReorder;
  final double unitCost;
  final double totalValue;
  final double stockPercentage;
  final String sku;
  final String description;
  final bool isLocked;
  final String? lockReason;
  final bool allowNegativeStock;
  final double reservedStock;
  final int expiringBatchCount;
  final String? nearestExpiryDate;

  CatalogItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.expiryDays,
    required this.storage,
    required this.batches,
    required this.category,
    this.status,
    required this.reorderLevel,
    required this.maxLevel,
    required this.isNearReorder,
    required this.unitCost,
    required this.totalValue,
    required this.stockPercentage,
    this.sku = '',
    this.description = '',
    this.isLocked = false,
    this.lockReason,
    this.allowNegativeStock = false,
    this.reservedStock = 0,
    this.expiringBatchCount = 0,
    this.nearestExpiryDate,
  });

  // Helper to check if item needs attention
  bool get needsAttention => status != null;

  // Helper to get stock level description
  String get stockLevelDescription {
    if (quantity == 0) return 'Out of stock';
    if (quantity <= reorderLevel) return 'Low stock - reorder needed';
    if (isNearReorder) return 'Stock approaching reorder level';
    return 'Stock level adequate';
  }

  // Helper to format quantity display
  String get quantityDisplay => '${quantity.toStringAsFixed(1)} $unit';

  // Helper to format reorder level display
  String get reorderLevelDisplay => '${reorderLevel.toStringAsFixed(1)} $unit';

  // Helper to format max level display
  String get maxLevelDisplay => '${maxLevel.toStringAsFixed(1)} $unit';

  // Helper to format expiry display
  String get expiryDisplay {
    if (expiryDays == 999) {
      return status == ItemStatus.expired ? 'Batch expired' : 'No batch expiry';
    }
    if (expiryDays < 0) return 'Expired ${expiryDays.abs()} days ago';
    if (expiryDays == 0) return 'Expires today';
    if (expiryDays == 1) return 'Expires tomorrow';
    return 'Expires in $expiryDays days';
  }
}

double _toDouble(dynamic value) {
  return double.tryParse(value?.toString() ?? '0') ?? 0;
}

int _toInt(dynamic value, {int fallback = 0}) {
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  return '';
}
