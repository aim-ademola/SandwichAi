class BranchStockRequest {
  final String itemId;
  final String branchId;
  final int currentStock;
  final int reorderLevel;
  final int maxLevel;
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
      currentStock: json['currentStock'] as int,
      reorderLevel: json['reorderLevel'] as int,
      maxLevel: json['maxLevel'] as int,
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
  int? get currentStock => data is Map ? data['currentStock'] as int? : null;
  int? get reorderLevel => data is Map ? data['reorderLevel'] as int? : null;
  int? get maxLevel => data is Map ? data['maxLevel'] as int? : null;
  double? get unitCost =>
      data is Map ? (data['unitCost'] as num?)?.toDouble() : null;
  String? get expiryDate => data is Map ? data['expiryDate'] as String? : null;
}
