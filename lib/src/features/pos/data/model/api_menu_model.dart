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
      recipe: _parseRecipe(json),
    );
  }

  static Recipe? _parseRecipe(Map<String, dynamic> json) {
    final recipeJson =
        json['recipe'] ??
        json['menuItemRecipe'] ??
        json['menu_item_recipe'] ??
        json['configuredRecipe'];

    if (recipeJson is Map<String, dynamic>) {
      return Recipe.fromJson(recipeJson);
    }

    final recipesJson = json['recipes'] ?? json['menuItemRecipes'];
    if (recipesJson is List && recipesJson.isNotEmpty) {
      final firstRecipe = recipesJson.first;
      if (firstRecipe is Map<String, dynamic>) {
        return Recipe.fromJson(firstRecipe);
      }
    }

    final recipeId = json['recipeId'] ?? json['recipe_id'];
    if (recipeId != null && recipeId.toString().isNotEmpty) {
      return Recipe.fromJson({
        'id': recipeId,
        'menuItemId': json['id'],
        'servingSize': json['servingSize'] ?? json['serving_size'] ?? 1,
      });
    }

    return null;
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
  final Map<String, dynamic>? openingHours; // Changed to Map
  final bool isActive;
  final String? managerId; // Changed to nullable
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? paystackAccountNumber;
  final String? paystackAccountName;
  final String? paystackBankName;
  final String? paystackCustomerCode;
  final String? paystackDVAId;
  final DateTime? dvaCreatedAt;

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
    this.managerId,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
    this.paystackAccountNumber,
    this.paystackAccountName,
    this.paystackBankName,
    this.paystackCustomerCode,
    this.paystackDVAId,
    this.dvaCreatedAt,
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
        openingHours: json['openingHours'] is Map
            ? Map<String, dynamic>.from(json['openingHours'])
            : null,
        isActive: _parseBool(json['isActive']),
        managerId: _parseStringOrNull(json['managerId']),
        organizationId: _parseString(json['organizationId']),
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
        paystackAccountNumber: _parseStringOrNull(
          json['paystackAccountNumber'],
        ),
        paystackAccountName: _parseStringOrNull(json['paystackAccountName']),
        paystackBankName: _parseStringOrNull(json['paystackBankName']),
        paystackCustomerCode: _parseStringOrNull(json['paystackCustomerCode']),
        paystackDVAId: _parseStringOrNull(json['paystackDVAId']),
        dvaCreatedAt: _parseDateTimeOrNull(json['dvaCreatedAt']),
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

  static DateTime? _parseDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is DateTime) return value;
    return null;
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
      'paystackAccountNumber': paystackAccountNumber,
      'paystackAccountName': paystackAccountName,
      'paystackBankName': paystackBankName,
      'paystackCustomerCode': paystackCustomerCode,
      'paystackDVAId': paystackDVAId,
      'dvaCreatedAt': dvaCreatedAt?.toIso8601String(),
    };
  }

  // Helper method to get opening hours for a specific day
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

  // Get formatted opening hours for display
  String getFormattedHours(String day) {
    final open = getOpeningTime(day);
    final close = getClosingTime(day);
    if (open == null || close == null) return 'Closed';
    return '$open - $close';
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
      id: _parseString(json['id'] ?? json['recipeId'] ?? json['recipe_id']),
      menuItemId: _parseString(json['menuItemId'] ?? json['menu_item_id']),
      servingSize: _parseInt(json['servingSize'] ?? json['serving_size']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      ingredients: _parseIngredients(json),
    );
  }

  static List<RecipeIngredient>? _parseIngredients(Map<String, dynamic> json) {
    final ingredientsJson =
        json['ingredients'] ??
        json['recipeIngredients'] ??
        json['recipe_ingredients'];

    if (ingredientsJson is! List) return null;

    return ingredientsJson
        .whereType<Map<String, dynamic>>()
        .map(RecipeIngredient.fromJson)
        .toList();
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
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
    try {
      return InventoryItem(
        id: _parseString(json['id']),
        itemName: _parseString(json['itemName']),
        category: _parseString(json['category']),
        unit: _parseString(json['unit']),
        description: _parseString(json['description']),
        sku: _parseString(json['sku']),
        organizationId: _parseString(json['organizationId']),
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      print('Error parsing InventoryItem: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      print('Warning: Expected String but got Map: $value');
      return '';
    }
    return value.toString();
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
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
    try {
      return RecipeIngredient(
        id: _parseString(json['id']),
        recipeId: _parseString(json['recipeId'] ?? json['recipe_id']),
        itemId: _parseString(json['itemId'] ?? json['item_id']),
        expectedQuantity: _parseString(
          json['expectedQuantity'] ?? json['expected_quantity'],
        ),
        unit: _parseString(json['unit']),
        createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
        updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
        item: json['item'] != null
            ? InventoryItem.fromJson(json['item'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      print('Error parsing RecipeIngredient: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      print('Warning: Expected String but got Map: $value');
      return '';
    }
    return value.toString();
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
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
