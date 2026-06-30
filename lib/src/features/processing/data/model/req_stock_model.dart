class CreateStockRequestRequest {
  final String requestingBranchId;
  final String requestedBy;
  final String department;
  final String? notes;
  final List<StockRequestItemInput> items;

  CreateStockRequestRequest({
    required this.requestingBranchId,
    required this.requestedBy,
    required this.department,
    this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'requestingBranchId': requestingBranchId,
      'requestedBy': requestedBy,
      'department': department,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class StockRequestItemInput {
  final String itemId;
  final double qtyRequested;

  StockRequestItemInput({required this.itemId, required this.qtyRequested});

  Map<String, dynamic> toJson() {
    return {'itemId': itemId, 'qtyRequested': qtyRequested};
  }
}

class CreateStockRequestResponse {
  final String message;
  final StockRequest data;

  CreateStockRequestResponse({required this.message, required this.data});

  factory CreateStockRequestResponse.fromJson(Map<String, dynamic> json) {
    return CreateStockRequestResponse(
      message: json['message'] ?? '',
      data: StockRequest.fromJson(json['data'] ?? {}),
    );
  }

  bool get isValid => data.id.isNotEmpty;
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
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StockRequestItem> items;
  final BranchInfo? requestingBranch;

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
    this.notes,
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
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => StockRequestItem.fromJson(item))
              .toList() ??
          [],
      requestingBranch: json['requestingBranch'] != null
          ? BranchInfo.fromJson(json['requestingBranch'])
          : null,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isRejected => status == 'REJECTED';
}

class StockRequestItem {
  final String id;
  final String requestId;
  final String itemId;
  final String qtyRequested;
  final String? qtySent;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ItemInfo? item;

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
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      item: json['item'] != null ? ItemInfo.fromJson(json['item']) : null,
    );
  }

  double get qtyRequestedValue => double.tryParse(qtyRequested) ?? 0.0;
  double? get qtySentValue =>
      qtySent != null ? double.tryParse(qtySent!) : null;
}

class ItemInfo {
  final String itemName;
  final String unit;

  ItemInfo({required this.itemName, required this.unit});

  factory ItemInfo.fromJson(Map<String, dynamic> json) {
    return ItemInfo(itemName: json['itemName'] ?? '', unit: json['unit'] ?? '');
  }
}

class BranchInfo {
  final String name;
  final String branchCode;

  BranchInfo({required this.name, required this.branchCode});

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      name: json['name'] ?? '',
      branchCode: json['branch_code'] ?? '',
    );
  }
}

class StockRequestResponse {
  final List<StockRequest> data;
  final String? message;

  StockRequestResponse({required this.data, this.message});

  factory StockRequestResponse.fromJson(Map<String, dynamic> json) {
    return StockRequestResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => StockRequest.fromJson(item))
              .toList() ??
          [],
      message: json['message'],
    );
  }
}
