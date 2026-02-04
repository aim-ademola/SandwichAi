// data/model/kitchen_dashboard_model.dart

class KitchenDashboardData {
  final OrderStats orderStats;
  final StaffOnDuty staffOnDuty;
  final ProcessingTransfers processingTransfers;
  final List<KitchenOrder> recentOrders;

  KitchenDashboardData({
    required this.orderStats,
    required this.staffOnDuty,
    required this.processingTransfers,
    required this.recentOrders,
  });

  factory KitchenDashboardData.fromJson(Map<String, dynamic> json) {
    return KitchenDashboardData(
      orderStats: OrderStats.fromJson(json['orderStats'] ?? {}),
      staffOnDuty: StaffOnDuty.fromJson(json['staffOnDuty'] ?? {}),
      processingTransfers: ProcessingTransfers.fromJson(
        json['processingTransfers'] ?? {},
      ),
      recentOrders:
          (json['recentOrders'] as List?)
              ?.map((order) => KitchenOrder.fromJson(order))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderStats': orderStats.toJson(),
      'staffOnDuty': staffOnDuty.toJson(),
      'processingTransfers': processingTransfers.toJson(),
      'recentOrders': recentOrders.map((order) => order.toJson()).toList(),
    };
  }
}

class OrderStats {
  final int ordersReceived;
  final int ordersDelivered;
  final int ongoingOrders;

  OrderStats({
    required this.ordersReceived,
    required this.ordersDelivered,
    required this.ongoingOrders,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      ordersReceived: json['ordersReceived'] ?? 0,
      ordersDelivered: json['ordersDelivered'] ?? 0,
      ongoingOrders: json['ongoingOrders'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ordersReceived': ordersReceived,
      'ordersDelivered': ordersDelivered,
      'ongoingOrders': ongoingOrders,
    };
  }
}

class StaffOnDuty {
  final int chefs;
  final int assistants;

  StaffOnDuty({required this.chefs, required this.assistants});

  factory StaffOnDuty.fromJson(Map<String, dynamic> json) {
    return StaffOnDuty(
      chefs: json['chefs'] ?? 0,
      assistants: json['assistants'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'chefs': chefs, 'assistants': assistants};
  }

  int get total => chefs + assistants;
}

class ProcessingTransfers {
  final int itemsReceived;
  final int varianceIssues;

  ProcessingTransfers({
    required this.itemsReceived,
    required this.varianceIssues,
  });

  factory ProcessingTransfers.fromJson(Map<String, dynamic> json) {
    return ProcessingTransfers(
      itemsReceived: json['itemsReceived'] ?? 0,
      varianceIssues: json['varianceIssues'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'itemsReceived': itemsReceived, 'varianceIssues': varianceIssues};
  }
}

class KitchenOrder {
  final String id;
  final String orderId;
  final String branchId;
  final String organizationId;
  final String orderType;
  final String? orderSource;
  final String status;
  final String? tableNumber;
  final String customerName;
  final String customerPhone;
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
  final String? specialInstructions;
  final String? cancellationReason;
  final List<OrderItem> items;

  KitchenOrder({
    required this.id,
    required this.orderId,
    required this.branchId,
    required this.organizationId,
    required this.orderType,
    this.orderSource,
    required this.status,
    this.tableNumber,
    required this.customerName,
    required this.customerPhone,
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
    this.specialInstructions,
    this.cancellationReason,
    required this.items,
  });

  factory KitchenOrder.fromJson(Map<String, dynamic> json) {
    return KitchenOrder(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      branchId: json['branchId'] ?? '',
      organizationId: json['organizationId'] ?? '',
      orderType: json['orderType'] ?? '',
      orderSource: json['orderSource'],
      status: json['status'] ?? '',
      tableNumber: json['tableNumber'],
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      orderedAt: DateTime.parse(json['orderedAt']),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'])
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      readyAt: json['readyAt'] != null ? DateTime.parse(json['readyAt']) : null,
      servedAt: json['servedAt'] != null
          ? DateTime.parse(json['servedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      subtotal: json['subtotal'] ?? '0',
      tax: json['tax'] ?? '0',
      discount: json['discount'] ?? '0',
      totalAmount: json['totalAmount'] ?? '0',
      specialInstructions: json['specialInstructions'],
      cancellationReason: json['cancellationReason'],
      items:
          (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'branchId': branchId,
      'organizationId': organizationId,
      'orderType': orderType,
      'orderSource': orderSource,
      'status': status,
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
      'specialInstructions': specialInstructions,
      'cancellationReason': cancellationReason,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(orderedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} day ago';
    }
  }

  String getItemsSummary() {
    final Map<String, int> itemCounts = {};

    for (var item in items) {
      final dishName = item.menuItem?.dishName ?? 'Unknown Item';
      itemCounts[dishName] = (itemCounts[dishName] ?? 0) + item.quantity;
    }

    return itemCounts.entries
        .map((entry) => '${entry.value}x ${entry.key}')
        .join(', ');
  }

  OrderStatus getOrderStatus() {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.newOrder;
      case 'PREPARING':
        return OrderStatus.inProgress;
      case 'READY':
      case 'COMPLETED':
        return OrderStatus.completed;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.newOrder;
    }
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String menuItemId;
  final int quantity;
  final String unitPrice;
  final String totalPrice;
  final String status;
  final String? specialRequest;
  final MenuItem? menuItem;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.status,
    this.specialRequest,
    this.menuItem,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      menuItemId: json['menuItemId'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: json['unitPrice'] ?? '0',
      totalPrice: json['totalPrice'] ?? '0',
      status: json['status'] ?? '',
      specialRequest: json['specialRequest'],
      menuItem: json['menuItem'] != null
          ? MenuItem.fromJson(json['menuItem'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'menuItemId': menuItemId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'status': status,
      'specialRequest': specialRequest,
      'menuItem': menuItem?.toJson(),
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
  final String? imageUrl;

  MenuItem({
    required this.id,
    required this.dishName,
    required this.description,
    required this.category,
    required this.price,
    required this.preparationTime,
    required this.isAvailable,
    this.imageUrl,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      dishName: json['dishName'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? '0',
      preparationTime: json['preparationTime'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
      imageUrl: json['imageUrl'],
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

enum OrderStatus { newOrder, inProgress, completed, cancelled }

enum OrderFilter { all, newOrder, inProgress, completed }
