import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_summary_model.dart';

sealed class BranchStockSummaryRepositoryInterface {
  Future<ApiResponse<BranchStockSummaryResponse>> getBranchStockSummary(
    String branchId,
  );
}

class BranchStockSummaryRepository extends BaseRepository
    implements BranchStockSummaryRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<BranchStockSummaryResponse>> getBranchStockSummary(
    String branchId,
  ) async {
    try {
      // Validate branchId
      _validateBranchId(branchId);

      final response = await _apiClient
          .get('branch-stock/branch/$branchId/summary')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (data) {
          try {
            // Handle null or empty response - THESE ARE VALID STATES
            if (data == null || (data is Map && data.isEmpty)) {
              return ApiResponse.success(_createEmptyStockSummary());
            }

            final summary = _parseBranchStockSummaryResponse(data);

            // Empty data is valid - don't treat it as an error
            // Just return the summary as-is
            return ApiResponse.success(summary);
          } catch (e) {
            print('Failed to parse stock summary: $e');
            // Return error for actual parsing failures
            return ApiResponse.error(
              NetworkException.formatException(
                'Failed to parse stock summary: ${e.toString()}',
              ),
            );
          }
        },
        error: (error) => ApiResponse.error(error),
      );
    } on SocketException catch (e) {
      return ApiResponse.error(NetworkException.noInternetConnection());
    } on TimeoutException catch (e) {
      return ApiResponse.error(NetworkException.requestTimeout());
    } on FormatException catch (e) {
      return ApiResponse.error(
        NetworkException.formatException(
          e.message.isNotEmpty
              ? e.message
              : 'Invalid response from server. Please try again later.',
        ),
      );
    } catch (e) {
      return ApiResponse.error(
        NetworkException.defaultError(_parseErrorMessage(e.toString())),
      );
    }
  }

  /// Validates branchId parameter
  void _validateBranchId(String branchId) {
    if (branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }
  }

  /// Parse branch stock summary response with error handling
  BranchStockSummaryResponse _parseBranchStockSummaryResponse(
    Map<String, dynamic> json,
  ) {
    try {
      return BranchStockSummaryResponse.fromJson(json);
    } catch (e) {
      throw FormatException('Failed to parse stock summary: ${e.toString()}');
    }
  }

  BranchStockSummaryResponse _createEmptyStockSummary() {
    return BranchStockSummaryResponse(
      message: 'No stock data available',
      data: BranchStockSummaryData(
        expiringItems: [],
        overview: Overview(
          totalItems: 0,
          totalStockQuantity: 0,
          totalValue: 0,
          statusBreakdown: StatusBreakdown(inStock: 0, expired: 0),
        ),
        stockByCategory: [],
        lowStockItems: [],
        recentMovements: [],
      ),
    );
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
    return 'Failed to load stock summary. Please try again later.';
  }
}
