// Models
class PurchaseOrder {
  final String id;
  final String orderNumber;
  final String buyerId;
  final String buyerBranchId;
  final String supplierId;
  final String? buyerEmail;
  final String? buyerPhone;
  final String status;
  final String priority;
  final DateTime orderDate;
  final DateTime expectedDeliveryDate;
  final DateTime? confirmedDeliveryDate;
  final DateTime? actualDeliveryDate;
  final String? availabilityStatus;
  final double subtotal;
  final double tax;
  final double totalAmount;
  final String currency;
  final String paymentTerm;
  final String paymentStatus;
  final DateTime? paymentDueDate;
  final String deliveryAddress;
  final String deliveryCity;
  final String deliveryState;
  final String? deliveryZipCode;
  final String? deliveryInstructions;
  final String? deliveryStatus;
  final String? trackingNumber;
  final String? courierName;
  final DateTime? acceptedAt;
  final String? acceptedBy;
  final DateTime? declinedAt;
  final String? declinedBy;
  final String? declineReason;
  final String? alternativeSuggestions;
  final DateTime? completedAt;
  final String? confirmedBy;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final String? buyerNotes;
  final String? supplierNotes;
  final String? internalNotes;
  final List<String>? attachments;
  final String? qcStatus;
  final String? qcNotes;
  final String? qcPerformedBy;
  final DateTime? qcPerformedAt;
  final bool? isEarlyDelivery;
  final bool? isOnTimeDelivery;
  final bool? isLateDelivery;
  final String? primaryCategory;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final SupplierInfo supplier;

