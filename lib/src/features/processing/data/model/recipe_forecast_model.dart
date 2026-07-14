String _parseString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return '';
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class RecipeForecastResponse {
  final String recipeId;
  final String dishName;
  final int originalServings;
  final int targetServings;
  final double scalingFactor;
  final List<ScaledIngredient> ingredients;
  final double? estimatedCost;
  final String preparationNotes;

  RecipeForecastResponse({
    required this.recipeId,
    required this.dishName,
    required this.originalServings,
    required this.targetServings,
    required this.scalingFactor,
    required this.ingredients,
    this.estimatedCost,
    required this.preparationNotes,
  });

  factory RecipeForecastResponse.fromJson(Map<String, dynamic> json) {
    final ingredientsJson =
        json['ingredients'] ??
        json['scaledIngredients'] ??
        json['scaled_ingredients'];

    return RecipeForecastResponse(
      recipeId: _parseString(json['recipe_id'] ?? json['recipeId']),
      dishName: _parseString(json['dish_name'] ?? json['dishName']),
      originalServings: _parseInt(
        json['original_servings'] ?? json['originalServings'],
      ),
      targetServings: _parseInt(
        json['target_servings'] ?? json['targetServings'],
      ),
      scalingFactor: _parseDouble(
        json['scaling_factor'] ?? json['scalingFactor'],
      ),
      ingredients: ingredientsJson is List
          ? ingredientsJson
                .whereType<Map>()
                .map(
                  (e) =>
                      ScaledIngredient.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : [],
      estimatedCost:
          json['estimated_cost'] != null || json['estimatedCost'] != null
          ? _parseDouble(json['estimated_cost'] ?? json['estimatedCost'])
          : null,
      preparationNotes: _parseString(
        json['preparation_notes'] ?? json['preparationNotes'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipe_id': recipeId,
      'dish_name': dishName,
      'original_servings': originalServings,
      'target_servings': targetServings,
      'scaling_factor': scalingFactor,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'estimated_cost': estimatedCost,
      'preparation_notes': preparationNotes,
    };
  }
}

class ScaledIngredient {
  final String ingredientId;
  final String ingredientName;
  final double originalQuantity;
  final String originalUnit;
  final double scaledQuantity;
  final String scaledUnit;
  final double scalingFactor;

  ScaledIngredient({
    required this.ingredientId,
    required this.ingredientName,
    required this.originalQuantity,
    required this.originalUnit,
    required this.scaledQuantity,
    required this.scaledUnit,
    required this.scalingFactor,
  });

  factory ScaledIngredient.fromJson(Map<String, dynamic> json) {
    return ScaledIngredient(
      ingredientId: _parseString(json['ingredient_id'] ?? json['ingredientId']),
      ingredientName: _parseString(
        json['ingredient_name'] ?? json['ingredientName'],
      ),
      originalQuantity: _parseDouble(
        json['original_quantity'] ?? json['originalQuantity'],
      ),
      originalUnit: _parseString(json['original_unit'] ?? json['originalUnit']),
      scaledQuantity: _parseDouble(
        json['scaled_quantity'] ?? json['scaledQuantity'],
      ),
      scaledUnit: _parseString(json['scaled_unit'] ?? json['scaledUnit']),
      scalingFactor: _parseDouble(
        json['scaling_factor'] ?? json['scalingFactor'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient_id': ingredientId,
      'ingredient_name': ingredientName,
      'original_quantity': originalQuantity,
      'original_unit': originalUnit,
      'scaled_quantity': scaledQuantity,
      'scaled_unit': scaledUnit,
      'scaling_factor': scalingFactor,
    };
  }
}
