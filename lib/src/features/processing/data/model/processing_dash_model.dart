class ProcessingDashboardData {
  final ProductIntake productIntake;
  final ProcessingTasks processingTasks;
  final List<RecentVerification> recentVerifications;
  final WasteToday wasteToday;

  ProcessingDashboardData({
    required this.productIntake,
    required this.processingTasks,
    required this.recentVerifications,
    required this.wasteToday,
  });

  factory ProcessingDashboardData.fromJson(Map<String, dynamic> json) {
    return ProcessingDashboardData(
      productIntake: ProductIntake.fromJson(json['productIntake'] ?? {}),
      processingTasks: ProcessingTasks.fromJson(json['processingTasks'] ?? {}),
      recentVerifications:
          (json['recentVerifications'] as List<dynamic>?)
              ?.map(
                (v) => RecentVerification.fromJson(v as Map<String, dynamic>),
              )
              .toList() ??
          [],
      wasteToday: WasteToday.fromJson(json['wasteToday'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productIntake': productIntake.toJson(),
      'processingTasks': processingTasks.toJson(),
      'recentVerifications': recentVerifications
          .map((v) => v.toJson())
          .toList(),
      'wasteToday': wasteToday.toJson(),
    };
  }
}

class ProductIntake {
  final int total;
  final int count;

  ProductIntake({required this.total, required this.count});

  factory ProductIntake.fromJson(Map<String, dynamic> json) {
    return ProductIntake(
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'total': total, 'count': count};
  }
}

class ProcessingTasks {
  final int pending;
  final int inProcess;
  final int completedToday;

  ProcessingTasks({
    required this.pending,
    required this.inProcess,
    required this.completedToday,
  });

  factory ProcessingTasks.fromJson(Map<String, dynamic> json) {
    return ProcessingTasks(
      pending: int.tryParse(json['pending']?.toString() ?? '0') ?? 0,
      inProcess: int.tryParse(json['inProcess']?.toString() ?? '0') ?? 0,
      completedToday:
          int.tryParse(json['completedToday']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pending': pending,
      'inProcess': inProcess,
      'completedToday': completedToday,
    };
  }
}

class RecentVerification {
  final String id;
  final String branchId;
  final String organizationId;
  final String batchId;
  final String? batchCode;
  final String productName;
  final String recipeId;
  final String expectedOutput;
  final String actualOutput;
  final String variance;
  final String qcStatus;
  final String reason;
  final String assignedTo;
  final String verifiedBy;
  final String timestamp;
  final String createdAt;
  final String updatedAt;
  final Recipe? recipe;

  RecentVerification({
    required this.id,
    required this.branchId,
    required this.organizationId,
    required this.batchId,
    this.batchCode,
    required this.productName,
    required this.recipeId,
    required this.expectedOutput,
    required this.actualOutput,
    required this.variance,
    required this.qcStatus,
    required this.reason,
    required this.assignedTo,
    required this.verifiedBy,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
    this.recipe,
  });

  factory RecentVerification.fromJson(Map<String, dynamic> json) {
    return RecentVerification(
      id: json['id'] ?? '',
      branchId: json['branchId'] ?? '',
      organizationId: json['organizationId'] ?? '',
      batchId: json['batchId'] ?? '',
      batchCode: json['batchCode'],
      productName: json['productName'] ?? '',
      recipeId: json['recipeId'] ?? '',
      expectedOutput: json['expectedOutput'] ?? '0',
      actualOutput: json['actualOutput'] ?? '0',
      variance: json['variance'] ?? '0',
      qcStatus: json['qcStatus'] ?? '',
      reason: json['reason'] ?? '',
      assignedTo: json['assignedTo'] ?? '',
      verifiedBy: json['verifiedBy'] ?? '',
      timestamp: json['timestamp'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      recipe: json['recipe'] != null
          ? Recipe.fromJson(json['recipe'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branchId': branchId,
      'organizationId': organizationId,
      'batchId': batchId,
      'batchCode': batchCode,
      'productName': productName,
      'recipeId': recipeId,
      'expectedOutput': expectedOutput,
      'actualOutput': actualOutput,
      'variance': variance,
      'qcStatus': qcStatus,
      'reason': reason,
      'assignedTo': assignedTo,
      'verifiedBy': verifiedBy,
      'timestamp': timestamp,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'recipe': recipe?.toJson(),
    };
  }

  // Helper getter for status display
  String get status {
    // You can customize this based on your business logic
    if (qcStatus == 'APPROVED' || qcStatus == 'WITHIN_TOLERANCE') {
      return 'Verified';
    } else if (qcStatus == 'SLIGHT_OVERUSE') {
      return 'Verified';
    } else if (qcStatus == 'REJECTED' || qcStatus == 'SIGNIFICANT_VARIANCE') {
      return 'Verified';
    }
    return 'Verified';
  }
}

class Recipe {
  final String id;
  final String menuItemId;
  final int servingSize;
  final String createdAt;
  final String updatedAt;
  final MenuItem? menuItem;

  Recipe({
    required this.id,
    required this.menuItemId,
    required this.servingSize,
    required this.createdAt,
    required this.updatedAt,
    this.menuItem,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      menuItemId: json['menuItemId'] ?? '',
      servingSize: int.tryParse(json['servingSize']?.toString() ?? '0') ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      menuItem: json['menuItem'] != null
          ? MenuItem.fromJson(json['menuItem'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'servingSize': servingSize,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
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
  final String imageUrl;
  final String branchId;
  final String organizationId;
  final String createdAt;
  final String updatedAt;

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
      id: json['id'] ?? '',
      dishName: json['dishName'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? '0',
      preparationTime:
          int.tryParse(json['preparationTime']?.toString() ?? '0') ?? 0,
      isAvailable: json['isAvailable'] ?? false,
      imageUrl: json['imageUrl'] ?? '',
      branchId: json['branchId'] ?? '',
      organizationId: json['organizationId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
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
      'branchId': branchId,
      'organizationId': organizationId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class WasteToday {
  final double value;
  final int count;

  WasteToday({required this.value, required this.count});

  factory WasteToday.fromJson(Map<String, dynamic> json) {
    return WasteToday(
      value: double.tryParse(json['value']?.toString() ?? '0') ?? 0.0,
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'count': count};
  }
}
