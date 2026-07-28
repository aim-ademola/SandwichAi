// data/model/goods_received_model.dart

class GoodsReceivedItem {
  final String itemId;
  final String itemName;
  final double orderedQty;
  final double receivedQty;
  final bool qualityCheck;
  final String qcStatus;
  final String? qcNote;
  final String? expiryDate;

  GoodsReceivedItem({
    required this.itemId,
    required this.itemName,
    required this.orderedQty,
    required this.receivedQty,
    required this.qualityCheck,
    required this.qcStatus,
    this.qcNote,
    this.expiryDate,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'itemName': itemName,
    'orderedQty': orderedQty,
    'receivedQty': receivedQty,
    'qualityCheck': qualityCheck,
    'qcStatus': qcStatus,
    'qcNote': qcNote,
    'expiryDate': expiryDate,
  };

  factory GoodsReceivedItem.fromJson(
    Map<String, dynamic> json,
  ) => GoodsReceivedItem(
    itemId: _string(json['itemId'] ?? json['inventoryItemId']),
    itemName: _string(json['itemName'] ?? json['name']),
    orderedQty: _double(json['orderedQty'] ?? json['quantityOrdered']),
    receivedQty: _double(json['receivedQty'] ?? json['quantityReceived']),
    qualityCheck: json['qualityCheck'] == true,
    qcStatus: _string(json['qcStatus']),
    qcNote: _nullableString(json['qcNote']),
    expiryDate: _nullableString(json['expiryDate']),
  );
}

class CreateGoodsReceivedRequest {
  final String branchId;
  final String? purchaseOrderId;
  final String? stockRequestId;
  final String supplierName;
  final String invoiceNo;
  final String poNumber;
  final String receivedBy;
  final String inspectedBy;
  final String qualityNotes;
  final bool? isFinalDelivery;
  final List<GoodsReceivedItem> items;

