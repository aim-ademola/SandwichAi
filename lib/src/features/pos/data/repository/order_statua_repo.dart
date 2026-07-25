import 'dart:async';
import 'dart:io';

import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/model/oder_status_model.dart';

abstract class KitchenOrdersRepositoryInterface {
  Future<ApiResponse<List<KitchenOrder>>> getKitchenOrders({
    required String branchId,
    String? startDate,
    String? endDate,
    String? status,
  });
}

class KitchenOrdersRepository extends BaseRepository
    implements KitchenOrdersRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<List<KitchenOrder>>> getKitchenOrders({
    required String branchId,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    try {
      _validateBranchId(branchId);

      final queryParams = <String, dynamic>{'branchId': branchId};
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final response = await _apiClient
          .get('kitchen/orders', queryParameters: queryParams)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw TimeoutException('Request timed out. Please try again.'),
          );

      return response.when(
        success: (data) {
          if (data == null) {
            return ApiResponse.errorMessage('No orders data received.');
          }
          final list = (data as List<dynamic>)
              .map((e) => KitchenOrder.fromJson(e as Map<String, dynamic>))
              .toList();
          return ApiResponse.success(list);
        },
        error: (error) => ApiResponse.errorMessage(error.toString()),
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(
        e.message.isNotEmpty ? e.message : 'Invalid data format received.',
      );
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
      throw const FormatException('Branch ID cannot be empty.');
    }
  }

  String _parseErrorMessage(String error, {int? statusCode}) {
    const fallback = 'Failed to load orders. Please try again later.';
    final code = statusCode ?? 0;
    final lower = error.toLowerCase();

    if (code == 401 || lower.contains('unauthorized')) {
      return 'Unauthorized access. Please login again.';
    }
    if (code == 403 || lower.contains('forbidden')) {
      if (lower.contains('missing permission')) {
        return 'Permission denied: $error';
      }
      return 'Access denied. Please contact support.';
    }
    if (code == 404 || lower.contains('not found')) {
      return 'No orders found for this branch.';
    }
    if (code >= 500 || lower.contains('internal server')) {
      return 'Server error. Please try again later.';
    }
    if (lower.contains('503') || lower.contains('service unavailable')) {
      return 'Service temporarily unavailable. Please try again later.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (lower.contains('timeout')) return 'Request timeout. Please try again.';

    return fallback;
  }
}