  PurchaseOrder({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.buyerBranchId,
    required this.supplierId,
    this.buyerEmail,
    this.buyerPhone,
    required this.status,
    required this.priority,
    required this.orderDate,
    required this.expectedDeliveryDate,
    this.confirmedDeliveryDate,
    this.actualDeliveryDate,
    this.availabilityStatus,
    required this.subtotal,
    required this.tax,
    required this.totalAmount,
    required this.currency,
    required this.paymentTerm,
    required this.paymentStatus,
    this.paymentDueDate,
    required this.deliveryAddress,
    required this.deliveryCity,
    required this.deliveryState,
    this.deliveryZipCode,
    this.deliveryInstructions,
    this.deliveryStatus,
    this.trackingNumber,
    this.courierName,
    this.acceptedAt,
    this.acceptedBy,
    this.declinedAt,
    this.declinedBy,
    this.declineReason,
    this.alternativeSuggestions,
    this.completedAt,
    this.confirmedBy,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
    this.buyerNotes,
    this.supplierNotes,
    this.internalNotes,
    this.attachments,
    this.qcStatus,
    this.qcNotes,
    this.qcPerformedBy,
    this.qcPerformedAt,
    this.isEarlyDelivery,
    this.isOnTimeDelivery,
    this.isLateDelivery,
    this.primaryCategory,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.supplier,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      buyerId: json['buyerId'] as String,
      buyerBranchId: json['buyerBranchId'] as String,
      supplierId: json['supplierId'] as String,
      buyerEmail: json['buyerEmail'] as String?,
      buyerPhone: json['buyerPhone'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String,
      orderDate: DateTime.parse(json['orderDate'] as String),
      expectedDeliveryDate: DateTime.parse(
        json['expectedDeliveryDate'] as String,
      ),
      confirmedDeliveryDate: json['confirmedDeliveryDate'] != null
          ? DateTime.parse(json['confirmedDeliveryDate'] as String)
          : null,
      actualDeliveryDate: json['actualDeliveryDate'] != null
          ? DateTime.parse(json['actualDeliveryDate'] as String)
          : null,
      availabilityStatus: json['availabilityStatus'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      currency: json['currency'] as String,
      paymentTerm: json['paymentTerm'] as String,
      paymentStatus: json['paymentStatus'] as String,
      paymentDueDate: json['paymentDueDate'] != null
          ? DateTime.parse(json['paymentDueDate'] as String)
          : null,
      deliveryAddress: json['deliveryAddress'] as String,
      deliveryCity: json['deliveryCity'] as String,
      deliveryState: json['deliveryState'] as String,
      deliveryZipCode: json['deliveryZipCode'] as String?,
      deliveryInstructions: json['deliveryInstructions'] as String?,
      deliveryStatus: json['deliveryStatus'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      courierName: json['courierName'] as String?,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      acceptedBy: json['acceptedBy'] as String?,
      declinedAt: json['declinedAt'] != null
          ? DateTime.parse(json['declinedAt'] as String)
          : null,
      declinedBy: json['declinedBy'] as String?,
      declineReason: json['declineReason'] as String?,
      alternativeSuggestions: json['alternativeSuggestions'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      confirmedBy: json['confirmedBy'] as String?,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancelledBy: json['cancelledBy'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      buyerNotes: json['buyerNotes'] as String?,
      supplierNotes: json['supplierNotes'] as String?,
      internalNotes: json['internalNotes'] as String?,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : null,
      qcStatus: json['qcStatus'] as String?,
      qcNotes: json['qcNotes'] as String?,
      qcPerformedBy: json['qcPerformedBy'] as String?,
      qcPerformedAt: json['qcPerformedAt'] != null
          ? DateTime.parse(json['qcPerformedAt'] as String)
          : null,
      isEarlyDelivery: json['isEarlyDelivery'] as bool?,
      isOnTimeDelivery: json['isOnTimeDelivery'] as bool?,
      isLateDelivery: json['isLateDelivery'] as bool?,
      primaryCategory: json['primaryCategory'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      supplier: SupplierInfo.fromJson(json['supplier'] as Map<String, dynamic>),
    );
  }
}

class OrderItem {
  final String id;
  final String purchaseOrderId;
  final String productId;
  final String productName;
  final String productCode;
  final String? productImage;
  final double quantityOrdered;
  final String unit;
  final double unitPrice;
  final double tax;
  final double totalPrice;
  final String status;
  final String? notes;

  OrderItem({
    required this.id,
    required this.purchaseOrderId,
    required this.productId,
    required this.productName,
    required this.productCode,
    this.productImage,
    required this.quantityOrdered,
    required this.unit,
    required this.unitPrice,
    required this.tax,
    required this.totalPrice,
    required this.status,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      purchaseOrderId: json['purchaseOrderId'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productCode: json['productCode'] as String,
      productImage: json['productImage'] as String?,
      quantityOrdered: (json['quantityOrdered'] as num).toDouble(),
      unit: json['unit'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );
  }
}

class SupplierInfo {
  final String id;
  final String supplierId;
  final String businessName;
  final String email;
  final String phone;
  final double? averageRating;
  final double? onTimeDeliveryRate;

  SupplierInfo({
    required this.id,
    required this.supplierId,
    required this.businessName,
    required this.email,
    required this.phone,
    this.averageRating,
    this.onTimeDeliveryRate,
  });

  factory SupplierInfo.fromJson(Map<String, dynamic> json) {
    return SupplierInfo(
      id: json['id'] as String,
      supplierId: json['supplierId'] as String,
      businessName: json['businessName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      averageRating: json['averageRating'] != null
          ? (json['averageRating'] as num).toDouble()
          : null,
      onTimeDeliveryRate: json['onTimeDeliveryRate'] != null
          ? (json['onTimeDeliveryRate'] as num).toDouble()
          : null,
    );
  }
}

class OrdersListResponse {
  final List<PurchaseOrder> orders;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  OrdersListResponse({
    required this.orders,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory OrdersListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final payload = data is Map ? Map<String, dynamic>.from(data) : json;
    final rawOrders =
        (data is List ? data : payload['items'] ?? payload['orders'])
            as List? ??
        const [];
    final meta = Map<String, dynamic>.from(
      (json['meta'] as Map?) ?? (payload['meta'] as Map?) ?? payload,
    );
    final total = _parseInt(
      meta['total'] ?? meta['totalItems'],
      rawOrders.length,
    );
    final page = _parseInt(meta['page'] ?? meta['currentPage'], 1);
    final limit = _parseInt(meta['limit'] ?? meta['perPage'], rawOrders.length);
    final totalPages = _parseInt(meta['totalPages'] ?? meta['lastPage'], 1);

    return OrdersListResponse(
      orders: rawOrders
          .whereType<Map>()
          .map(
            (order) => PurchaseOrder.fromJson(Map<String, dynamic>.from(order)),
          )
          .toList(),
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
      hasNextPage:
          meta['hasNextPage'] as bool? ?? (totalPages > 0 && page < totalPages),
      hasPreviousPage: meta['hasPreviousPage'] as bool? ?? page > 1,
    );
  }
}

int _parseInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
