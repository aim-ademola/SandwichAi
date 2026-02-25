import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/kitchen/data/model/kitchen_dash_model.dart';

import '../../../../core/config/prod_print.dart';

abstract class KitchenDashboardRepositoryInterface {
  Future<ApiResponse<KitchenDashboardData>> getDashboardData({
    required String branchId,
  });

  Future<ApiResponse<void>> updateOrderStatus({
    required String orderId,
    required String status,
    required String updatedBy,
  });
}

class KitchenDashboardRepository extends BaseRepository
    implements KitchenDashboardRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<KitchenDashboardData>> getDashboardData({
    required String branchId,
  }) async {
    try {
      _validateBranchId(branchId);

      final queryParams = <String, dynamic>{'branchId': branchId};

      AppLogger.log(
        'DEBUG REPO: Fetching dashboard data for branch: $branchId',
      );

      final response = await _apiClient
          .get('kitchen/dashboard', queryParameters: queryParams)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      AppLogger.log('DEBUG REPO: Dashboard response received');
      AppLogger.log('DEBUG REPO: Response type: ${response.runtimeType}');

      // The response is already an ApiResponse, so we need to check if it succeeded
      return response.when(
        success: (data) {
          AppLogger.log('DEBUG REPO: Response data received');

          if (data == null) {
            AppLogger.log('DEBUG REPO: Response data is null');
            return ApiResponse.errorMessage('No data received from server');
          }

          final dashboardData = KitchenDashboardData.fromJson(data);
          AppLogger.log('DEBUG REPO: Dashboard data parsed successfully');
          return ApiResponse.success(dashboardData);
        },
        error: (error) {
          AppLogger.log('DEBUG REPO: Response returned error: $error');
          return ApiResponse.errorMessage(error.toString());
        },
      );
    } on DioException catch (e) {
      AppLogger.log('DEBUG REPO: DioException - ${e.message}');
      AppLogger.log('DEBUG REPO: Response data - ${e.response?.data}');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return ApiResponse.errorMessage(
          'Connection timeout. Please check your internet and try again.',
        );
      }

      if (e.type == DioExceptionType.connectionError) {
        return ApiResponse.errorMessage(
          'No internet connection. Please check your network settings.',
        );
      }

      final errorMessage =
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Failed to fetch dashboard data';
      return ApiResponse.errorMessage(errorMessage);
    } on SocketException catch (e) {
      AppLogger.log('DEBUG REPO: SocketException - $e');
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      AppLogger.log('DEBUG REPO: TimeoutException - $e');
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      AppLogger.log('DEBUG REPO: FormatException - ${e.message}');
      return ApiResponse.errorMessage(e.message);
    } catch (e, stackTrace) {
      AppLogger.log('DEBUG REPO: Unexpected error - $e');
      AppLogger.log('DEBUG REPO: Error type: ${e.runtimeType}');
      AppLogger.log('DEBUG REPO: Stack trace - $stackTrace');
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<void>> updateOrderStatus({
    required String orderId,
    required String status,
    required String updatedBy,
  }) async {
    try {
      _validateOrderId(orderId);
      _validateStatus(status);
      _validateUpdatedBy(updatedBy);

      final requestBody = {'status': status, 'updatedBy': updatedBy};

      AppLogger.log(
        'DEBUG REPO: Updating order $orderId to status $status by $updatedBy',
      );
      AppLogger.log('DEBUG REPO: Request body: $requestBody');

      final response = await _apiClient
          .patch('kitchen/orders/$orderId/status', data: requestBody)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      AppLogger.log('DEBUG REPO: Update response received');
      AppLogger.log('DEBUG REPO: Response type: ${response.runtimeType}');

      // The response is already an ApiResponse, so we handle it accordingly
      return response.when(
        success: (data) {
          AppLogger.log('DEBUG REPO: ✅ Order status updated successfully');
          AppLogger.log('DEBUG REPO: Response data: $data');
          return ApiResponse.success(null);
        },
        error: (error) {
          AppLogger.log('DEBUG REPO: ❌ Update failed with error: $error');
          return ApiResponse.errorMessage(error.toString());
        },
      );
    } on DioException catch (e) {
      AppLogger.log('DEBUG REPO: DioException - ${e.message}');
      AppLogger.log('DEBUG REPO: DioException type - ${e.type}');
      AppLogger.log('DEBUG REPO: Response status - ${e.response?.statusCode}');
      AppLogger.log('DEBUG REPO: Response data - ${e.response?.data}');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return ApiResponse.errorMessage(
          'Connection timeout. Please check your internet and try again.',
        );
      }

      if (e.type == DioExceptionType.connectionError) {
        return ApiResponse.errorMessage(
          'No internet connection. Please check your network settings.',
        );
      }

      // Try to get error message from response
      String errorMessage = 'Failed to update order status';

      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          errorMessage =
              e.response!.data['message']?.toString() ??
              e.response!.data['error']?.toString() ??
              errorMessage;
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      return ApiResponse.errorMessage(errorMessage);
    } on SocketException catch (e) {
      AppLogger.log('DEBUG REPO: SocketException - $e');
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      AppLogger.log('DEBUG REPO: TimeoutException - $e');
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      AppLogger.log('DEBUG REPO: FormatException - ${e.message}');
      return ApiResponse.errorMessage(e.message);
    } catch (e, stackTrace) {
      AppLogger.log('DEBUG REPO: Unexpected error - $e');
      AppLogger.log('DEBUG REPO: Error type - ${e.runtimeType}');
      AppLogger.log('DEBUG REPO: Stack trace - $stackTrace');
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  void _validateBranchId(String branchId) {
    if (branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }
  }

  void _validateOrderId(String orderId) {
    if (orderId.isEmpty) {
      throw FormatException('Order ID cannot be empty');
    }
  }

  void _validateStatus(String status) {
    const validStatuses = [
      'PENDING',
      'PREPARING',
      'READY',
      'COMPLETED',
      'CANCELLED',
    ];
    if (!validStatuses.contains(status.toUpperCase())) {
      throw FormatException(
        'Invalid status. Must be one of: ${validStatuses.join(", ")}',
      );
    }
  }

  void _validateUpdatedBy(String updatedBy) {
    if (updatedBy.isEmpty) {
      throw FormatException('Updated by (employee ID) cannot be empty');
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
      return 'Order not found.';
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
