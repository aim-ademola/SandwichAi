import 'package:equatable/equatable.dart';

/// Movement Type Enum
enum MovementType {
  INFLOW,
  OUTFLOW,
  SPOILAGE,
  TRANSFER,
  ADJUSTMENT;

  String get displayName {
    switch (this) {
      case MovementType.INFLOW:
        return 'Received';
      case MovementType.OUTFLOW:
        return 'Consumed';
      case MovementType.SPOILAGE:
        return 'Spoilage';
      case MovementType.TRANSFER:
        return 'Transfer';
      case MovementType.ADJUSTMENT:
        return 'Adjustment';
    }
  }

  static MovementType fromString(String value) {
    return MovementType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MovementType.ADJUSTMENT,
    );
  }
}

/// Stock Movement Item Model
class StockMovementItem extends Equatable {
  final String id;
  final String itemId;
  final String branchId;
  final String organizationId;
  final MovementType movementType;
  final String? inflow;
  final String? outflow;
  final String? variance;
  final String balanceBefore;
  final String balanceAfter;
  final String? note;
  final String? reference;
  final String performedBy;
  final DateTime createdAt;
  final ItemInfo item;
  final BranchInfo branch;

  const StockMovementItem({
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
    required this.branch,
  });

  factory StockMovementItem.fromJson(Map<String, dynamic> json) {
    return StockMovementItem(
      id: json['id'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      movementType: MovementType.fromString(
        json['movementType'] as String? ?? 'ADJUSTMENT',
      ),
      inflow: json['inflow'] as String?,
      outflow: json['outflow'] as String?,
      variance: json['variance'] as String?,
      balanceBefore: json['balanceBefore'] as String? ?? '0',
      balanceAfter: json['balanceAfter'] as String? ?? '0',
      note: json['note'] as String?,
      reference: json['reference'] as String?,
      performedBy: json['performedBy'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      item: ItemInfo.fromJson(json['item'] as Map<String, dynamic>? ?? {}),
      branch: BranchInfo.fromJson(
        json['branch'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'branchId': branchId,
      'organizationId': organizationId,
      'movementType': movementType.name,
      'inflow': inflow,
      'outflow': outflow,
      'variance': variance,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'note': note,
      'reference': reference,
      'performedBy': performedBy,
      'createdAt': createdAt.toIso8601String(),
      'item': item.toJson(),
      'branch': branch.toJson(),
    };
  }

  String get quantityDisplay {
    if (inflow != null) return '$inflow ${item.unit}';
    if (outflow != null) return '$outflow ${item.unit}';
    if (variance != null) return '$variance ${item.unit}';
    return '0 ${item.unit}';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  @override
  List<Object?> get props => [
    id,
    itemId,
    branchId,
    organizationId,
    movementType,
    inflow,
    outflow,
    variance,
    balanceBefore,
    balanceAfter,
    note,
    reference,
    performedBy,
    createdAt,
    item,
    branch,
  ];
}

/// Item Info Model
class ItemInfo extends Equatable {
  final String itemName;
  final String unit;

  const ItemInfo({required this.itemName, required this.unit});

  factory ItemInfo.fromJson(Map<String, dynamic> json) {
    return ItemInfo(
      itemName: json['itemName'] as String? ?? 'Unknown Item',
      unit: json['unit'] as String? ?? 'UNIT',
    );
  }

  Map<String, dynamic> toJson() {
    return {'itemName': itemName, 'unit': unit};
  }

  @override
  List<Object?> get props => [itemName, unit];
}

/// Branch Info Model
class BranchInfo extends Equatable {
  final String name;
  final String branchCode;

  const BranchInfo({required this.name, required this.branchCode});

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      name: json['name'] as String? ?? 'Unknown Branch',
      branchCode: json['branch_code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'branch_code': branchCode};
  }

  @override
  List<Object?> get props => [name, branchCode];
}

/// Pagination Model
class PaginationInfo extends Equatable {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginationInfo({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
    };
  }

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  @override
  List<Object?> get props => [total, page, limit, totalPages];
}

/// Stock Movement Response Model
class StockMovementResponse extends Equatable {
  final String message;
  final List<StockMovementItem> data;
  final PaginationInfo pagination;

  const StockMovementResponse({
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory StockMovementResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return StockMovementResponse(
      message: json['message'] as String? ?? '',
      data: dataList
          .map(
            (item) => StockMovementItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      pagination: PaginationInfo.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }

  bool get isValid => data.isNotEmpty;

  List<StockMovementItem> get inflowMovements =>
      data.where((item) => item.movementType == MovementType.INFLOW).toList();

  List<StockMovementItem> get outflowMovements =>
      data.where((item) => item.movementType == MovementType.OUTFLOW).toList();

  @override
  List<Object?> get props => [message, data, pagination];
}
