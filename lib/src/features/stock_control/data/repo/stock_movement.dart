import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/stock_movement_model.dart';

/// Query Parameters for Stock Movements
class StockMovementQuery {
  final String? itemId;
  final String? branchId;
  final String? movementType;
  final String? startDate;
  final String? endDate;
  final int? page;
  final int? limit;

  const StockMovementQuery({
    this.itemId,
    this.branchId,
    this.movementType,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (itemId != null && itemId!.isNotEmpty) params['itemId'] = itemId;
    if (branchId != null && branchId!.isNotEmpty) params['branchId'] = branchId;
    if (movementType != null && movementType!.isNotEmpty) {
      params['movementType'] = movementType;
    }
    if (startDate != null && startDate!.isNotEmpty) {
      params['startDate'] = startDate;
    }
    if (endDate != null && endDate!.isNotEmpty) params['endDate'] = endDate;
    // if (page != null) params['page'] = page.toString();
    // if (limit != null) params['limit'] = limit.toString();

    return params;
  }
}

sealed class StockMovementRepositoryInterface {
  Future<ApiResponse<StockMovementResponse>> getStockMovements(
    StockMovementQuery query,
  );
}

class StockMovementRepository extends BaseRepository
    implements StockMovementRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<StockMovementResponse>> getStockMovements(
    StockMovementQuery query,
  ) async {
    try {
      // Build query parameters
      final queryParams = query.toQueryParams();

      // Build query string
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');

      final endpoint = queryString.isEmpty
          ? 'stock-movements'
          : 'stock-movements?$queryString';

      final response = await _apiClient
          .get(endpoint)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseStockMovementResponse(json),
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

  StockMovementResponse _parseStockMovementResponse(Map<String, dynamic> json) {
    return StockMovementResponse.fromJson(json);
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
      return 'Stock movements not found. Please check your filters.';
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
    return 'Failed to load stock movements. Please try again later.';
  }
}
