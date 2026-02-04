import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/core/network/connectivity_service.dart';
import 'package:sandwich_ai/src/core/offline/offline_queue_manager.dart';
import 'package:sandwich_ai/src/core/offline/pending_req.dart';
import 'package:sandwich_ai/src/features/processing/data/model/recipe_compliance_models.dart';

abstract class RecipeComplianceRepositoryInterface {
  Future<ApiResponse<MenuItemsResponse>> getMenuItems(String branchId);
  Future<ApiResponse<RecipeComplianceResponse>> submitRecipeCompliance(
    RecipeComplianceRequest request,
  );
}

class RecipeComplianceRepository extends BaseRepository
    implements RecipeComplianceRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<MenuItemsResponse>> getMenuItems(String branchId) async {
    try {
      _validateBranchId(branchId);

      // Make the API call and wrap it in ApiResponse
      final apiCall = _apiClient
          .get('kitchen/menu-items', queryParameters: {'branchId': branchId})
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          )
          .then((response) {
            // Just wrap the response.data in ApiResponse.success
            return ApiResponse.success(response.data);
          })
          .catchError((error) {
            // Handle any errors from the API call
            return ApiResponse.error(error);
          });

      // Use handleListResponse to parse the list
      final listResponse = await handleListResponse<MenuItem>(
        apiCall,
        (json) => MenuItem.fromJson(json),
      );

      // Transform List<MenuItem> into MenuItemsResponse
      return listResponse.when(
        success: (menuItems) =>
            ApiResponse.success(MenuItemsResponse(menuItems: menuItems)),
        error: (error) => ApiResponse.error(error),
      );
    } on SocketException catch (e) {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<RecipeComplianceResponse>> submitRecipeCompliance(
    RecipeComplianceRequest request,
  ) async {
    try {
      _validateRecipeComplianceRequest(request);

      final online = await ConnectivityService.instance.isOnline;

      if (!online) {
        await OfflineQueueManager.instance.add(
          PendingRequest(
            method: "POST",
            url: "kitchen/recipe-compliance",
            body: request.toJson(),
          ),
          onSaved: () {
            // showToast("Request saved. Will retry automatically.");
          },
        );

        return ApiResponse.errorMessage(
          "No internet. Request saved for retry.",
        );
      }

      final response = await _apiClient
          .post("kitchen/recipe-compliance", data: request.toJson())
          .timeout(const Duration(seconds: 30));

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseRecipeComplianceResponse(json),
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  /// Validates branch ID
  void _validateBranchId(String branchId) {
    if (branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }
  }

  /// Validates recipe compliance request fields
  void _validateRecipeComplianceRequest(RecipeComplianceRequest request) {
    if (request.menuItemId.isEmpty) {
      throw FormatException('Menu Item ID cannot be empty');
    }

    if (request.branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }

    if (request.batchesPrepared <= 0) {
      throw FormatException('Batches prepared must be greater than zero');
    }

    if (request.itemName.isEmpty) {
      throw FormatException('Item name cannot be empty');
    }

    if (request.expectedInput < 0) {
      throw FormatException('Expected input cannot be negative');
    }

    if (request.actualInput < 0) {
      throw FormatException('Actual input cannot be negative');
    }
  }

  /// Parse menu items response with error handling
  MenuItemsResponse _parseMenuItemsResponse(Map<String, dynamic> json) {
    try {
      final response = MenuItemsResponse.fromJson(json);

      if (!response.isValid) {
        throw FormatException('No menu items found for this branch');
      }

      return response;
    } catch (e) {
      throw FormatException('Unable to process menu items: ${e.toString()}');
    }
  }

  /// Parse recipe compliance response with error handling
  RecipeComplianceResponse _parseRecipeComplianceResponse(
    Map<String, dynamic> json,
  ) {
    try {
      final response = RecipeComplianceResponse.fromJson(json);

      if (!response.isValid) {
        throw FormatException('Invalid compliance data received');
      }

      return response;
    } catch (e) {
      throw FormatException('Unable to process response: ${e.toString()}');
    }
  }

  /// Parse error messages to user-friendly format
  String _parseErrorMessage(String error) {
    final lowercaseError = error.toLowerCase();

    // Common API error patterns
    if (lowercaseError.contains('401') ||
        lowercaseError.contains('unauthorized')) {
      return 'Unauthorized. Please log in again.';
    }

    if (lowercaseError.contains('403') ||
        lowercaseError.contains('forbidden')) {
      return 'Access denied. You do not have permission.';
    }

    if (lowercaseError.contains('404') ||
        lowercaseError.contains('not found')) {
      return 'Menu item or recipe not found.';
    }

    if (lowercaseError.contains('409') || lowercaseError.contains('conflict')) {
      return 'Recipe compliance record already exists.';
    }

    if (lowercaseError.contains('422') ||
        lowercaseError.contains('unprocessable')) {
      return 'Invalid data provided. Please check your input.';
    }

    if (lowercaseError.contains('429') ||
        lowercaseError.contains('too many requests')) {
      return 'Too many requests. Please try again later.';
    }

    if (lowercaseError.contains('500') ||
        lowercaseError.contains('internal server')) {
      return 'Server error. Please try again later.';
    }

    if (lowercaseError.contains('503') ||
        lowercaseError.contains('service unavailable')) {
      return 'Service temporarily unavailable. Please try again.';
    }

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection')) {
      return 'Network error. Please check your connection.';
    }

    if (lowercaseError.contains('timeout')) {
      return 'Request timeout. Please try again.';
    }

    if (lowercaseError.contains('format') || lowercaseError.contains('parse')) {
      return 'Invalid response format. Please try again.';
    }

    // Generic fallback
    return 'Operation failed. Please try again later.';
  }
}