  CreateGoodsReceivedRequest({
    required this.branchId,
    this.purchaseOrderId,
    this.stockRequestId,
    required this.supplierName,
    required this.invoiceNo,
    required this.poNumber,
    required this.receivedBy,
    required this.inspectedBy,
    required this.qualityNotes,
    this.isFinalDelivery,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'branchId': branchId,
    if (purchaseOrderId != null && purchaseOrderId!.isNotEmpty)
      'purchaseOrderId': purchaseOrderId,
    if (stockRequestId != null && stockRequestId!.isNotEmpty)
      'stockRequestId': stockRequestId,
    'supplierName': supplierName,
    'invoiceNo': invoiceNo,
    'poNumber': poNumber,
    'receivedBy': receivedBy,
    'inspectedBy': inspectedBy,
    'qualityNotes': qualityNotes,
    if (isFinalDelivery != null) 'isFinalDelivery': isFinalDelivery,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class GoodsReceivedBranch {
  final String name;
  final String branchCode;

  GoodsReceivedBranch({required this.name, required this.branchCode});

  factory GoodsReceivedBranch.fromJson(Map<String, dynamic> json) =>
      GoodsReceivedBranch(
        name: _string(json['name']),
        branchCode: _string(json['branch_code'] ?? json['branchCode']),
      );
}

class GoodsReceived {
  final String id;
  final String receiptNo;
  final String branchId;
  final String? purchaseOrderId;
  final String? stockRequestId;
  final String organizationId;
  final String supplierName;
  final String invoiceNo;
  final String poNumber;
  final String receivedBy;
  final String inspectedBy;
  final int totalItems;
  final int passedQC;
  final int failedQC;
  final String qualityNotes;
  final DateTime receivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GoodsReceivedItem> items;
  final GoodsReceivedBranch? branch;

  GoodsReceived({
    required this.id,
    required this.receiptNo,
    required this.branchId,
    this.purchaseOrderId,
    this.stockRequestId,
    required this.organizationId,
    required this.supplierName,
    required this.invoiceNo,
    required this.poNumber,
    required this.receivedBy,
    required this.inspectedBy,
    required this.totalItems,
    required this.passedQC,
    required this.failedQC,
    required this.qualityNotes,
    required this.receivedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.branch,
  });

  factory GoodsReceived.fromJson(Map<String, dynamic> json) => GoodsReceived(
    id: _string(json['id']),
    receiptNo: _string(json['receiptNo'] ?? json['receiptNumber']),
    branchId: _string(json['branchId']),
    purchaseOrderId: _nullableString(json['purchaseOrderId']),
    stockRequestId: _nullableString(json['stockRequestId']),
    organizationId: _string(json['organizationId']),
    supplierName: _string(json['supplierName']),
    invoiceNo: _string(json['invoiceNo']),
    poNumber: _string(json['poNumber']),
    receivedBy: _string(json['receivedBy']),
    inspectedBy: _string(json['inspectedBy']),
    totalItems: _int(json['totalItems']),
    passedQC: _int(json['passedQC']),
    failedQC: _int(json['failedQC']),
    qualityNotes: _string(json['qualityNotes']),
    receivedAt: _date(json['receivedAt'] ?? json['createdAt']),
    createdAt: _date(json['createdAt'] ?? json['receivedAt']),
    updatedAt: _date(json['updatedAt'] ?? json['createdAt']),
    items:
        (json['items'] as List?)
            ?.whereType<Map>()
            .map(
              (item) =>
                  GoodsReceivedItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList() ??
        [],
    branch: json['branch'] != null
        ? GoodsReceivedBranch.fromJson(_asMap(json['branch']))
        : null,
  );
}

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final String unit;
  final String description;
  final String sku;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.description,
    required this.sku,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'] ?? '',
    name: json['itemName'] ?? '',
    category: json['category'] ?? '',
    unit: json['unit'] ?? '',
    description: json['description'] ?? '',
    sku: json['sku'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemName': name,
    'category': category,
    'unit': unit,
    'description': description,
    'sku': sku,
  };
}

class UpdateGoodsReceivedQcRequest {
  final String qcStatus;
  final String inspectedBy;
  final String? qcNote;
  final List<GoodsReceivedQcItem>? items;

  const UpdateGoodsReceivedQcRequest({
    required this.qcStatus,
    required this.inspectedBy,
    this.qcNote,
    this.items,
  });

  Map<String, dynamic> toJson() => {
    'qcStatus': qcStatus,
    'inspectedBy': inspectedBy,
    if (qcNote != null) 'qcNote': qcNote,
    if (items != null) 'items': items!.map((item) => item.toJson()).toList(),
  };
}

class GoodsReceivedQcItem {
  final String itemId;
  final String qcStatus;
  final bool qualityCheck;
  final String? qcNote;

  const GoodsReceivedQcItem({
    required this.itemId,
    required this.qcStatus,
    required this.qualityCheck,
    this.qcNote,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'qcStatus': qcStatus,
    'qualityCheck': qualityCheck,
    if (qcNote != null) 'qcNote': qcNote,
  };
}

class GoodsReceivedPrefillResponse {
  final String purchaseOrderId;
  final String poNumber;
  final String supplierName;
  final String branchId;
  final List<GoodsReceivedItem> items;
  final Map<String, dynamic> raw;

  const GoodsReceivedPrefillResponse({
    required this.purchaseOrderId,
    required this.poNumber,
    required this.supplierName,
    required this.branchId,
    required this.items,
    required this.raw,
  });

  factory GoodsReceivedPrefillResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']).isNotEmpty ? _asMap(json['data']) : json;
    return GoodsReceivedPrefillResponse(
      purchaseOrderId: _string(
        data['purchaseOrderId'] ?? data['poId'] ?? data['id'],
      ),
      poNumber: _string(data['poNumber'] ?? data['orderNumber']),
      supplierName: _string(data['supplierName']),
      branchId: _string(data['branchId']),
      items: (_extractList(data).whereType<Map>().map((item) {
        final map = Map<String, dynamic>.from(item);
        return GoodsReceivedItem.fromJson({
          ...map,
          'orderedQty': map['orderedQty'] ?? map['quantityOrdered'],
          'receivedQty': map['receivedQty'] ?? map['quantityOrdered'],
          'qualityCheck': map['qualityCheck'] ?? false,
          'qcStatus': map['qcStatus'] ?? '',
        });
      }).toList()),
      raw: json,
    );
  }
}

class PurchaseOrderDeliveryStatusResponse {
  final String purchaseOrderId;
  final String deliveryStatus;
  final double orderedQty;
  final double receivedQty;
  final double pendingQty;
  final bool isComplete;
  final Map<String, dynamic> raw;

  const PurchaseOrderDeliveryStatusResponse({
    required this.purchaseOrderId,
    required this.deliveryStatus,
    required this.orderedQty,
    required this.receivedQty,
    required this.pendingQty,
    required this.isComplete,
    required this.raw,
  });

  factory PurchaseOrderDeliveryStatusResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = _asMap(json['data']).isNotEmpty ? _asMap(json['data']) : json;
    return PurchaseOrderDeliveryStatusResponse(
      purchaseOrderId: _string(
        data['purchaseOrderId'] ?? data['poId'] ?? data['id'],
      ),
      deliveryStatus: _string(data['deliveryStatus'] ?? data['status']),
      orderedQty: _double(data['orderedQty'] ?? data['totalOrdered']),
      receivedQty: _double(data['receivedQty'] ?? data['totalReceived']),
      pendingQty: _double(data['pendingQty'] ?? data['remainingQty']),
      isComplete: data['isComplete'] == true || data['complete'] == true,
      raw: json,
    );
  }
}

class GoodsReceivedQcStats {
  final int totalInspected;
  final int passed;
  final int failed;
  final double passRate;
  final Map<String, dynamic> raw;

  const GoodsReceivedQcStats({
    required this.totalInspected,
    required this.passed,
    required this.failed,
    required this.passRate,
    required this.raw,
  });

  factory GoodsReceivedQcStats.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']).isNotEmpty ? _asMap(json['data']) : json;
    return GoodsReceivedQcStats(
      totalInspected: _int(data['totalInspected'] ?? data['totalItems']),
      passed: _int(data['passed'] ?? data['passedQC']),
      failed: _int(data['failed'] ?? data['failedQC']),
      passRate: _double(data['passRate'] ?? data['qualityPassRate']),
      raw: json,
    );
  }
}

List<dynamic> _extractList(Map<String, dynamic> json) {
  for (final key in const ['items', 'data', 'results']) {
    final value = json[key];
    if (value is List) return value;
  }
  final data = json['data'];
  if (data is Map) {
    for (final key in const ['items', 'results']) {
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

String? _nullableString(dynamic value) {
  final parsed = _string(value);
  return parsed.isEmpty ? null : parsed;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _date(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
