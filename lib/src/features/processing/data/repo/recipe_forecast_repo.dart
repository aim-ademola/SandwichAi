import 'package:sandwich_ai/src/core/config/feature_registry.dart';
// data/repo/recipe_forecast_repository.dart
import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/config/app_environment.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/api_constants.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/model/recipe_forecast_model.dart';

abstract class RecipeForecastRepositoryInterface {
  Future<ApiResponse<RecipeForecastResponse>> calculateRecipe({
    required String recipeId,
    required String dishName,
    required int targetServings,
    required String organizationId,
    required String branchId,
  });
}

class RecipeForecastRepository extends BaseRepository
    implements RecipeForecastRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<RecipeForecastResponse>> calculateRecipe({
    required String recipeId,
    required String dishName,
    required int targetServings,
    required String organizationId,
    required String branchId,
  }) async {
    try {
      if (!FeatureRegistry.isEnabled(AppFeature.aiForecast)) {
        return ApiResponse.errorMessage(
          AppEnvironment.current.disabledFeatureMessage(AppFeature.aiForecast),
        );
      }

      _validateInput(
        recipeId,
        dishName,
        targetServings,
        organizationId,
        branchId,
      );

      final requestBody = {
        if (recipeId.trim().isNotEmpty) 'recipe_id': recipeId,
        'dish_name': dishName,
        'target_servings': targetServings,
        'organization_id': organizationId,
        if (branchId.trim().isNotEmpty) 'branch_id': branchId,
      };

      final response = await _apiClient
          .post('${ApiConstants.aiBaseUrl}forecast/recipe', data: requestBody)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw TimeoutException(
                'Recipe calculation timed out. Please try again.',
              );
            },
          );

      return response.when(
        success: (body) {
          final forecastJson = _extractForecastJson(body);
          if (forecastJson == null) {
            return ApiResponse.errorMessage(
              'Invalid recipe response from AI service',
            );
          }

          final forecast = RecipeForecastResponse.fromJson(forecastJson);
          return ApiResponse.success(forecast);
        },
        error: (error) => ApiResponse.error(error),
      );
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Request timeout. The AI service is taking longer than expected.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  Map<String, dynamic>? _extractForecastJson(dynamic body) {
    if (body is Map<String, dynamic>) {
      final nested =
          body['data'] ?? body['forecast'] ?? body['result'] ?? body['recipe'];
      if (nested is Map<String, dynamic>) return nested;
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return body;
    }

    if (body is Map) return Map<String, dynamic>.from(body);
    return null;
  }

  void _validateInput(
    String recipeId,
    String dishName,
    int targetServings,
    String organizationId,
    String branchId,
  ) {
    if (dishName.trim().isEmpty) {
      throw FormatException('Dish name cannot be empty');
    }
    if (recipeId.trim().isEmpty && dishName.trim().isEmpty) {
      throw FormatException('Select a menu item before calculating');
    }
    if (targetServings <= 0) {
      throw FormatException('Target servings must be greater than zero');
    }
    if (organizationId.trim().isEmpty) {
      throw FormatException('Organization ID cannot be empty');
    }
  }

  String _parseErrorMessage(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('401') ||
        lowercaseError.contains('unauthorized')) {
      return 'Unauthorized access. Please login again.';
    }
    if (lowercaseError.contains('403') ||
        lowercaseError.contains('forbidden')) {
      return 'Access denied. Please contact support.';
    }
    if (lowercaseError.contains('404') ||
        lowercaseError.contains('not found')) {
      return 'Recipe not found.';
    }
    if (lowercaseError.contains('500') ||
        lowercaseError.contains('internal server')) {
      return 'AI service error. Please try again later.';
    }
    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (lowercaseError.contains('timeout')) {
      return 'Request timeout. Please try again.';
    }

    return 'An error occurred. Please try again later.';
  }
}
