import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_model.dart';

abstract class BranchStockRepositoryInterface {
  Future<ApiResponse<BranchStockResponse>> getBranchStock(String branchId);
}

class BranchStockRepository extends BaseRepository
    implements BranchStockRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<BranchStockResponse>> getBranchStock(
    String branchId,
  ) async {
    try {
      // Validate branchId
      _validateBranchId(branchId);

      final response = await _apiClient
          .get('branch-stock/branch/$branchId')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseBranchStockResponse(json),
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
      return ApiResponse.errorMessage(
        'Invalid response from server. Please try again later.',
      );
    } catch (e) {
      return ApiResponse.errorMessage(_extractCleanErrorMessage(e));
    }
  }

  String _extractCleanErrorMessage(Object error) {
    if (error is FormatException) {
      return error.message.isNotEmpty
          ? error.message
          : 'Invalid data received from server.';
    }

    if (error is TimeoutException) {
      return 'Request timeout. Please try again.';
    }

    return _parseErrorMessage(error.toString());
  }

  /// Validates branchId parameter
  void _validateBranchId(String branchId) {
    if (branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }
  }

  /// Parse branch stock response with error handling
  BranchStockResponse _parseBranchStockResponse(Map<String, dynamic> json) {
    return BranchStockResponse.fromJson(json);
  }

  /// Parse error messages to user-friendly format
  String _parseErrorMessage(String error) {
    final lowercaseError = error.toLowerCase();

    // Common API error patterns
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
      return 'Branch not found. Please check your selection.';
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
    return 'Failed to load stock data. Please try again later.';
  }
}
