import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_model.dart';

// Repository
abstract class PurchaseOrdersRepositoryInterface {
  Future<ApiResponse<OrdersListResponse>> getPurchaseOrders({
    String? status,
    String? deliveryStatus,
    String? paymentStatus,
    String? supplierId,
    String buyerBranchId,
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
      final queryParams = <String, dynamic>{
        // 'page': page,
        // 'limit': limit,
        // 'sortBy': sortBy,
        // 'sortOrder': sortOrder,
      };

      // if (status != null && status.isNotEmpty) queryParams['status'] = status;
      // if (deliveryStatus != null && deliveryStatus.isNotEmpty) {
      //   queryParams['deliveryStatus'] = deliveryStatus;
      // }
      // if (paymentStatus != null && paymentStatus.isNotEmpty) {
      //   queryParams['paymentStatus'] = paymentStatus;
      // }
      // if (supplierId != null && supplierId.isNotEmpty) {
      //   queryParams['supplierId'] = supplierId;
      // }
      if (buyerBranchId != null && buyerBranchId.isNotEmpty) {
        queryParams['buyerBranchId'] = buyerBranchId;
      }
      // if (priority != null && priority.isNotEmpty) {
      //   queryParams['priority'] = priority;
      // }
      // if (primaryCategory != null && primaryCategory.isNotEmpty) {
      //   queryParams['primaryCategory'] = primaryCategory;
      // }
      // if (search != null && search.isNotEmpty) {
      //   queryParams['search'] = search;
      // }
      // if (orderDateFrom != null && orderDateFrom.isNotEmpty) {
      //   queryParams['orderDateFrom'] = orderDateFrom;
      // }
      // if (orderDateTo != null && orderDateTo.isNotEmpty) {
      //   queryParams['orderDateTo'] = orderDateTo;
      // }
      // if (deliveryDateFrom != null && deliveryDateFrom.isNotEmpty) {
      //   queryParams['deliveryDateFrom'] = deliveryDateFrom;
      // }
      // if (deliveryDateTo != null && deliveryDateTo.isNotEmpty) {
      //   queryParams['deliveryDateTo'] = deliveryDateTo;
      // }
      // if (minAmount != null) queryParams['minAmount'] = minAmount;
      // if (maxAmount != null) queryParams['maxAmount'] = maxAmount;

      final response = await _apiClient
          .get('/procurement/orders', queryParameters: queryParams)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      // Check for error response
      if (response.data is Map && response.data['statusCode'] != null) {
        final statusCode = response.data['statusCode'];
        if (statusCode >= 400) {
          return ApiResponse.errorMessage(
            _parseErrorFromResponse(response.data),
          );
        }
      }

      final ordersResponse = OrdersListResponse.fromJson(response.data);
      return ApiResponse.success(ordersResponse);
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
