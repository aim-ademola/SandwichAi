import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/branch_details_model.dart';

abstract class BranchStockDetailsRepositoryInterface {
  Future<ApiResponse<BranchStockDetails>> getBranchStockDetails(String stockId);
}

class BranchStockDetailsRepository extends BaseRepository
    implements BranchStockDetailsRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<BranchStockDetails>> getBranchStockDetails(
    String stockId,
  ) async {
    try {
      // Validate stockId
      _validateStockId(stockId);

      final response = await _apiClient
          .get('branch-stock/$stockId')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseBranchStockDetails(json),
      );
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException {
      return ApiResponse.errorMessage(
        'Invalid response from server. Please try again later.',
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  /// Validates stockId parameter
  void _validateStockId(String stockId) {
    if (stockId.isEmpty) {
      throw FormatException('Stock ID cannot be empty');
    }
  }

  /// Parse branch stock details response with error handling
  BranchStockDetails _parseBranchStockDetails(Map<String, dynamic> json) {
    try {
      // Validate response structure
      if (!json.containsKey('data')) {
        throw FormatException('Invalid response structure: missing data field');
      }

      final data = json['data'];
      if (data == null) {
        throw FormatException('No stock details found');
      }

      return BranchStockDetails.fromJson(json);
    } catch (e) {
      throw FormatException('Failed to parse stock details: ${e.toString()}');
    }
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
      return 'Stock item not found. It may have been deleted.';
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
    return 'Failed to load stock details. Please try again later.';
  }
}
