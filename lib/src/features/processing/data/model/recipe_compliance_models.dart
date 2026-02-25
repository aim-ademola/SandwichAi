// recipe_compliance_request.dart
class RecipeComplianceRequest {
  final String menuItemId;
  final String branchId;
  final int batchesPrepared;
  final String itemName;
  final int expectedInput;
  final int actualInput;
  final String? notes;

  RecipeComplianceRequest({
    required this.menuItemId,
    required this.branchId,
    required this.batchesPrepared,
    required this.itemName,
    required this.expectedInput,
    required this.actualInput,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'branchId': branchId,
      'batchesPrepared': batchesPrepared,
      'itemName': itemName,
      'expectedInput': expectedInput,
      'actualInput': actualInput,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

// recipe_compliance_response.dart
class RecipeComplianceResponse {
  final String id;
  final String menuItemId;
  final String branchId;
  final String checkDate;
  final int batchesPrepared;
  final String itemName;
  final String expectedInput;
  final String actualInput;
  final String variance;
  final String variancePercent;
  final String status;
  final String? notes;
  final String createdAt;
  final MenuItem? menuItem;
  final Branch? branch;

  RecipeComplianceResponse({
    required this.id,
    required this.menuItemId,
    required this.branchId,
    required this.checkDate,
    required this.batchesPrepared,
    required this.itemName,
    required this.expectedInput,
    required this.actualInput,
    required this.variance,
    required this.variancePercent,
    required this.status,
    this.notes,
    required this.createdAt,
    this.menuItem,
    this.branch,
  });

  factory RecipeComplianceResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return RecipeComplianceResponse(
      id: data['id'] ?? '',
      menuItemId: data['menuItemId'] ?? '',
      branchId: data['branchId'] ?? '',
      checkDate: data['checkDate'] ?? '',
      batchesPrepared: data['batchesPrepared'] ?? 0,
      itemName: data['itemName'] ?? '',
      expectedInput: data['expectedInput']?.toString() ?? '0',
      actualInput: data['actualInput']?.toString() ?? '0',
      variance: data['variance']?.toString() ?? '0',
      variancePercent: data['variancePercent']?.toString() ?? '0',
      status: data['status'] ?? '',
      notes: data['notes'],
      createdAt: data['createdAt'] ?? '',
      menuItem: data['menuItem'] != null
          ? MenuItem.fromJson(data['menuItem'])
          : null,
      branch: data['branch'] != null ? Branch.fromJson(data['branch']) : null,
    );
  }

  bool get isValid => id.isNotEmpty && menuItemId.isNotEmpty;
}

// menu_item_model.dart
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
  final Recipe? recipe;

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
    this.recipe,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      dishName: json['dishName'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: json['price']?.toString() ?? '0',
      preparationTime: json['preparationTime'] ?? 0,
      isAvailable: json['isAvailable'] ?? false,
      imageUrl: json['imageUrl'] ?? '',
      branchId: json['branchId'] ?? '',
      organizationId: json['organizationId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      recipe: json['recipe'] != null ? Recipe.fromJson(json['recipe']) : null,
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
      if (recipe != null) 'recipe': recipe!.toJson(),
    };
  }
}

class Recipe {
  final String id;
  final String menuItemId;
  final int servingSize;
  final String createdAt;
  final String updatedAt;
  final List<Ingredient> ingredients;

  Recipe({
    required this.id,
    required this.menuItemId,
    required this.servingSize,
    required this.createdAt,
    required this.updatedAt,
    required this.ingredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      menuItemId: json['menuItemId'] ?? '',
      servingSize: json['servingSize'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      ingredients:
          (json['ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'servingSize': servingSize,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
    };
  }
}

class Ingredient {
  final String id;
  final String recipeId;
  final String itemId;
  final String expectedQuantity;
  final String unit;
  final String createdAt;
  final String updatedAt;
  final Item? item;

  Ingredient({
    required this.id,
    required this.recipeId,
    required this.itemId,
    required this.expectedQuantity,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
    this.item,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] ?? '',
      recipeId: json['recipeId'] ?? '',
      itemId: json['itemId'] ?? '',
      expectedQuantity: json['expectedQuantity']?.toString() ?? '0',
      unit: json['unit'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      item: json['item'] != null ? Item.fromJson(json['item']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'itemId': itemId,
      'expectedQuantity': expectedQuantity,
      'unit': unit,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (item != null) 'item': item!.toJson(),
    };
  }
}

class Item {
  final String id;
  final String itemName;
  final String category;
  final String unit;
  final String? description;
  final String sku;
  final String organizationId;
  final String createdAt;
  final String updatedAt;

  Item({
    required this.id,
    required this.itemName,
    required this.category,
    required this.unit,
    this.description,
    required this.sku,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? '',
      itemName: json['itemName'] ?? '',
      category: json['category'] ?? '',
      unit: json['unit'] ?? '',
      description: json['description'],
      sku: json['sku'] ?? '',
      organizationId: json['organizationId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
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
      'createdAt': createdAt,
      'updatedAt': updatedAt,
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

// menu_items_response.dart
class MenuItemsResponse {
  final List<MenuItem> menuItems;
  final String message;

  MenuItemsResponse({required this.menuItems, this.message = ''});

  factory MenuItemsResponse.fromJson(dynamic json) {
    List<MenuItem> items = [];

    // Handle direct array response
    if (json is List) {
      items = json
          .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    // Handle wrapped response with 'data' key
    else if (json is Map<String, dynamic>) {
      final data = json['data'];

      if (data is List) {
        items = data
            .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    return MenuItemsResponse(
      menuItems: items,
      message: json is Map<String, dynamic>
          ? (json['message']?.toString() ?? '')
          : '',
    );
  }

  bool get isValid => menuItems.isNotEmpty;

  List<String> get categories {
    return menuItems.map((item) => item.category).toSet().toList();
  }
}
