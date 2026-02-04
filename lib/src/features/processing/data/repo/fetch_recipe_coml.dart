import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/processing/data/model/recipe_compliance_models.dart';

abstract class RecipeComplianceHistoryRepositoryInterface {
  Future<ApiResponse<List<RecipeComplianceResponse>>>
  getRecipeComplianceHistory({
    required String branchId,
    String? menuItemId,
    DateTime? startDate,
    DateTime? endDate,
  });
}

class RecipeComplianceHistoryRepository extends BaseRepository
    implements RecipeComplianceHistoryRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<List<RecipeComplianceResponse>>>
  getRecipeComplianceHistory({
    required String branchId,
    String? menuItemId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _validateBranchId(branchId);

      final queryParams = <String, dynamic>{'branchId': branchId};

      if (menuItemId != null && menuItemId.isNotEmpty) {
        queryParams['menuItemId'] = menuItemId;
      }

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }

      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final listResponse = await handleListResponse<RecipeComplianceResponse>(
        _apiClient
            .get('kitchen/recipe-compliance', queryParameters: queryParams)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Request timed out. Please try again.');
              },
            )
            .then((response) => ApiResponse.success(response.data)),
        (json) => RecipeComplianceResponse.fromJson(json),
      );

      return listResponse;
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

  void _validateBranchId(String branchId) {
    if (branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
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
      return 'No compliance records found.';
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

    return 'Failed to load compliance history. Please try again later.';
  }
}
