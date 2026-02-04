// lib/src/features/stock_control/data/model/processing_transfer_model.dart

class ProcessingTransferRequest {
  final String branchId;
  final String batchCode;
  final String sentBy;
  final List<TransferItem> items;
  final String? notes;

  ProcessingTransferRequest({
    required this.branchId,
    required this.batchCode,
    required this.sentBy,
    required this.items,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'batchCode': batchCode,
      'sentBy': sentBy,
      'items': items.map((item) => item.toJson()).toList(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

class TransferItem {
  final String itemId;
  final int qtySent;

  TransferItem({required this.itemId, required this.qtySent});

  Map<String, dynamic> toJson() {
    return {'itemId': itemId, 'qtySent': qtySent};
  }
}

class ProcessingTransferResponse {
  final String id;
  final String transferId;
  final String branchId;
  final String organizationId;
  final String batchCode;
  final String sentBy;
  final DateTime sentAt;
  final String? receivedBy;
  final DateTime? receivedAt;
  final String status;
  final bool qualityCheck;
  final String? varianceNote;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProcessingTransferItemResponse> items;
  final BranchInfo branch;

  ProcessingTransferResponse({
    required this.id,
    required this.transferId,
    required this.branchId,
    required this.organizationId,
    required this.batchCode,
    required this.sentBy,
    required this.sentAt,
    this.receivedBy,
    this.receivedAt,
    required this.status,
    required this.qualityCheck,
    this.varianceNote,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.branch,
  });

  factory ProcessingTransferResponse.fromJson(Map<String, dynamic> json) {
    return ProcessingTransferResponse(
      id: json['id'] as String,
      transferId: json['transferId'] as String,
      branchId: json['branchId'] as String,
      organizationId: json['organizationId'] as String,
      batchCode: json['batchCode'] as String,
      sentBy: json['sentBy'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      receivedBy: json['receivedBy'] as String?,
      receivedAt: json['receivedAt'] != null
          ? DateTime.parse(json['receivedAt'] as String)
          : null,
      status: json['status'] as String,
      qualityCheck: json['qualityCheck'] as bool,
      varianceNote: json['varianceNote'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      items: (json['items'] as List)
          .map((item) => ProcessingTransferItemResponse.fromJson(item))
          .toList(),
      branch: BranchInfo.fromJson(json['branch']),
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isInTransit => status == 'IN_TRANSIT';
  bool get isReceived => status == 'RECEIVED';
  bool get isRejected => status == 'REJECTED';
  bool get isCompleted => isReceived || isRejected;
}

class ProcessingTransferItemResponse {
  final String id;
  final String transferId;
  final String itemId;
  final String qtySent;
  final String? qtyReceived;
  final String? variance;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ItemInfo item;

  ProcessingTransferItemResponse({
    required this.id,
    required this.transferId,
    required this.itemId,
    required this.qtySent,
    this.qtyReceived,
    this.variance,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.item,
  });

  factory ProcessingTransferItemResponse.fromJson(Map<String, dynamic> json) {
    return ProcessingTransferItemResponse(
      id: json['id'] as String,
      transferId: json['transferId'] as String,
      itemId: json['itemId'] as String,
      qtySent: json['qtySent'] as String,
      qtyReceived: json['qtyReceived'] as String?,
      variance: json['variance'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      item: ItemInfo.fromJson(json['item']),
    );
  }
}

class ItemInfo {
  final String id;
  final String itemName;
  final String category;
  final String unit;
  final String description;
  final String sku;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemInfo({
    required this.id,
    required this.itemName,
    required this.category,
    required this.unit,
    required this.description,
    required this.sku,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemInfo.fromJson(Map<String, dynamic> json) {
    return ItemInfo(
      id: json['id'] as String,
      itemName: json['itemName'] as String,
      category: json['category'] as String,
      unit: json['unit'] as String,
      description: json['description'] as String,
      sku: json['sku'] as String,
      organizationId: json['organizationId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class BranchInfo {
  final String id;
  final String name;
  final String branchCode;
  final String address;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final String email;

  BranchInfo({
    required this.id,
    required this.name,
    required this.branchCode,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
    required this.email,
  });

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      branchCode: json['branch_code'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      country: json['country'] as String,
      zipCode: json['zipCode'] as String,
      email: json['email'] as String,
    );
  }
}

class ReceiveTransferRequest {
  final String receivedBy;
  final List<ReceiveTransferItem> items;
  final bool qualityCheck;
  final String? varianceNote;

  ReceiveTransferRequest({
    required this.receivedBy,
    required this.items,
    this.qualityCheck = true,
    this.varianceNote,
  });

  Map<String, dynamic> toJson() => {
    'receivedBy': receivedBy,
    'items': items.map((item) => item.toJson()).toList(),
    'qualityCheck': qualityCheck,
    if (varianceNote != null && varianceNote!.isNotEmpty)
      'varianceNote': varianceNote,
  };
}

class ReceiveTransferItem {
  final String itemId;
  final int qtyReceived;

  ReceiveTransferItem({required this.itemId, required this.qtyReceived});

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'qtyReceived': qtyReceived,
  };
}
