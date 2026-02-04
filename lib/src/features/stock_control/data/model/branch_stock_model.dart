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
    required this.item,
  });

  factory BranchStockItem.fromJson(Map<String, dynamic> json) {
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
    if (expiryDate == null) return 999;
    try {
      final expiry = DateTime.parse(expiryDate!);
      final now = DateTime.now();
      return expiry.difference(now).inDays;
    } catch (e) {
      return 999;
    }
  }

  // Check if expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return daysUntilExpiry <= 0;
  }

  // Check if expiring soon (within 30 days)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    return daysUntilExpiry > 0 && daysUntilExpiry <= 30;
  }

  // Convert status string to ItemStatus enum with priority logic
  ItemStatus? get itemStatus {
    // Priority: expired > out of stock > low stock > near reorder > use soon

    // Check if expired (highest priority)
    if (isExpired || status.toUpperCase() == 'EXPIRED') {
      return ItemStatus.expired;
    }

    // Check if out of stock
    if (isOutOfStock || status.toUpperCase() == 'OUT_OF_STOCK') {
      return ItemStatus.outOfStock;
    }

    // Check if at or below reorder level
    if (isAtOrBelowReorder || status.toUpperCase() == 'LOW_STOCK') {
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

  // Get storage location from category or other fields
  String get storage {
    final category = item.category.toLowerCase();
    if (category.contains('protein') ||
        category.contains('meat') ||
        category.contains('dairy') ||
        category.contains('frozen')) {
      return 'Freezer';
    } else if (category.contains('vegetable') ||
        category.contains('fruit') ||
        category.contains('fresh')) {
      return 'Refrigerator';
    } else if (category.contains('grain') ||
        category.contains('spice') ||
        category.contains('seasoning') ||
        category.contains('dry')) {
      return 'Dry Storage';
    }
    return 'Storage';
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
      batches: 1,
      category: item.category,
      status: itemStatus,
      reorderLevel: reorderLevelValue,
      maxLevel: maxLevelValue,
      isNearReorder: isNearReorder,
      unitCost: unitCostValue,
      totalValue: totalValueValue,
      stockPercentage: stockToReorderPercentage,
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
      'item': item.toJson(),
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
  final int totalValue;

  StockSummary({
    required this.totalItems,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.expired,
    required this.totalValue,
  });

  factory StockSummary.fromJson(Map<String, dynamic> json) {
    return StockSummary(
      totalItems: int.tryParse(json['totalItems']?.toString() ?? '0') ?? 0,
      inStock: int.tryParse(json['inStock']?.toString() ?? '0') ?? 0,
      lowStock: int.tryParse(json['lowStock']?.toString() ?? '0') ?? 0,
      outOfStock: int.tryParse(json['outOfStock']?.toString() ?? '0') ?? 0,
      expired: int.tryParse(json['expired']?.toString() ?? '0') ?? 0,
      totalValue: int.tryParse(json['totalValue']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalItems': totalItems,
      'inStock': inStock,
      'lowStock': lowStock,
      'outOfStock': outOfStock,
      'expired': expired,
      'totalValue': totalValue,
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
    if (expiryDays == 999) return 'No expiry';
    if (expiryDays < 0) return 'Expired ${expiryDays.abs()} days ago';
    if (expiryDays == 0) return 'Expires today';
    if (expiryDays == 1) return 'Expires tomorrow';
    return 'Expires in $expiryDays days';
  }
}
