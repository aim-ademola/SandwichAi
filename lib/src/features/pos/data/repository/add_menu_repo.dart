// data/repo/menu_items_repository.dart
import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';

abstract class MenuItemsRepositoryInterface {
  Future<ApiResponse<List<ApiMenuItem>>> getMenuItems({
    required String branchId,
  });

  Future<ApiResponse<ApiMenuItem>> createMenuItem({
    required String branchId,
    required String dishName,
    required String description,
    required String category,
    required int price,
    required int preparationTime,
    required bool isAvailable,
    String? imageUrl,
  });

  Future<ApiResponse<ApiMenuItem>> updateMenuItem({
    required String menuItemId,
    required String dishName,
    required String description,
    required String category,
    required int price,
    required int preparationTime,
    required bool isAvailable,
    String? imageUrl,
  });

  Future<ApiResponse<String>> deleteMenuItem({required String menuItemId});
}

class MenuItemsRepository extends BaseRepository
    implements MenuItemsRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<List<ApiMenuItem>>> getMenuItems({
    required String branchId,
  }) async {
    try {
      _validateBranchId(branchId);

      final queryParams = {'branchId': branchId};

      final listResponse = await handleListResponse(
        _apiClient
            .get('kitchen/menu-items', queryParameters: queryParams)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Request timed out. Please try again.');
              },
            )
            .then((response) => ApiResponse.success(response.data)),
        (json) => ApiMenuItem.fromJson(json),
      );

      return listResponse;
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
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
  Future<ApiResponse<ApiMenuItem>> createMenuItem({
    required String branchId,
    required String dishName,
    required String description,
    required String category,
    required int price,
    required int preparationTime,
    required bool isAvailable,
    String? imageUrl,
  }) async {
    try {
      _validateBranchId(branchId);
      _validateMenuItem(
        dishName,
        description,
        category,
        price,
        preparationTime,
      );

      final requestBody = {
        'branchId': branchId,
        'dishName': dishName,
        'description': description,
        'category': category,
        'price': price,
        'preparationTime': preparationTime,
        'isAvailable': isAvailable,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      };

      final response = await _apiClient
          .post('kitchen/menu-items', data: requestBody)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Failed to create menu item');
      }

      final menuItem = ApiMenuItem.fromJson(response.data);
      return ApiResponse.success(menuItem);
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
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
  Future<ApiResponse<ApiMenuItem>> updateMenuItem({
    required String menuItemId,
    required String dishName,
    required String description,
    required String category,
    required int price,
    required int preparationTime,
    required bool isAvailable,
    String? imageUrl,
  }) async {
    try {
      _validateMenuItemId(menuItemId);
      _validateMenuItem(
        dishName,
        description,
        category,
        price,
        preparationTime,
      );

      final requestBody = {
        'dishName': dishName,
        'description': description,
        'category': category,
        'price': price,
        'preparationTime': preparationTime,
        'isAvailable': isAvailable,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      };

      final response = await _apiClient
          .put('kitchen/menu-items/$menuItemId', data: requestBody)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Failed to update menu item');
      }

      final menuItem = ApiMenuItem.fromJson(response.data);
      return ApiResponse.success(menuItem);
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
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
  Future<ApiResponse<String>> deleteMenuItem({
    required String menuItemId,
  }) async {
    try {
      _validateMenuItemId(menuItemId);

      final response = await _apiClient
          .delete('kitchen/menu-items/$menuItemId')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data != null && response.data['message'] != null) {
        return ApiResponse.success(response.data['message']);
      }

      return ApiResponse.success('Menu item deleted successfully');
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  void _validateBranchId(String branchId) {
    if (branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }
  }

  void _validateMenuItemId(String menuItemId) {
    if (menuItemId.isEmpty) {
      throw FormatException('Menu item ID cannot be empty');
    }
  }

  void _validateMenuItem(
    String dishName,
    String description,
    String category,
    int price,
    int preparationTime,
  ) {
    if (dishName.trim().isEmpty) {
      throw FormatException('Dish name cannot be empty');
    }
    if (description.trim().isEmpty) {
      throw FormatException('Description cannot be empty');
    }
    if (category.trim().isEmpty) {
      throw FormatException('Category cannot be empty');
    }
    if (price <= 0) {
      throw FormatException('Price must be greater than zero');
    }
    if (preparationTime <= 0) {
      throw FormatException('Preparation time must be greater than zero');
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
      return 'Menu item not found.';
    }
    if (lowercaseError.contains('500') ||
        lowercaseError.contains('internal server')) {
      return 'Server error. Please try again later.';
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
