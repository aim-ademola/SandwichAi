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
    return RecipeForecastResponse(
      recipeId: json['recipe_id'] ?? '',
      dishName: json['dish_name'] ?? '',
      originalServings: json['original_servings'] ?? 0,
      targetServings: json['target_servings'] ?? 0,
      scalingFactor: (json['scaling_factor'] ?? 0.0).toDouble(),
      ingredients:
          (json['ingredients'] as List<dynamic>?)
              ?.map((e) => ScaledIngredient.fromJson(e))
              .toList() ??
          [],
      estimatedCost: json['estimated_cost'] != null
          ? (json['estimated_cost'] as num).toDouble()
          : null,
      preparationNotes: json['preparation_notes'] ?? '',
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
      ingredientId: json['ingredient_id'] ?? '',
      ingredientName: json['ingredient_name'] ?? '',
      originalQuantity: (json['original_quantity'] ?? 0.0).toDouble(),
      originalUnit: json['original_unit'] ?? '',
      scaledQuantity: (json['scaled_quantity'] ?? 0.0).toDouble(),
      scaledUnit: json['scaled_unit'] ?? '',
      scalingFactor: (json['scaling_factor'] ?? 0.0).toDouble(),
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
