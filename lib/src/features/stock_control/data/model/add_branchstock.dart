class BranchStockRequest {
  final String itemId;
  final String branchId;
  final double currentStock;
  final double reorderLevel;
  final double maxLevel;
  final double unitCost;
  final String expiryDate;

  BranchStockRequest({
    required this.itemId,
    required this.branchId,
    required this.currentStock,
    required this.reorderLevel,
    required this.maxLevel,
    required this.unitCost,
    required this.expiryDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'branchId': branchId,
      'currentStock': currentStock,
      'reorderLevel': reorderLevel,
      'maxLevel': maxLevel,
      'unitCost': unitCost,
      'expiryDate': expiryDate,
    };
  }

  factory BranchStockRequest.fromJson(Map<String, dynamic> json) {
    return BranchStockRequest(
      itemId: json['itemId'] as String,
      branchId: json['branchId'] as String,
      currentStock: (json['currentStock'] as num).toDouble(),
      reorderLevel: (json['reorderLevel'] as num).toDouble(),
      maxLevel: (json['maxLevel'] as num).toDouble(),
      unitCost: (json['unitCost'] as num).toDouble(),
      expiryDate: json['expiryDate'] as String,
    );
  }
}

class BranchStockResponse {
  final String message;
  final bool success;
  final dynamic data;

  BranchStockResponse({
    required this.message,
    required this.success,
    this.data,
  });

  factory BranchStockResponse.fromJson(Map<String, dynamic> json) {
    return BranchStockResponse(
      message: json['message'] as String? ?? 'Operation completed',
      success: json['success'] as bool? ?? true,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'success': success, 'data': data};
  }

  bool get isValid => success && message.isNotEmpty;

  // Helper getters to extract data if needed
  String? get id => data is Map ? data['id'] as String? : null;
  String? get itemId => data is Map ? data['itemId'] as String? : null;
  String? get branchId => data is Map ? data['branchId'] as String? : null;
  double? get currentStock =>
      data is Map ? (data['currentStock'] as num?)?.toDouble() : null;
  double? get reorderLevel =>
      data is Map ? (data['reorderLevel'] as num?)?.toDouble() : null;
  double? get maxLevel =>
      data is Map ? (data['maxLevel'] as num?)?.toDouble() : null;
  double? get unitCost =>
      data is Map ? (data['unitCost'] as num?)?.toDouble() : null;
  String? get expiryDate => data is Map ? data['expiryDate'] as String? : null;
}
