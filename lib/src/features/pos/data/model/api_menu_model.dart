// data/model/api_menu_item.dart

import 'package:sandwich_ai/src/features/pos/data/model/menu_items.dart';

class ApiMenuItem {
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
  final Branch? branch;
  final Recipe? recipe;

  ApiMenuItem({
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
    this.branch,
    this.recipe,
  });

  factory ApiMenuItem.fromJson(Map<String, dynamic> json) {
    return ApiMenuItem(
      id: json['id'] as String? ?? '',
      dishName: json['dishName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: _parseToString(json['price']),
      preparationTime: _parseToInt(json['preparationTime']),
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
      branch: json['branch'] != null
          ? Branch.fromJson(json['branch'] as Map<String, dynamic>)
          : null,
      recipe: json['recipe'] != null
          ? Recipe.fromJson(json['recipe'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Helper method to safely parse values to String
  static String _parseToString(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }

  /// Helper method to safely parse values to int
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
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
      'branch': branch?.toJson(),
      'recipe': recipe?.toJson(),
    };
  }

  // Convert to MenuItem for compatibility
  MenuItem toMenuItem() {
    return MenuItem(
      id: id.hashCode,
      name: dishName,
      price: double.parse(price).toInt(),
      category: category,
      imageUrl: imageUrl,
    );
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
  final String? openingHours;
  final bool isActive;
  final String managerId;
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
    required this.managerId,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      branchCode: json['branch_code'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? '',
      zipCode: json['zipCode'] as String? ?? '',
      email: json['email'] as String? ?? '',
      openingHours: json['openingHours'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      managerId: json['managerId'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
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
}

class Recipe {
  final String id;
  final String menuItemId;
  final int servingSize;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RecipeIngredient>? ingredients;

  Recipe({
    required this.id,
    required this.menuItemId,
    required this.servingSize,
    required this.createdAt,
    required this.updatedAt,
    this.ingredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String? ?? '',
      menuItemId: json['menuItemId'] as String? ?? '',
      servingSize: (json['servingSize'] is int)
          ? json['servingSize'] as int
          : int.tryParse(json['servingSize'].toString()) ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      ingredients: json['ingredients'] != null
          ? (json['ingredients'] as List)
                .map(
                  (i) => RecipeIngredient.fromJson(i as Map<String, dynamic>),
                )
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'servingSize': servingSize,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'ingredients': ingredients?.map((i) => i.toJson()).toList(),
    };
  }
}

class RecipeIngredient {
  final String id;
  final String recipeId;
  final String itemId;
  final String expectedQuantity;
  final String unit;
  final DateTime createdAt;
  final DateTime updatedAt;
  final InventoryItem? item;

  RecipeIngredient({
    required this.id,
    required this.recipeId,
    required this.itemId,
    required this.expectedQuantity,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
    this.item,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'] as String? ?? '',
      recipeId: json['recipeId'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      expectedQuantity: json['expectedQuantity'] as String? ?? '0',
      unit: json['unit'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      item: json['item'] != null
          ? InventoryItem.fromJson(json['item'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'itemId': itemId,
      'expectedQuantity': expectedQuantity,
      'unit': unit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'item': item?.toJson(),
    };
  }
}

class InventoryItem {
  final String id;
  final String itemName;
  final String category;
  final String unit;
  final String description;
  final String sku;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem({
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

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'category': category,
      'unit': unit,
      'description': description,
      'sku': sku,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
