// repo/output_verification_repo.dart

import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/model/output_verfification_model.dart';

abstract class OutputVerificationRepositoryInterface {
  Future<ApiResponse<List<MenuItem>>> getMenuItems({required String branchId});

  Future<ApiResponse<Recipe>> getRecipe({required String menuItemId});

  Future<ApiResponse<OutputVerification>> createOutputVerification({
    required CreateOutputVerificationRequest request,
  });

  Future<ApiResponse<List<OutputVerification>>> getOutputVerifications({
    required String branchId,
  });
}

class OutputVerificationRepository extends BaseRepository
    implements OutputVerificationRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<List<MenuItem>>> getMenuItems({
    required String branchId,
  }) async {
    try {
      final listResponse = await handleListResponse<MenuItem>(
        _apiClient
            .get('kitchen/menu-items')
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Request timed out. Please try again.');
              },
            )
            .then((response) => ApiResponse.success(response.data)),
        (json) => MenuItem.fromJson(json),
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
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<Recipe>> getRecipe({required String menuItemId}) async {
    try {
      if (menuItemId.isEmpty) {
        throw FormatException('Menu Item ID cannot be empty');
      }

      final response = await _apiClient
          .get('kitchen/recipes', queryParameters: {'menuItemId': menuItemId})
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Invalid response from server');
      }

      // The API returns an array, so we take the first element
      final List<dynamic> recipes = response.data is List
          ? response.data
          : [response.data];

      if (recipes.isEmpty) {
        return ApiResponse.errorMessage('No recipe found for this menu item');
      }

      return ApiResponse.success(Recipe.fromJson(recipes[0]));
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<OutputVerification>> createOutputVerification({
    required CreateOutputVerificationRequest request,
  }) async {
    try {
      _validateBranchId(request.branchId);
      _validateOutputData(request);

      final response = await _apiClient
          .post('processing/output-verifications', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Invalid response from server');
      }

      return ApiResponse.success(OutputVerification.fromJson(response.data));
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
  Future<ApiResponse<List<OutputVerification>>> getOutputVerifications({
    required String branchId,
  }) async {
    try {
      _validateBranchId(branchId);

      final listResponse = await handleListResponse<OutputVerification>(
        _apiClient
            .get(
              'processing/output-verifications',
              queryParameters: {'branchId': branchId},
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Request timed out. Please try again.');
              },
            )
            .then((response) => ApiResponse.success(response.data)),
        (json) => OutputVerification.fromJson(json),
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
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  void _validateBranchId(String branchId) {
    if (branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }
  }

  void _validateOutputData(CreateOutputVerificationRequest request) {
    if (request.batchId.isEmpty) {
      throw FormatException('Batch ID cannot be empty');
    }
    if (request.productName.isEmpty) {
      throw FormatException('Product name cannot be empty');
    }
    if (request.recipeId.isEmpty) {
      throw FormatException('Recipe ID cannot be empty');
    }
    if (request.expectedOutput <= 0) {
      throw FormatException('Expected output must be greater than 0');
    }
    if (request.actualOutput < 0) {
      throw FormatException('Actual output cannot be negative');
    }
    if (request.assignedTo.isEmpty) {
      throw FormatException('Assigned to field cannot be empty');
    }
    if (request.verifiedBy.isEmpty) {
      throw FormatException('Verified by field cannot be empty');
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
      return 'Resource not found.';
    }

    if (lowercaseError.contains('409') || lowercaseError.contains('conflict')) {
      return 'Conflict detected. Please check your data.';
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

    return 'Failed to process request. Please try again later.';
  }
}
