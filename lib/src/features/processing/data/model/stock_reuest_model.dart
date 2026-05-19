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
  final StockRequestUser? requestedBy; // ← was String?
  final String department;
  final String organizationId;
  final String status;
  final StockRequestUser? approvedBy; // ← was String?
  final DateTime? approvedAt;
  final StockRequestUser? completedBy; // ← was String?
  final DateTime? completedAt;
  final StockRequestUser? rejectedBy; // ← new field from API
  final DateTime? rejectedAt; // ← new field from API
  final String? rejectionNote; // ← new field from API
  final String? approvalNote; // ← new field from API
  final String? cancellationNote; // ← new field from API
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StockRequestItem> items;
  final RequestingBranch? requestingBranch;

  StockRequest({
    required this.id,
    required this.requestId,
    required this.requestingBranchId,
    this.requestedBy,
    required this.department,
    required this.organizationId,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.completedBy,
    this.completedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionNote,
    this.approvalNote,
    this.cancellationNote,
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
      requestedBy: _parseUser(json['requestedBy']),
      department: json['department'] ?? '',
      organizationId: json['organizationId'] ?? '',
      status: json['status'] ?? 'PENDING',
      approvedBy: _parseUser(json['approvedBy']),
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      completedBy: _parseUser(json['completedBy']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      rejectedBy: _parseUser(json['rejectedBy']),
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt'])
          : null,
      rejectionNote: json['rejectionNote'],
      approvalNote: json['approvalNote'],
      cancellationNote: json['cancellationNote'],
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
      'requestedBy': requestedBy?.toJson(),
      'department': department,
      'organizationId': organizationId,
      'status': status,
      'approvedBy': approvedBy?.toJson(),
      'approvedAt': approvedAt?.toIso8601String(),
      'completedBy': completedBy?.toJson(),
      'completedAt': completedAt?.toIso8601String(),
      'rejectedBy': rejectedBy?.toJson(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectionNote': rejectionNote,
      'approvalNote': approvalNote,
      'cancellationNote': cancellationNote,
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
// lib/src/features/stock_control/data/model/stock_request.dart

// Add this new class for user references
class StockRequestUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String department;
  final String employeeId;

  StockRequestUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.department,
    required this.employeeId,
  });

  String get fullName => '$firstName $lastName';

  factory StockRequestUser.fromJson(Map<String, dynamic> json) {
    return StockRequestUser(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      department: json['department'] ?? '',
      employeeId: json['employeeId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'department': department,
      'employeeId': employeeId,
    };
  }
}

// Helper to safely parse a user field that could be null, a String, or a Map
StockRequestUser? _parseUser(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return StockRequestUser.fromJson(value);
  return null; // was a plain string ID — treat as unknown
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
