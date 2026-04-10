// data/model/kitchen_order_model.dart

class KitchenOrder {
  final String id;
  final String orderId;
  final String branchId;
  final String organizationId;
  final OrderType orderType;
  final OrderStatus status;
  final String? tableNumber;
  final String? customerName; // ← CHANGED: Made nullable
  final String? customerPhone; // ← CHANGED: Made nullable
  final DateTime orderedAt;
  final DateTime? confirmedAt;
  final DateTime? startedAt;
  final DateTime? readyAt;
  final DateTime? servedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String subtotal;
  final String tax;
  final String discount;
  final String totalAmount;
  final String? amountPaid;
  final String? paymentMethod;
  final String takenBy;
  final String? preparedBy;
  final String? deliveredBy;
  final String? specialInstructions;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final Branch branch;

  KitchenOrder({
    required this.id,
    required this.orderId,
    required this.branchId,
    required this.organizationId,
    required this.orderType,
    required this.status,
    this.tableNumber,
    this.customerName, // ← CHANGED: Made nullable
    this.customerPhone, // ← CHANGED: Made nullable
    required this.orderedAt,
    this.confirmedAt,
    this.startedAt,
    this.readyAt,
    this.servedAt,
    this.completedAt,
    this.cancelledAt,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.totalAmount,
    this.amountPaid,
    this.paymentMethod,
    required this.takenBy,
    this.preparedBy,
    this.deliveredBy,
    this.specialInstructions,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.branch,
  });

