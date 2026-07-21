import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_action_model.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_model.dart';

// Repository
abstract class PurchaseOrdersRepositoryInterface {
  Future<ApiResponse<OrdersListResponse>> getPurchaseOrders({
    String? status,
    String? deliveryStatus,
    String? paymentStatus,
    String? supplierId,
    String? buyerBranchId,
    String? priority,
    String? primaryCategory,
    String? search,
    String? orderDateFrom,
    String? orderDateTo,
    String? deliveryDateFrom,
    String? deliveryDateTo,
    double? minAmount,
    double? maxAmount,
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  });

  Future<ApiResponse<OrdersListResponse>> getPendingApprovalOrders({
    int page = 1,
    int limit = 10,
  });

  Future<ApiResponse<OrdersListResponse>> getOverdueDeliveries({
    int page = 1,
    int limit = 10,
  });

  Future<ApiResponse<PurchaseOrderTimelineResponse>> getOrderTimeline({
    String? orderId,
    String? dateFrom,
    String? dateTo,
  });
}

class PurchaseOrdersRepository extends BaseRepository
    implements PurchaseOrdersRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<OrdersListResponse>> getPurchaseOrders({
    String? status,
    String? deliveryStatus,
    String? paymentStatus,
    String? supplierId,
    String? buyerBranchId,
    String? priority,
    String? primaryCategory,
    String? search,
    String? orderDateFrom,
    String? orderDateTo,
    String? deliveryDateFrom,
    String? deliveryDateTo,
    double? minAmount,
    double? maxAmount,
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final trimmedSearch = search?.trim() ?? '';
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (deliveryStatus != null && deliveryStatus.isNotEmpty) {
        queryParams['deliveryStatus'] = deliveryStatus;
      }
      if (paymentStatus != null && paymentStatus.isNotEmpty) {
        queryParams['paymentStatus'] = paymentStatus;
      }
      if (supplierId != null && supplierId.isNotEmpty) {
        queryParams['supplierId'] = supplierId;
      }
      if (buyerBranchId != null && buyerBranchId.isNotEmpty) {
        queryParams['buyerBranchId'] = buyerBranchId;
      }
      if (priority != null && priority.isNotEmpty) {
        queryParams['priority'] = priority;
      }
      if (primaryCategory != null && primaryCategory.isNotEmpty) {
        queryParams['primaryCategory'] = primaryCategory;
      }
      if (trimmedSearch.isNotEmpty) {
        queryParams['search'] = trimmedSearch;
      }
      if (orderDateFrom != null && orderDateFrom.isNotEmpty) {
        queryParams['orderDateFrom'] = orderDateFrom;
      }
      if (orderDateTo != null && orderDateTo.isNotEmpty) {
        queryParams['orderDateTo'] = orderDateTo;
      }
      if (deliveryDateFrom != null && deliveryDateFrom.isNotEmpty) {
        queryParams['deliveryDateFrom'] = deliveryDateFrom;
      }
      if (deliveryDateTo != null && deliveryDateTo.isNotEmpty) {
        queryParams['deliveryDateTo'] = deliveryDateTo;
      }
      if (minAmount != null) queryParams['minAmount'] = minAmount;
      if (maxAmount != null) queryParams['maxAmount'] = maxAmount;

      final response = await _apiClient
          .get('/procurement/orders', queryParameters: queryParams)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (data) {
          if (data is Map && data['statusCode'] != null) {
            final statusCode = data['statusCode'];
            if (statusCode is num && statusCode >= 400) {
              return ApiResponse.errorMessage(
                _parseErrorFromResponse(Map<String, dynamic>.from(data)),
              );
            }
          }

          if (data is! Map) {
            return ApiResponse.errorMessage('Invalid response from server');
          }

          try {
            final ordersResponse = OrdersListResponse.fromJson(
              Map<String, dynamic>.from(data),
            );
            return ApiResponse.success(ordersResponse);
          } on Object catch (error, stackTrace) {
            AppLogger.log('Purchase orders parse error: $error');
            AppLogger.log('Purchase orders response: $data');
            AppLogger.log('Purchase orders stack: $stackTrace');
            return ApiResponse.errorMessage(
              'Invalid purchase orders response format.',
            );
          }
        },
        error: (error) => ApiResponse.error(error),
      );
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
  Future<ApiResponse<OrdersListResponse>> getPendingApprovalOrders({
    int page = 1,
    int limit = 10,
  }) {
    return _getOrders(
      '/procurement/orders/approval/pending',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  @override
  Future<ApiResponse<OrdersListResponse>> getOverdueDeliveries({
    int page = 1,
    int limit = 10,
  }) {
    return _getOrders(
      '/procurement/orders/overdue-deliveries',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  @override
  Future<ApiResponse<PurchaseOrderTimelineResponse>> getOrderTimeline({
    String? orderId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
        if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
      };

      final response = await _apiClient
          .get(
            '/procurement/orders/timeline',
            queryParameters: queryParameters.isNotEmpty
                ? queryParameters
                : null,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (data) {
          final json = data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};
          return ApiResponse.success(
            PurchaseOrderTimelineResponse.fromJson(json),
          );
        },
        error: (error) => ApiResponse.error(error),
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

  Future<ApiResponse<OrdersListResponse>> _getOrders(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _apiClient
          .get(endpoint, queryParameters: queryParameters)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (data) {
          if (data is! Map) {
            return ApiResponse.errorMessage('Invalid response from server');
          }
          try {
            return ApiResponse.success(
              OrdersListResponse.fromJson(Map<String, dynamic>.from(data)),
            );
          } on Object catch (error, stackTrace) {
            AppLogger.log('Purchase orders parse error: $error');
            AppLogger.log('Purchase orders response: $data');
            AppLogger.log('Purchase orders stack: $stackTrace');
            return ApiResponse.errorMessage(
              'Invalid purchase orders response format.',
            );
          }
        },
        error: (error) => ApiResponse.error(error),
      );
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

  String _parseErrorFromResponse(Map<String, dynamic> data) {
    final statusCode = data['statusCode'];
    final message = data['message'] ?? 'An error occurred';

    if (statusCode == 500) {
      return 'Server error. Please try again later.';
    } else if (statusCode == 404) {
      return 'Orders not found.';
    } else if (statusCode == 401) {
      return 'Unauthorized. Please login again.';
    } else if (statusCode == 403) {
      return 'Access forbidden.';
    }

    return message;
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
      return 'Orders not found.';
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

    return 'Failed to load orders. Please try again later.';
  }
}
