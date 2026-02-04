// models/output_verification_model.dart

class OutputVerification {
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
  final Branch? branch;
  final Recipe? recipe;

  OutputVerification({
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
    this.branch,
    this.recipe,
  });

  factory OutputVerification.fromJson(Map<String, dynamic> json) {
    return OutputVerification(
      id: json['id'] ?? '',
      branchId: json['branchId'] ?? '',
      organizationId: json['organizationId'] ?? '',
      batchId: json['batchId'] ?? '',
      batchCode: json['batchCode'],
      productName: json['productName'] ?? '',
      recipeId: json['recipeId'] ?? '',
      expectedOutput: json['expectedOutput']?.toString() ?? '0',
      actualOutput: json['actualOutput']?.toString() ?? '0',
      variance: json['variance']?.toString() ?? '0',
      qcStatus: json['qcStatus'] ?? '',
      reason: json['reason'] ?? '',
      assignedTo: json['assignedTo'] ?? '',
      verifiedBy: json['verifiedBy'] ?? '',
      timestamp: json['timestamp'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      recipe: json['recipe'] != null ? Recipe.fromJson(json['recipe']) : null,
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
    };
  }
}

class CreateOutputVerificationRequest {
  final String branchId;
  final String batchId;
  final String productName;
  final String recipeId;
  final int expectedOutput;
  final int actualOutput;
  final String reason;
  final String assignedTo;
  final String verifiedBy;

  CreateOutputVerificationRequest({
    required this.branchId,
    required this.batchId,
    required this.productName,
    required this.recipeId,
    required this.expectedOutput,
    required this.actualOutput,
    required this.reason,
    required this.assignedTo,
    required this.verifiedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'batchId': batchId,
      'productName': productName,
      'recipeId': recipeId,
      'expectedOutput': expectedOutput,
      'actualOutput': actualOutput,
      'reason': reason,
      'assignedTo': assignedTo,
      'verifiedBy': verifiedBy,
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

  Branch({
    required this.id,
    required this.name,
    required this.branchCode,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      branchCode: json['branch_code'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

class Recipe {
  final String id;
  final String menuItemId;
  final int servingSize;
  final MenuItem? menuItem;

  Recipe({
    required this.id,
    required this.menuItemId,
    required this.servingSize,
    this.menuItem,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      menuItemId: json['menuItemId'] ?? '',
      servingSize: json['servingSize'] ?? 0,
      menuItem: json['menuItem'] != null
          ? MenuItem.fromJson(json['menuItem'])
          : null,
    );
  }
}

class MenuItem {
  final String id;
  final String dishName;
  final String description;
  final String category;
  final String imageUrl;

  MenuItem({
    required this.id,
    required this.dishName,
    required this.description,
    required this.category,
    required this.imageUrl,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      dishName: json['dishName'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
