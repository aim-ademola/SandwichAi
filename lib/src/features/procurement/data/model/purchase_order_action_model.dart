class PurchaseOrderActionResponse {
  final bool success;
  final String message;
  final Map<String, dynamic> data;
  final Map<String, dynamic> raw;

  const PurchaseOrderActionResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.raw,
  });

  factory PurchaseOrderActionResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    return PurchaseOrderActionResponse(
      success: json['success'] == true || _string(json['message']).isNotEmpty,
      message: _string(json['message']),
      data: data.isNotEmpty ? data : json,
      raw: json,
    );
  }
}

class PurchaseOrderApprovalStatus {
  final String orderId;
  final String status;
  final String approvalStatus;
  final String currentApprover;
  final List<Map<String, dynamic>> approvals;
  final Map<String, dynamic> raw;

  const PurchaseOrderApprovalStatus({
    required this.orderId,
    required this.status,
    required this.approvalStatus,
    required this.currentApprover,
    required this.approvals,
    required this.raw,
  });

  factory PurchaseOrderApprovalStatus.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']).isNotEmpty ? _asMap(json['data']) : json;
    final approvals = data['approvals'] is List
        ? (data['approvals'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    return PurchaseOrderApprovalStatus(
      orderId: _string(
        data['orderId'] ?? data['purchaseOrderId'] ?? data['id'],
      ),
      status: _string(data['status']),
      approvalStatus: _firstString([
        data['approvalStatus'],
        data['approval_status'],
        data['approvalState'],
        data['approval_state'],
        data['currentApprovalStatus'],
        data['current_approval_status'],
        _nestedValue(data, const ['approval', 'status']),
        _nestedValue(data, const ['approval', 'approvalStatus']),
        _nestedValue(data, const ['purchaseOrder', 'approvalStatus']),
        _nestedValue(data, const ['purchaseOrder', 'approval_status']),
        data['status'],
      ]),
      currentApprover: _firstString([
        data['currentApprover'],
        data['current_approver'],
        data['approver'],
        data['approverName'],
        _nestedValue(data, const ['currentApproval', 'approver']),
        _nestedValue(data, const ['approval', 'currentApprover']),
      ]),
      approvals: approvals,
      raw: json,
    );
  }
}

class PurchaseOrderDispatchRequest {
  final String dispatchedBy;
  final String? trackingNumber;
  final String? courierName;
  final String? dispatchNote;

  const PurchaseOrderDispatchRequest({
    required this.dispatchedBy,
    this.trackingNumber,
    this.courierName,
    this.dispatchNote,
  });

  Map<String, dynamic> toJson() => {
    'dispatchedBy': dispatchedBy,
    if (trackingNumber != null) 'trackingNumber': trackingNumber,
    if (courierName != null) 'courierName': courierName,
    if (dispatchNote != null) 'dispatchNote': dispatchNote,
  };
}

class SubmitPurchaseOrderApprovalRequest {
  final String submittedBy;
  final String? note;

  const SubmitPurchaseOrderApprovalRequest({
    required this.submittedBy,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'submittedBy': submittedBy,
    if (note != null) 'note': note,
  };
}

class BulkCreatePurchaseOrdersRequest {
  final List<Map<String, dynamic>> orders;

  const BulkCreatePurchaseOrdersRequest({required this.orders});

  Map<String, dynamic> toJson() => {'orders': orders};
}

class PurchaseOrderTimelineResponse {
  final List<Map<String, dynamic>> events;
  final Map<String, dynamic> raw;

  const PurchaseOrderTimelineResponse({
    required this.events,
    required this.raw,
  });

  factory PurchaseOrderTimelineResponse.fromJson(Map<String, dynamic> json) {
    final list = _extractList(json);
    return PurchaseOrderTimelineResponse(
      events: list
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      raw: json,
    );
  }
}

List<dynamic> _extractList(Map<String, dynamic> json) {
  for (final key in const ['data', 'items', 'results', 'events', 'timeline']) {
    final value = json[key];
    if (value is List) return value;
  }
  final data = json['data'];
  if (data is Map) {
    for (final key in const ['items', 'results', 'events', 'timeline']) {
      final value = data[key];
      if (value is List) return value;
    }
  }
  return const [];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _string(dynamic value) => value?.toString() ?? '';

String _firstString(List<dynamic> values) {
  for (final value in values) {
    final text = _string(value).trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

dynamic _nestedValue(Map<String, dynamic> source, List<String> path) {
  dynamic current = source;
  for (final key in path) {
    if (current is! Map) return null;
    current = current[key];
  }
  return current;
}
