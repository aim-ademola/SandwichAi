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
      id: _parseString(json['id']),
      requestId: _parseString(json['requestId']),
      itemId: _parseString(json['itemId']),
      qtyRequested: json['qtyRequested']?.toString() ?? '0',
      qtySent: json['qtySent']?.toString(),
      status: _parseString(json['status'], fallback: 'PENDING'),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      item: _asMap(json['item']).isNotEmpty
          ? StockRequestItemDetails.fromJson(_asMap(json['item']))
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
      itemName: _parseString(json['itemName'] ?? json['name']),
      unit: _parseString(json['unit']),
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
      name: _parseString(json['name']),
      branchCode: _parseString(json['branch_code'] ?? json['branchCode']),
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
      id: _parseString(json['id']),
      requestId: _parseString(json['requestId'] ?? json['request_id']),
      requestingBranchId: _parseString(
        json['requestingBranchId'] ?? json['requesting_branch_id'],
      ),
      requestedBy: _parseUser(json['requestedBy']),
      department: _parseString(json['department']),
      organizationId: _parseString(
        json['organizationId'] ?? json['organization_id'],
      ),
      status: _parseString(json['status'], fallback: 'PENDING'),
      approvedBy: _parseUser(json['approvedBy']),
      approvedAt: _parseDateTimeOrNull(json['approvedAt']),
      completedBy: _parseUser(json['completedBy']),
      completedAt: _parseDateTimeOrNull(json['completedAt']),
      rejectedBy: _parseUser(json['rejectedBy']),
      rejectedAt: _parseDateTimeOrNull(json['rejectedAt']),
      rejectionNote: _parseStringOrNull(json['rejectionNote']),
      approvalNote: _parseStringOrNull(json['approvalNote']),
      cancellationNote: _parseStringOrNull(json['cancellationNote']),
      notes: _parseString(json['notes']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      items: _asList(json['items'])
          .whereType<Map>()
          .map(
            (item) => StockRequestItem.fromJson(item.cast<String, dynamic>()),
          )
          .toList(),
      requestingBranch: _asMap(json['requestingBranch']).isNotEmpty
          ? RequestingBranch.fromJson(_asMap(json['requestingBranch']))
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

  double get totalQuantityRequested => items.fold(
    0.0,
    (sum, item) => sum + (double.tryParse(item.qtyRequested) ?? 0.0),
  );
}

// Create Stock Request Models
class CreateStockRequestItem {
  final String itemId;
  final double qtyRequested;

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
    final data = _extractStockRequestList(json);
    return StockRequestResponse(
      message: json['message'] ?? '',
      data: data
          .whereType<Map<String, dynamic>>()
          .map(StockRequest.fromJson)
          .toList(),
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
      id: _parseString(json['id']),
      firstName: _parseString(json['firstName']),
      lastName: _parseString(json['lastName']),
      email: _parseString(json['email']),
      role: _parseString(json['role']),
      department: _parseString(json['department']),
      employeeId: _parseString(json['employeeId']),
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
  final user = _asMap(value);
  if (user.isNotEmpty) return StockRequestUser.fromJson(user);
  return null; // was a plain string ID — treat as unknown
}

class CreateStockRequestResponse {
  final String message;
  final StockRequest data;

  CreateStockRequestResponse({required this.message, required this.data});

  factory CreateStockRequestResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final stockRequestJson = data is Map<String, dynamic> ? data : json;
    return CreateStockRequestResponse(
      message: _parseString(json['message']),
      data: StockRequest.fromJson(stockRequestJson),
    );
  }

  bool get isValid => data.id.isNotEmpty;
}

String _parseString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return fallback;
}

String? _parseStringOrNull(dynamic value) {
  final parsed = _parseString(value);
  return parsed.isEmpty ? null : parsed;
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

DateTime? _parseDateTimeOrNull(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

List<dynamic> _extractStockRequestList(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is List) return data;
  if (data is Map<String, dynamic>) {
    final nestedData = data['data'];
    if (nestedData is List) return nestedData;

    final items = data['items'] ?? data['stockRequests'] ?? data['requests'];
    if (items is List) return items;

    if (data.containsKey('id') || data.containsKey('requestId')) {
      return [data];
    }
  }

  final items = json['items'] ?? json['stockRequests'] ?? json['requests'];
  if (items is List) return items;

  if (json.containsKey('id') || json.containsKey('requestId')) {
    return [json];
  }

  return const [];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}
