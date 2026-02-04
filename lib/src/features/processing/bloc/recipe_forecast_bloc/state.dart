// ==================== STATE ====================
// bloc/recipe_forecast_bloc/state.dart
import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/processing/data/model/recipe_forecast_model.dart';

enum RecipeForecastErrorType {
  network,
  timeout,
  validation,
  notFound,
  server,
  general,
}

abstract class RecipeForecastState extends Equatable {
  const RecipeForecastState();

  @override
  List<Object?> get props => [];
}

class RecipeForecastInitial extends RecipeForecastState {
  const RecipeForecastInitial();
}

class RecipeForecastCalculating extends RecipeForecastState {
  const RecipeForecastCalculating();
}

class RecipeForecastCalculated extends RecipeForecastState {
  final RecipeForecastResponse forecast;

  const RecipeForecastCalculated({required this.forecast});

  @override
  List<Object?> get props => [forecast];
}

class RecipeForecastError extends RecipeForecastState {
  final String error;
  final RecipeForecastErrorType errorType;

  const RecipeForecastError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}
