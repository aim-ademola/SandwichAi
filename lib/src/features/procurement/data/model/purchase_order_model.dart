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
      id: _string(json['id']),
      orderNumber: _string(json['orderNumber'] ?? json['orderNo']),
      buyerId: _string(json['buyerId']),
      buyerBranchId: _string(json['buyerBranchId'] ?? json['branchId']),
      supplierId: _string(json['supplierId']),
      buyerEmail: _nullableString(json['buyerEmail']),
      buyerPhone: _nullableString(json['buyerPhone']),
      status: _string(json['status'], fallback: 'UNKNOWN'),
      priority: _string(json['priority'], fallback: 'NORMAL'),
      orderDate: _date(json['orderDate'] ?? json['createdAt']),
      expectedDeliveryDate: _date(
        json['expectedDeliveryDate'] ?? json['deliveryDate'],
      ),
      confirmedDeliveryDate: json['confirmedDeliveryDate'] != null
          ? _date(json['confirmedDeliveryDate'])
          : null,
      actualDeliveryDate: json['actualDeliveryDate'] != null
          ? _date(json['actualDeliveryDate'])
          : null,
      availabilityStatus: _nullableString(json['availabilityStatus']),
      subtotal: _double(json['subtotal']),
      tax: _double(json['tax']),
      totalAmount: _double(json['totalAmount'] ?? json['amount']),
      currency: _string(json['currency'], fallback: 'NGN'),
      paymentTerm: _string(json['paymentTerm']),
      paymentStatus: _string(json['paymentStatus'], fallback: 'PENDING'),
      paymentDueDate: json['paymentDueDate'] != null
          ? _date(json['paymentDueDate'])
          : null,
      deliveryAddress: _string(json['deliveryAddress']),
      deliveryCity: _string(json['deliveryCity']),
      deliveryState: _string(json['deliveryState']),
      deliveryZipCode: _nullableString(json['deliveryZipCode']),
      deliveryInstructions: _nullableString(json['deliveryInstructions']),
      deliveryStatus: _nullableString(json['deliveryStatus']),
      trackingNumber: _nullableString(json['trackingNumber']),
      courierName: _nullableString(json['courierName']),
      acceptedAt: json['acceptedAt'] != null ? _date(json['acceptedAt']) : null,
      acceptedBy: _nullableString(json['acceptedBy']),
      declinedAt: json['declinedAt'] != null ? _date(json['declinedAt']) : null,
      declinedBy: _nullableString(json['declinedBy']),
      declineReason: _nullableString(json['declineReason']),
      alternativeSuggestions: _nullableString(json['alternativeSuggestions']),
      completedAt: json['completedAt'] != null
          ? _date(json['completedAt'])
          : null,
      confirmedBy: _nullableString(json['confirmedBy']),
      cancelledAt: json['cancelledAt'] != null
          ? _date(json['cancelledAt'])
          : null,
      cancelledBy: _nullableString(json['cancelledBy']),
      cancellationReason: _nullableString(json['cancellationReason']),
      buyerNotes: _nullableString(json['buyerNotes']),
      supplierNotes: _nullableString(json['supplierNotes']),
      internalNotes: _nullableString(json['internalNotes']),
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : null,
      qcStatus: _nullableString(json['qcStatus']),
      qcNotes: _nullableString(json['qcNotes']),
      qcPerformedBy: _nullableString(json['qcPerformedBy']),
      qcPerformedAt: json['qcPerformedAt'] != null
          ? _date(json['qcPerformedAt'])
          : null,
      isEarlyDelivery: json['isEarlyDelivery'] as bool?,
      isOnTimeDelivery: json['isOnTimeDelivery'] as bool?,
      isLateDelivery: json['isLateDelivery'] as bool?,
      primaryCategory: _nullableString(json['primaryCategory']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt'] ?? json['createdAt']),
      items: _list(json['items'] ?? json['orderItems'])
          .whereType<Map>()
          .map((item) => OrderItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      supplier: SupplierInfo.fromJson(_map(json['supplier'])),
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
      id: _string(json['id']),
      purchaseOrderId: _string(json['purchaseOrderId']),
      productId: _string(json['productId']),
      productName: _string(json['productName']),
      productCode: _string(json['productCode']),
      productImage: _nullableString(json['productImage']),
      quantityOrdered: _double(json['quantityOrdered']),
      unit: _string(json['unit']),
      unitPrice: _double(json['unitPrice']),
      tax: _double(json['tax']),
      totalPrice: _double(json['totalPrice']),
      status: _string(json['status'], fallback: 'PENDING'),
      notes: _nullableString(json['notes']),
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
      id: _string(json['id']),
      supplierId: _string(json['supplierId']),
      businessName: _string(json['businessName'], fallback: 'Unknown Supplier'),
      email: _string(json['email']),
      phone: _string(json['phone']),
      averageRating: _nullableDouble(json['averageRating']),
      onTimeDeliveryRate: _nullableDouble(json['onTimeDeliveryRate']),
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
    final rawOrders = _extractOrdersList(data, payload);
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
          .map((order) => PurchaseOrder.fromJson(_purchaseOrderMap(order)))
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

List<dynamic> _extractOrdersList(dynamic data, Map<String, dynamic> payload) {
  if (data is List) return data;
  for (final key in const [
    'items',
    'orders',
    'records',
    'results',
    'purchaseOrders',
    'purchase_orders',
  ]) {
    final value = payload[key];
    if (value is List) return value;
  }
  return const [];
}

Map<String, dynamic> _purchaseOrderMap(Map order) {
  final map = Map<String, dynamic>.from(order);
  for (final key in const ['purchaseOrder', 'purchase_order', 'order']) {
    final nested = map[key];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
  }
  return map;
}

int _parseInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String _string(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

double _double(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime _date(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<dynamic> _list(dynamic value) {
  if (value is List) return value;
  return const <dynamic>[];
}
