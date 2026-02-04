// bloc/recipe_forecast_bloc/event.dart
import 'package:equatable/equatable.dart';

abstract class RecipeForecastEvent extends Equatable {
  const RecipeForecastEvent();

  @override
  List<Object?> get props => [];
}

class CalculateRecipeForecast extends RecipeForecastEvent {
  final String recipeId;
  final String dishName;
  final int targetServings;
  final String organizationId;
  final String branchId;

  const CalculateRecipeForecast({
    required this.recipeId,
    required this.dishName,
    required this.targetServings,
    required this.organizationId,
    required this.branchId,
  });

  @override
  List<Object?> get props => [
    recipeId,
    dishName,
    targetServings,
    organizationId,
    branchId,
  ];
}

class ResetRecipeForecast extends RecipeForecastEvent {
  const ResetRecipeForecast();
}
