class BranchStockSummaryResponse {
  final String message;
  final BranchStockSummaryData data;

  BranchStockSummaryResponse({required this.message, required this.data});

  factory BranchStockSummaryResponse.fromJson(Map<String, dynamic> json) {
    return BranchStockSummaryResponse(
      message: json['message'] ?? '',
      data: BranchStockSummaryData.fromJson(json['data'] ?? {}),
    );
  }

  bool get isValid => data.overview.totalItems > 0;
}

class BranchStockSummaryData {
  final Overview overview;
  final List<StockByCategory> stockByCategory;
  final List<LowStockItem> lowStockItems;
  final List<ExpiringItem> expiringItems;
  final List<RecentMovement> recentMovements;

  BranchStockSummaryData({
    required this.overview,
    required this.stockByCategory,
    required this.lowStockItems,
    required this.expiringItems,
    required this.recentMovements,
  });

  factory BranchStockSummaryData.fromJson(Map<String, dynamic> json) {
    final overviewJson = Map<String, dynamic>.from(json['overview'] ?? {});
    if (json.containsKey('itemsWithExpiringBatches')) {
      overviewJson['itemsWithExpiringBatches'] =
          json['itemsWithExpiringBatches'];
    }

    return BranchStockSummaryData(
      overview: Overview.fromJson(overviewJson),
      stockByCategory:
          (json['stockByCategory'] as List<dynamic>?)
              ?.map((e) => StockByCategory.fromJson(e))
              .toList() ??
          [],
      lowStockItems:
          (json['lowStockItems'] as List<dynamic>?)
              ?.map((e) => LowStockItem.fromJson(e))
              .toList() ??
          [],
      expiringItems:
          (json['expiringItems'] as List<dynamic>?)
              ?.map((e) => ExpiringItem.fromJson(e))
              .toList() ??
          [],
      recentMovements:
          (json['recentMovements'] as List<dynamic>?)
              ?.map((e) => RecentMovement.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Overview {
  final int totalItems;
  final int totalStockQuantity;
  final double totalValue;
  final int itemsWithExpiringBatches;
  final StatusBreakdown statusBreakdown;

  Overview({
    required this.totalItems,
    required this.totalStockQuantity,
    required this.totalValue,
    this.itemsWithExpiringBatches = 0,
    required this.statusBreakdown,
  });

  factory Overview.fromJson(Map<String, dynamic> json) {
    return Overview(
      totalItems: _parseInt(json['totalItems']),
      totalStockQuantity: _parseInt(json['totalStockQuantity']),
      totalValue: _parseDouble(json['totalValue']),
      itemsWithExpiringBatches: _parseInt(
        json['itemsWithExpiringBatches'] ??
            json['expiringBatchCount'] ??
            json['expiringBatches'],
      ),
      statusBreakdown: StatusBreakdown.fromJson(json['statusBreakdown'] ?? {}),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class StatusBreakdown {
  final int inStock;
  final int expired;

  StatusBreakdown({required this.inStock, required this.expired});

  factory StatusBreakdown.fromJson(Map<String, dynamic> json) {
    return StatusBreakdown(
      inStock: _parseInt(json['IN_STOCK']),
      expired: _parseInt(json['EXPIRED']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class StockByCategory {
  final String category;
  final int itemCount;
  final int totalStock;
  final double totalValue;

  StockByCategory({
    required this.category,
    required this.itemCount,
    required this.totalStock,
    required this.totalValue,
  });

  factory StockByCategory.fromJson(Map<String, dynamic> json) {
    return StockByCategory(
      category: json['category'] ?? '',
      itemCount: _parseInt(json['itemCount']),
      totalStock: _parseInt(json['totalStock']),
      totalValue: _parseDouble(json['totalValue']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Convert to InventoryItem for UI display
  InventoryItem toInventoryItem() {
    return InventoryItem(
      name: _formatCategoryName(category),
      unitsRemaining: totalStock,
      stockLevel: _determineStockLevel(totalStock),
      category: category,
      totalValue: totalValue,
      itemCount: itemCount,
    );
  }

  String _formatCategoryName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _determineStockLevel(int stock) {
    if (stock < 100) return 'Low';
    if (stock < 500) return 'Medium';
    return 'High';
  }
}

class LowStockItem {
  final String itemName;
  final String category;
  final int currentStock;
  final int? reorderLevel;

  LowStockItem({
    required this.itemName,
    required this.category,
    required this.currentStock,
    this.reorderLevel,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) {
    return LowStockItem(
      itemName: json['itemName'] ?? '',
      category: json['category'] ?? '',
      currentStock: _parseInt(json['currentStock']),
      reorderLevel: json['reorderLevel'] != null
          ? _parseInt(json['reorderLevel'])
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class ExpiringItem {
  final String itemName;
  final String category;
  final DateTime expiryDate;
  final int quantity;

  ExpiringItem({
    required this.itemName,
    required this.category,
    required this.expiryDate,
    required this.quantity,
  });

  factory ExpiringItem.fromJson(Map<String, dynamic> json) {
    return ExpiringItem(
      itemName: json['itemName'] ?? '',
      category: json['category'] ?? '',
      expiryDate: _parseDateTime(json['expiryDate']),
      quantity: _parseInt(json['quantity']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

class RecentMovement {
  final String id;
  final String itemId;
  final String branchId;
  final String organizationId;
  final String movementType;
  final int? inflow;
  final int? outflow;
  final int? variance;
  final int balanceBefore;
  final int balanceAfter;
  final String? note;
  final String? reference;
  final String performedBy;
  final DateTime createdAt;
  final ItemInfo item;

  RecentMovement({
    required this.id,
    required this.itemId,
    required this.branchId,
    required this.organizationId,
    required this.movementType,
    this.inflow,
    this.outflow,
    this.variance,
    required this.balanceBefore,
    required this.balanceAfter,
    this.note,
    this.reference,
    required this.performedBy,
    required this.createdAt,
    required this.item,
  });

  factory RecentMovement.fromJson(Map<String, dynamic> json) {
    return RecentMovement(
      id: json['id'] ?? '',
      itemId: json['itemId'] ?? '',
      branchId: json['branchId'] ?? '',
      organizationId: json['organizationId'] ?? '',
      movementType: json['movementType'] ?? '',
      inflow: json['inflow'] != null ? _parseInt(json['inflow']) : null,
      outflow: json['outflow'] != null ? _parseInt(json['outflow']) : null,
      variance: json['variance'] != null ? _parseInt(json['variance']) : null,
      balanceBefore: _parseInt(json['balanceBefore']),
      balanceAfter: _parseInt(json['balanceAfter']),
      note: json['note'],
      reference: json['reference'],
      performedBy: json['performedBy'] ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      item: ItemInfo.fromJson(json['item'] ?? {}),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

class ItemInfo {
  final String itemName;

  ItemInfo({required this.itemName});

  factory ItemInfo.fromJson(Map<String, dynamic> json) {
    return ItemInfo(itemName: json['itemName'] ?? '');
  }
}

// UI Model for displaying inventory items
class InventoryItem {
  final String name;
  final int unitsRemaining;
  final String stockLevel;
  final String category;
  final double totalValue;
  final int itemCount;

  InventoryItem({
    required this.name,
    required this.unitsRemaining,
    required this.stockLevel,
    required this.category,
    required this.totalValue,
    required this.itemCount,
  });
}
