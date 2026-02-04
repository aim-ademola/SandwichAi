// lib/src/features/stock_control/data/model/stock_request.dart

class StockRequestItem {
  final String id;
  final String requestId;
  final String itemId;
  final String qtyRequested;
  final String? qtySent;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final StockRequestItemDetails? item;

  StockRequestItem({
    required this.id,
    required this.requestId,
    required this.itemId,
    required this.qtyRequested,
    this.qtySent,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.item,
  });

  factory StockRequestItem.fromJson(Map<String, dynamic> json) {
    return StockRequestItem(
      id: json['id'] ?? '',
      requestId: json['requestId'] ?? '',
      itemId: json['itemId'] ?? '',
      qtyRequested: json['qtyRequested']?.toString() ?? '0',
      qtySent: json['qtySent']?.toString(),
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      item: json['item'] != null
          ? StockRequestItemDetails.fromJson(json['item'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'itemId': itemId,
      'qtyRequested': qtyRequested,
      'qtySent': qtySent,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'item': item?.toJson(),
    };
  }
}

class StockRequestItemDetails {
  final String itemName;
  final String unit;

  StockRequestItemDetails({required this.itemName, required this.unit});

  factory StockRequestItemDetails.fromJson(Map<String, dynamic> json) {
    return StockRequestItemDetails(
      itemName: json['itemName'] ?? '',
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'itemName': itemName, 'unit': unit};
  }
}

class RequestingBranch {
  final String name;
  final String branchCode;

  RequestingBranch({required this.name, required this.branchCode});

  factory RequestingBranch.fromJson(Map<String, dynamic> json) {
    return RequestingBranch(
      name: json['name'] ?? '',
      branchCode: json['branch_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'branch_code': branchCode};
  }
}

class StockRequest {
  final String id;
  final String requestId;
  final String requestingBranchId;
  final String requestedBy;
  final String department;
  final String organizationId;
  final String status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? completedBy;
  final DateTime? completedAt;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StockRequestItem> items;
  final RequestingBranch? requestingBranch;

  StockRequest({
    required this.id,
    required this.requestId,
    required this.requestingBranchId,
    required this.requestedBy,
    required this.department,
    required this.organizationId,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.completedBy,
    this.completedAt,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.requestingBranch,
  });

  factory StockRequest.fromJson(Map<String, dynamic> json) {
    return StockRequest(
      id: json['id'] ?? '',
      requestId: json['requestId'] ?? '',
      requestingBranchId: json['requestingBranchId'] ?? '',
      requestedBy: json['requestedBy'] ?? '',
      department: json['department'] ?? '',
      organizationId: json['organizationId'] ?? '',
      status: json['status'] ?? 'PENDING',
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      completedBy: json['completedBy'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      notes: json['notes'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => StockRequestItem.fromJson(item))
              .toList() ??
          [],
      requestingBranch: json['requestingBranch'] != null
          ? RequestingBranch.fromJson(json['requestingBranch'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'requestingBranchId': requestingBranchId,
      'requestedBy': requestedBy,
      'department': department,
      'organizationId': organizationId,
      'status': status,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'completedBy': completedBy,
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'requestingBranch': requestingBranch?.toJson(),
    };
  }

  int get totalItemsCount => items.length;

  int get totalQuantityRequested => items.fold(
    0,
    (sum, item) => sum + (int.tryParse(item.qtyRequested) ?? 0),
  );
}

// Create Stock Request Models
class CreateStockRequestItem {
  final String itemId;
  final int qtyRequested;

  CreateStockRequestItem({required this.itemId, required this.qtyRequested});

  Map<String, dynamic> toJson() {
    return {'itemId': itemId, 'qtyRequested': qtyRequested};
  }
}

class CreateStockRequestRequest {
  final String requestingBranchId;
  final String requestedBy;
  final String department;
  final String notes;
  final List<CreateStockRequestItem> items;

  CreateStockRequestRequest({
    required this.requestingBranchId,
    required this.requestedBy,
    required this.department,
    required this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'requestingBranchId': requestingBranchId,
      'requestedBy': requestedBy,
      'department': department,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class StockRequestResponse {
  final String message;
  final List<StockRequest> data;

  StockRequestResponse({required this.message, required this.data});

  factory StockRequestResponse.fromJson(Map<String, dynamic> json) {
    return StockRequestResponse(
      message: json['message'] ?? '',
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => StockRequest.fromJson(item))
              .toList() ??
          [],
    );
  }

  bool get isValid => data.isNotEmpty;
}

class CreateStockRequestResponse {
  final String message;
  final StockRequest data;

  CreateStockRequestResponse({required this.message, required this.data});

  factory CreateStockRequestResponse.fromJson(Map<String, dynamic> json) {
    return CreateStockRequestResponse(
      message: json['message'] ?? '',
      data: StockRequest.fromJson(json['data']),
    );
  }

  bool get isValid => data.id.isNotEmpty;
}
