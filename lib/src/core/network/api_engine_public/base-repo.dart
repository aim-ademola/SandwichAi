import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';

import '../api_engine_private/api_client.dart';

abstract class BaseRepository {
  final ApiClient _apiClient = ApiClient.instance;

  // Generic method for handling API responses with error handling
  Future<ApiResponse<T>> handleApiCall<T>(
    Future<ApiResponse<T>> apiCall, {
    String? errorMessage,
  }) async {
    try {
      final response = await apiCall;
      return response;
    } catch (e) {
      return ApiResponse.error(
        NetworkException.defaultError(
          errorMessage ?? 'An unexpected error occurred',
        ),
      );
    }
  }

  // Common error handling for repositories
  Future<ApiResponse<List<T>>> handleListResponse<T>(
    Future<ApiResponse<dynamic>> apiCall,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await apiCall;

    return response.when(
      success: (data) {
        try {
          if (data is List) {
            final items = data
                .cast<Map<String, dynamic>>()
                .map((item) => fromJson(item))
                .toList();
            return ApiResponse.success(items);
          } else if (data is Map<String, dynamic> && data.containsKey('data')) {
            final List<dynamic> dataList = data['data'] as List<dynamic>;
            final items = dataList
                .cast<Map<String, dynamic>>()
                .map((item) => fromJson(item))
                .toList();
            return ApiResponse.success(items);
          } else {
            return ApiResponse.error(
              NetworkException.formatException(
                'Expected list but got ${data.runtimeType}',
              ),
            );
          }
        } catch (e) {
          return ApiResponse.error(
            NetworkException.formatException('Failed to parse list: $e'),
          );
        }
      },
      error: (error) => ApiResponse.error(error),
    );
  }

  Future<ApiResponse<T>> handleObjectResponse<T>(
    Future<ApiResponse<dynamic>> apiCall,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await apiCall;

    return response.when(
      success: (data) {
        try {
          if (data is Map<String, dynamic>) {
            AppLogger.log('handleObjectResponse - Full data: $data'); // Debug

            // Don't extract the 'data' field - let the model handle its own structure
            final item = fromJson(data);
            return ApiResponse.success(item);
          } else {
            return ApiResponse.error(
              NetworkException.formatException(
                'Expected object but got ${data.runtimeType}',
              ),
            );
          }
        } catch (e, stackTrace) {
          AppLogger.log('handleObjectResponse error: $e');
          AppLogger.log('Stack trace: $stackTrace');
          return ApiResponse.error(
            NetworkException.formatException('Failed to parse object: $e'),
          );
        }
      },
      error: (error) => ApiResponse.error(error),
    );
  }

  Future<ApiResponse<T>> handleWrappedObjectResponse<T>(
    Future<ApiResponse<dynamic>> apiCall,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await apiCall;

    return response.when(
      success: (data) {
        try {
          if (data is Map<String, dynamic>) {
            // For APIs that return data wrapped in a 'data' field
            final Map<String, dynamic> objectData = data.containsKey('data')
                ? data['data'] as Map<String, dynamic>
                : data;
            final item = fromJson(objectData);
            return ApiResponse.success(item);
          } else {
            return ApiResponse.error(
              NetworkException.formatException(
                'Expected object but got ${data.runtimeType}',
              ),
            );
          }
        } catch (e) {
          return ApiResponse.error(
            NetworkException.formatException('Failed to parse object: $e'),
          );
        }
      },
      error: (error) => ApiResponse.error(error),
    );
  }

  // Handle paginated response
  Future<ApiResponse<PaginatedResponse<T>>> handlePaginatedResponse<T>(
    Future<ApiResponse<dynamic>> apiCall,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await apiCall;

    return response.when(
      success: (data) {
        try {
          if (data is Map<String, dynamic>) {
            final paginatedResponse = PaginatedResponse<T>.fromJson(
              data,
              fromJson,
            );
            return ApiResponse.success(paginatedResponse);
          } else {
            return ApiResponse.error(
              NetworkException.formatException(
                'Expected paginated object but got ${data.runtimeType}',
              ),
            );
          }
        } catch (e) {
          return ApiResponse.error(
            NetworkException.formatException(
              'Failed to parse paginated response: $e',
            ),
          );
        }
      },
      error: (error) => ApiResponse.error(error),
    );
  }
}

// lib/core/network/paginated_response.dart
class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final List<dynamic> dataList = json['data'] ?? json['items'] ?? [];
    final data = dataList
        .cast<Map<String, dynamic>>()
        .map((item) => fromJsonT(item))
        .toList();

    return PaginatedResponse<T>(
      data: data,
      currentPage: json['current_page'] ?? json['page'] ?? 1,
      totalPages: json['total_pages'] ?? json['last_page'] ?? 1,
      totalItems: json['total'] ?? json['total_count'] ?? data.length,
      itemsPerPage: json['per_page'] ?? json['limit'] ?? data.length,
      hasNextPage: (json['current_page'] ?? 1) < (json['total_pages'] ?? 1),
      hasPreviousPage: (json['current_page'] ?? 1) > 1,
    );
  }
}
