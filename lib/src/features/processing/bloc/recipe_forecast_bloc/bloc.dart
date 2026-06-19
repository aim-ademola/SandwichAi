// ==================== BLOC ====================
// bloc/recipe_forecast_bloc/bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_forecast_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_forecast_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/recipe_forecast_repo.dart';

class RecipeForecastBloc
    extends Bloc<RecipeForecastEvent, RecipeForecastState> {
  final RecipeForecastRepositoryInterface _repository;

  RecipeForecastBloc({required RecipeForecastRepositoryInterface repository})
    : _repository = repository,
      super(const RecipeForecastInitial()) {
    on<CalculateRecipeForecast>(_onCalculateRecipeForecast);
    on<ResetRecipeForecast>(_onResetRecipeForecast);
  }

  Future<void> _onCalculateRecipeForecast(
    CalculateRecipeForecast event,
    Emitter<RecipeForecastState> emit,
  ) async {
    try {
      emit(const RecipeForecastCalculating());

      final response = await _repository.calculateRecipe(
        recipeId: event.recipeId,
        dishName: event.dishName,
        targetServings: event.targetServings,
        organizationId: event.organizationId,
        branchId: event.branchId,
      );

      await response.when(
        success: (forecast) async {
          emit(RecipeForecastCalculated(forecast: forecast));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            RecipeForecastError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const RecipeForecastError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: RecipeForecastErrorType.general,
        ),
      );
    }
  }

  void _onResetRecipeForecast(
    ResetRecipeForecast event,
    Emitter<RecipeForecastState> emit,
  ) {
    emit(const RecipeForecastInitial());
  }

  RecipeForecastErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return RecipeForecastErrorType.network;
    }
    if (lowercaseError.contains('timeout')) {
      return RecipeForecastErrorType.timeout;
    }
    if (lowercaseError.contains('not found') ||
        lowercaseError.contains('404')) {
      return RecipeForecastErrorType.notFound;
    }
    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return RecipeForecastErrorType.server;
    }
    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return RecipeForecastErrorType.validation;
    }

    return RecipeForecastErrorType.general;
  }
}
