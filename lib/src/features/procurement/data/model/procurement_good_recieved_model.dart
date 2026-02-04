// data/model/goods_received_model.dart

class GoodsReceivedItem {
  final String itemId;
  final String itemName;
  final int orderedQty;
  final int receivedQty;
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

  factory GoodsReceivedItem.fromJson(Map<String, dynamic> json) =>
      GoodsReceivedItem(
        itemId: json['itemId'] ?? '',
        itemName: json['itemName'] ?? '',
        orderedQty: int.tryParse(json['orderedQty']?.toString() ?? '0') ?? 0,
        receivedQty: int.tryParse(json['receivedQty']?.toString() ?? '0') ?? 0,
        qualityCheck: json['qualityCheck'] ?? false,
        qcStatus: json['qcStatus'] ?? '',
        qcNote: json['qcNote'],
        expiryDate: json['expiryDate'],
      );
}

class CreateGoodsReceivedRequest {
  final String branchId;
  final String supplierName;
  final String invoiceNo;
  final String poNumber;
  final String receivedBy;
  final String inspectedBy;
  final String qualityNotes;
  final List<GoodsReceivedItem> items;

  CreateGoodsReceivedRequest({
    required this.branchId,
    required this.supplierName,
    required this.invoiceNo,
    required this.poNumber,
    required this.receivedBy,
    required this.inspectedBy,
    required this.qualityNotes,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'branchId': branchId,
    'supplierName': supplierName,
    'invoiceNo': invoiceNo,
    'poNumber': poNumber,
    'receivedBy': receivedBy,
    'inspectedBy': inspectedBy,
    'qualityNotes': qualityNotes,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class GoodsReceivedBranch {
  final String name;
  final String branchCode;

  GoodsReceivedBranch({required this.name, required this.branchCode});

  factory GoodsReceivedBranch.fromJson(Map<String, dynamic> json) =>
      GoodsReceivedBranch(
        name: json['name'] ?? '',
        branchCode: json['branch_code'] ?? '',
      );
}

class GoodsReceived {
  final String id;
  final String receiptNo;
  final String branchId;
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
    id: json['id'] ?? '',
    receiptNo: json['receiptNo'] ?? '',
    branchId: json['branchId'] ?? '',
    organizationId: json['organizationId'] ?? '',
    supplierName: json['supplierName'] ?? '',
    invoiceNo: json['invoiceNo'] ?? '',
    poNumber: json['poNumber'] ?? '',
    receivedBy: json['receivedBy'] ?? '',
    inspectedBy: json['inspectedBy'] ?? '',
    totalItems: json['totalItems'] ?? 0,
    passedQC: json['passedQC'] ?? 0,
    failedQC: json['failedQC'] ?? 0,
    qualityNotes: json['qualityNotes'] ?? '',
    receivedAt: DateTime.parse(json['receivedAt']),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    items:
        (json['items'] as List?)
            ?.map((item) => GoodsReceivedItem.fromJson(item))
            .toList() ??
        [],
    branch: json['branch'] != null
        ? GoodsReceivedBranch.fromJson(json['branch'])
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
