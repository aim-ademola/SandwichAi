class ItemBranchAssignment {
  final String id;
  final String branchId;
  final String branchName;
  final String branchCode;
  final String status;
  final String notes;
  final Map<String, dynamic> raw;

  const ItemBranchAssignment({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.branchCode,
    required this.status,
    required this.notes,
    required this.raw,
  });

  factory ItemBranchAssignment.fromJson(Map<String, dynamic> json) {
    final branch = _asMap(json['branch']);
    final source = branch.isNotEmpty ? branch : json;

    return ItemBranchAssignment(
      id: _string(json['id'] ?? json['assignmentId']),
      branchId: _string(
        json['branchId'] ?? source['id'] ?? source['branchId'],
      ),
      branchName: _string(
        source['name'] ??
            source['branchName'] ??
            source['branch_name'] ??
            json['branchName'],
      ),
      branchCode: _string(
        source['branchCode'] ??
            source['branch_code'] ??
            source['code'] ??
            json['branchCode'],
      ),
      status: _string(json['status'] ?? source['status']),
      notes: _string(json['notes'] ?? json['note']),
      raw: json,
    );
  }
}

class ItemBranchAssignmentsResponse {
  final List<ItemBranchAssignment> assignments;
  final Map<String, dynamic> raw;

  const ItemBranchAssignmentsResponse({
    required this.assignments,
    required this.raw,
  });

  factory ItemBranchAssignmentsResponse.fromJson(Map<String, dynamic> json) {
    final list = _extractList(json);
    return ItemBranchAssignmentsResponse(
      assignments: list
          .whereType<Map>()
          .map((item) => ItemBranchAssignment.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      raw: json,
    );
  }
}

List<dynamic> _extractList(Map<String, dynamic> json) {
  for (final key in const [
    'data',
    'items',
    'branches',
    'assignments',
    'results',
  ]) {
    final value = json[key];
    if (value is List) return value;
  }

  final data = json['data'];
  if (data is Map) {
    for (final key in const ['items', 'branches', 'assignments', 'results']) {
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

String _string(dynamic value) {
  if (value == null) return '';
  final text = value.toString().trim();
  if (text.toLowerCase() == 'null') return '';
  return text;
}