  factory KitchenOrder.fromJson(Map<String, dynamic> json) {
    return KitchenOrder(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      orderType: OrderType.fromString(json['orderType'] as String?),
      status: OrderStatus.fromString(json['status'] as String?),
      tableNumber: json['tableNumber'] as String?,
      customerName:
          json['customerName'] as String?, // ← CHANGED: Safe nullable cast
      customerPhone:
          json['customerPhone'] as String?, // ← CHANGED: Safe nullable cast
      orderedAt: json['orderedAt'] != null
          ? DateTime.parse(json['orderedAt'] as String)
          : DateTime.now(),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      readyAt: json['readyAt'] != null
          ? DateTime.parse(json['readyAt'] as String)
          : null,
      servedAt: json['servedAt'] != null
          ? DateTime.parse(json['servedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      subtotal: _parseToString(json['subtotal']),
      tax: _parseToString(json['tax']),
      discount: _parseToString(json['discount']),
      totalAmount: _parseToString(json['totalAmount']),
      amountPaid: json['amountPaid'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      takenBy: json['takenBy'] as String? ?? '',
      preparedBy: json['preparedBy'] as String?,
      deliveredBy: json['deliveredBy'] as String?,
      specialInstructions: json['specialInstructions'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      branch: Branch.fromJson(json['branch'] as Map<String, dynamic>),
    );
  }

  /// Helper to safely parse values to String
  static String _parseToString(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'branchId': branchId,
      'organizationId': organizationId,
      'orderType': orderType.value,
      'status': status.value,
      'tableNumber': tableNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'orderedAt': orderedAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'readyAt': readyAt?.toIso8601String(),
      'servedAt': servedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'paymentMethod': paymentMethod,
      'takenBy': takenBy,
      'preparedBy': preparedBy,
      'deliveredBy': deliveredBy,
      'specialInstructions': specialInstructions,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'branch': branch.toJson(),
    };
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String menuItemId;
  final int quantity;
  final String unitPrice;
  final String totalPrice;
  final OrderStatus status;
  final String? specialRequest;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MenuItem menuItem;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.status,
    this.specialRequest,
    required this.createdAt,
    required this.updatedAt,
    required this.menuItem,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      menuItemId: json['menuItemId'] as String? ?? '',
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toInt()
          : 0,
      unitPrice: _parseToString(json['unitPrice']),
      totalPrice: _parseToString(json['totalPrice']),
      status: OrderStatus.fromString(json['status'] as String?),
      specialRequest: json['specialRequest'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      menuItem: MenuItem.fromJson(json['menuItem'] as Map<String, dynamic>),
    );
  }

  /// Helper to safely parse values to String
  static String _parseToString(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'menuItemId': menuItemId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'status': status.value,
      'specialRequest': specialRequest,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'menuItem': menuItem.toJson(),
    };
  }
}

class MenuItem {
  final String id;
  final String dishName;
  final String description;
  final String category;
  final String price;
  final int preparationTime;
  final bool isAvailable;
  final String imageUrl;
  final String branchId;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem({
    required this.id,
    required this.dishName,
    required this.description,
    required this.category,
    required this.price,
    required this.preparationTime,
    required this.isAvailable,
    required this.imageUrl,
    required this.branchId,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String? ?? '',
      dishName: json['dishName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: _parseToString(json['price']),
      preparationTime: (json['preparationTime'] is num)
          ? (json['preparationTime'] as num).toInt()
          : 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Helper to safely parse values to String
  static String _parseToString(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dishName': dishName,
      'description': description,
      'category': category,
      'price': price,
      'preparationTime': preparationTime,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'branchId': branchId,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Branch {
  final String id;
  final String name;
  final String branchCode;
  final String address;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final String email;
  final Map<String, dynamic>? openingHours; // Changed from String? to Map
  final bool isActive;
  final String? managerId; // Changed to nullable
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Branch({
    required this.id,
    required this.name,
    required this.branchCode,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
    required this.email,
    this.openingHours,
    required this.isActive,
    this.managerId, // Made nullable
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    try {
      return Branch(
        id: _parseString(json['id']),
        name: _parseString(json['name']),
        branchCode: _parseString(json['branch_code'] ?? json['branchCode']),
        address: _parseString(json['address']),
        city: _parseString(json['city']),
        state: _parseString(json['state']),
        country: _parseString(json['country']),
        zipCode: _parseString(json['zipCode']),
        email: _parseString(json['email']),
        openingHours:
            json['openingHours'] != null && json['openingHours'] is Map
            ? Map<String, dynamic>.from(json['openingHours'])
            : null,
        isActive: _parseBool(json['isActive']),
        managerId: _parseStringOrNull(json['managerId']),
        organizationId: _parseString(json['organizationId']),
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      print('Error parsing Branch: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) return '';
    if (value is num) return value.toString();
    return value.toString();
  }

  static String? _parseStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is Map) return null;
    if (value is num) return value.toString();
    return value.toString();
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is num) return value != 0;
    return false;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'branch_code': branchCode,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zipCode': zipCode,
      'email': email,
      'openingHours': openingHours,
      'isActive': isActive,
      'managerId': managerId,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods to work with opening hours
  String? getOpeningTime(String day) {
    if (openingHours == null) return null;
    final dayHours = openingHours![day.toLowerCase()];
    if (dayHours is Map) {
      return dayHours['open'] as String?;
    }
    return null;
  }

  String? getClosingTime(String day) {
    if (openingHours == null) return null;
    final dayHours = openingHours![day.toLowerCase()];
    if (dayHours is Map) {
      return dayHours['close'] as String?;
    }
    return null;
  }

  String getFormattedHours(String day) {
    final open = getOpeningTime(day);
    final close = getClosingTime(day);
    if (open == null || close == null) return 'Closed';
    return '$open - $close';
  }
}

enum OrderType {
  dineIn('DINE_IN'),
  takeaway('TAKEAWAY'),
  online('ONLINE'),
  delivery('DELIVERY');

  final String value;
  const OrderType(this.value);

  static OrderType fromString(String? value) {
    if (value == null) return OrderType.dineIn;
    return OrderType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => OrderType.dineIn,
    );
  }
}

enum OrderStatus {
  pending('PENDING'),
  confirmed('CONFIRMED'),
  inQueue('IN_QUEUE'),
  preparing('PREPARING'),
  ready('READY'),
  served('SERVED'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  final String value;
  const OrderStatus(this.value);

  static OrderStatus fromString(String? value) {
    if (value == null) return OrderStatus.pending;
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.inQueue:
        return 'In Queue';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.served:
        return 'Served';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
