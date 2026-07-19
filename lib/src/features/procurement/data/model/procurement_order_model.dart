class ProcurementResponse {
  final String message;
  final List<ProcurementRequest> data;

  ProcurementResponse({required this.message, required this.data});

  factory ProcurementResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return ProcurementResponse(
      message: _string(json['message']),
      data: data is List
          ? data
                .whereType<Map>()
                .map(
                  (e) => ProcurementRequest.fromJson(e.cast<String, dynamic>()),
                )
                .toList()
          : [],
    );
  }

  bool get isValid => data.isNotEmpty;

  List<ProcurementRequest> getByStatus(String status) {
    if (status.toUpperCase() == 'ALL') return data;
    return data
        .where((req) => req.status.toUpperCase() == status.toUpperCase())
        .toList();
  }
}

class ProcurementRequest {
  final String id;
  final String requestId;
  final String branchId;
  final String organizationId;
  final String requestedBy;
  final String status;
  final String priority;
  final String? approvedBy;
  final String? approvedAt;
  final String? rejectedBy;
  final String? rejectedAt;
  final String? rejectionNote;
  final String? expectedDelivery;
  final String? actualDelivery;
  final String totalAmount;
  final String? notes;
  final String requestingDepartment;
  final String createdAt;
  final String updatedAt;
  final List<ProcurementItem> items;
  final BranchInfo branch;

  ProcurementRequest({
    required this.id,
    required this.requestId,
    required this.branchId,
    required this.organizationId,
    required this.requestedBy,
    required this.status,
    required this.priority,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionNote,
    this.expectedDelivery,
    this.actualDelivery,
    required this.totalAmount,
    this.notes,
    required this.requestingDepartment,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.branch,
  });

  factory ProcurementRequest.fromJson(Map<String, dynamic> json) {
    return ProcurementRequest(
      id: _parseToString(json['id']),
      requestId: _parseToString(json['requestId']),
      branchId: _parseToString(json['branchId']),
      organizationId: _parseToString(json['organizationId']),
      requestedBy: _parseToString(json['requestedBy']),
      status: _parseToString(json['status']),
      priority: _parseToString(json['priority']),
      approvedBy: json['approvedBy'] != null
          ? _parseToString(json['approvedBy'])
          : null,
      approvedAt: json['approvedAt'] != null
          ? _parseToString(json['approvedAt'])
          : null,
      rejectedBy: json['rejectedBy'] != null
          ? _parseToString(json['rejectedBy'])
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? _parseToString(json['rejectedAt'])
          : null,
      rejectionNote: json['rejectionNote'] != null
          ? _parseToString(json['rejectionNote'])
          : null,
      expectedDelivery: json['expectedDelivery'] != null
          ? _parseToString(json['expectedDelivery'])
          : null,
      actualDelivery: json['actualDelivery'] != null
          ? _parseToString(json['actualDelivery'])
          : null,
      totalAmount: _parseToString(json['totalAmount']),
      notes: json['notes'] != null ? _parseToString(json['notes']) : null,
      requestingDepartment: _parseToString(
        json['requestingDepartment'] ??
            json['department'] ??
            json['requestedByDepartment'],
      ),
      createdAt: _parseToString(json['createdAt']),
      updatedAt: _parseToString(json['updatedAt']),
      items: _asList(json['items'])
          .whereType<Map>()
          .map((e) => ProcurementItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      branch: BranchInfo.fromJson(_asMap(json['branch'])),
    );
  }

  // Helper method to safely convert any type to String
  static String _parseToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    if (value is bool) return value.toString();
    return value.toString();
  }

  double get totalAmountDouble => double.tryParse(totalAmount) ?? 0.0;

  int get itemCount => items.length;

  String get formattedExpectedDelivery {
    if (expectedDelivery == null || expectedDelivery!.isEmpty) return 'Not set';
    try {
      final date = DateTime.parse(expectedDelivery!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String get formattedCreatedAt {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}

class ProcurementItem {
  final String id;
  final String requestId;
  final String itemId;
  final String currentStock;
  final String minLevel;
  final String qtyNeeded;
  final String? qtyApproved;
  final String? qtyReceived;
  final String unitCost;
  final String totalCost;
  final String status;
  final String createdAt;
  final String updatedAt;
  final ItemInfo item;

  ProcurementItem({
    required this.id,
    required this.requestId,
    required this.itemId,
    required this.currentStock,
    required this.minLevel,
    required this.qtyNeeded,
    this.qtyApproved,
    this.qtyReceived,
    required this.unitCost,
    required this.totalCost,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.item,
  });

  factory ProcurementItem.fromJson(Map<String, dynamic> json) {
    return ProcurementItem(
      id: _parseToString(json['id']),
      requestId: _parseToString(json['requestId']),
      itemId: _parseToString(json['itemId']),
      currentStock: _parseToString(json['currentStock']),
      minLevel: _parseToString(json['minLevel']),
      qtyNeeded: _parseToString(json['qtyNeeded']),
      qtyApproved: json['qtyApproved'] != null
          ? _parseToString(json['qtyApproved'])
          : null,
      qtyReceived: json['qtyReceived'] != null
          ? _parseToString(json['qtyReceived'])
          : null,
      unitCost: _parseToString(json['unitCost']),
      totalCost: _parseToString(json['totalCost']),
      status: _parseToString(json['status']),
      createdAt: _parseToString(json['createdAt']),
      updatedAt: _parseToString(json['updatedAt']),
      item: ItemInfo.fromJson(_asMap(json['item'])),
    );
  }

  // Helper method to safely convert any type to String
  static String _parseToString(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    if (value is bool) return value.toString();
    return value.toString();
  }

  double get unitCostDouble => double.tryParse(unitCost) ?? 0.0;
  double get totalCostDouble => double.tryParse(totalCost) ?? 0.0;
  double get qtyNeededValue => double.tryParse(qtyNeeded) ?? 0.0;
  double get currentStockValue => double.tryParse(currentStock) ?? 0.0;
  double get minLevelValue => double.tryParse(minLevel) ?? 0.0;
  double? get qtyApprovedValue =>
      qtyApproved != null ? double.tryParse(qtyApproved!) : null;
  double? get qtyReceivedValue =>
      qtyReceived != null ? double.tryParse(qtyReceived!) : null;
}

class ItemInfo {
  final String itemName;
  final String unit;

  ItemInfo({required this.itemName, required this.unit});

  factory ItemInfo.fromJson(Map<String, dynamic> json) {
    return ItemInfo(
      itemName: _parseToString(json['itemName']),
      unit: _parseToString(json['unit']),
    );
  }

  // Helper method to safely convert any type to String
  static String _parseToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    if (value is bool) return value.toString();
    return value.toString();
  }
}

class BranchInfo {
  final String name;
  final String branchCode;

  BranchInfo({required this.name, required this.branchCode});

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      name: _parseToString(json['name']),
      branchCode: _parseToString(json['branch_code'] ?? json['branchCode']),
    );
  }

  // Helper method to safely convert any type to String
  static String _parseToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    if (value is bool) return value.toString();
    return value.toString();
  }
}

String _string(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return fallback;
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
