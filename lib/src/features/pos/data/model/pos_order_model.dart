class PosOrderResponseModel {
  final String id;
  final String orderId; // This is the order number (ORD0010)
  final String status;
  final String orderType;
  final String? tableNumber;
  final String? customerName;
  final String? customerPhone;
  final double totalAmount;
  final double discount;
  final double subtotal;
  final double tax;
  final String? specialInstructions;
  final String branchId;
  final String takenBy;
  final DateTime createdAt;
  final List<PosOrderItemResponse> items;

  PosOrderResponseModel({
    required this.id,
    required this.orderId,
    required this.status,
    required this.orderType,
    this.tableNumber,
    this.customerName,
    this.customerPhone,
    required this.totalAmount,
    required this.discount,
    required this.subtotal,
    required this.tax,
    this.specialInstructions,
    required this.branchId,
    required this.takenBy,
    required this.createdAt,
    required this.items,
  });

  // Convenience getter for order number
  String get orderNumber => orderId;

  factory PosOrderResponseModel.fromJson(Map<String, dynamic> json) {
    return PosOrderResponseModel(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      orderType: json['orderType'] as String? ?? '',
      tableNumber: json['tableNumber'] as String?,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      // Parse string prices to double
      totalAmount: _parseToDouble(json['totalAmount']),
      discount: _parseToDouble(json['discount']),
      subtotal: _parseToDouble(json['subtotal']),
      tax: _parseToDouble(json['tax']),
      specialInstructions: json['specialInstructions'] as String?,
      branchId: json['branchId'] as String? ?? '',
      takenBy: json['takenBy'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) =>
                    PosOrderItemResponse.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  /// Helper method to safely parse values to double
  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'orderId': orderId,
      'status': status,
      'orderType': orderType,
      'totalAmount': totalAmount.toString(),
      'discount': discount.toString(),
      'subtotal': subtotal.toString(),
      'tax': tax.toString(),
      'branchId': branchId,
      'takenBy': takenBy,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };

    if (tableNumber != null) data['tableNumber'] = tableNumber;
    if (customerName != null) data['customerName'] = customerName;
    if (customerPhone != null) data['customerPhone'] = customerPhone;
    if (specialInstructions != null) {
      data['specialInstructions'] = specialInstructions;
    }

    return data;
  }
}

class PosOrderItemResponse {
  final String id;
  final String menuItemId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String status;
  final String? specialRequest;
  final MenuItemDetail? menuItem;

  PosOrderItemResponse({
    required this.id,
    required this.menuItemId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.status,
    this.specialRequest,
    this.menuItem,
  });

  // Convenience getter for dishName
  String get dishName => menuItem?.dishName ?? '';

  factory PosOrderItemResponse.fromJson(Map<String, dynamic> json) {
    return PosOrderItemResponse(
      id: json['id'] as String? ?? '',
      menuItemId: json['menuItemId'] as String? ?? '',
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toInt()
          : 0,
      unitPrice: _parseToDouble(json['unitPrice']),
      totalPrice: _parseToDouble(json['totalPrice']),
      status: json['status'] as String? ?? '',
      specialRequest: json['specialRequest'] as String?,
      menuItem: json['menuItem'] != null
          ? MenuItemDetail.fromJson(json['menuItem'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Helper method to safely parse values to double
  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'menuItemId': menuItemId,
      'quantity': quantity,
      'unitPrice': unitPrice.toString(),
      'totalPrice': totalPrice.toString(),
      'status': status,
    };

    if (specialRequest != null && specialRequest!.isNotEmpty) {
      data['specialRequest'] = specialRequest;
    }

    if (menuItem != null) {
      data['menuItem'] = menuItem!.toJson();
    }

    return data;
  }
}

class MenuItemDetail {
  final String id;
  final String dishName;
  final String description;
  final String category;
  final String price;
  final int preparationTime;
  final bool isAvailable;
  final String imageUrl;

  MenuItemDetail({
    required this.id,
    required this.dishName,
    required this.description,
    required this.category,
    required this.price,
    required this.preparationTime,
    required this.isAvailable,
    required this.imageUrl,
  });

  factory MenuItemDetail.fromJson(Map<String, dynamic> json) {
    return MenuItemDetail(
      id: json['id'] as String? ?? '',
      dishName: json['dishName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: json['price']?.toString() ?? '0',
      preparationTime: (json['preparationTime'] is num)
          ? (json['preparationTime'] as num).toInt()
          : 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String? ?? '',
    );
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
    };
  }
}
