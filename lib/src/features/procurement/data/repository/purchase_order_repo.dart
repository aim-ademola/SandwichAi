import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';

abstract class OrderRepositoryInterface {
  Future<ApiResponse<Map<String, dynamic>>> createOrder({
    required String supplierId,
    required String buyerId,
    required String buyerBranchId,
    required String priority,
    required String expectedDeliveryDate,
    required String paymentTerm,
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryState,
    required String orgId,
    String? deliveryInstructions,
    String? buyerNotes,
    required List<OrderItemRequest> items,
  });
}

class OrderRepository implements OrderRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  OrderRepository();

  @override
  Future<ApiResponse<Map<String, dynamic>>> createOrder({
    required String supplierId,
    required String buyerId,
    required String buyerBranchId,
    required String priority,
    required String expectedDeliveryDate,
    required String paymentTerm,
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryState,
    required String orgId,
    String? deliveryInstructions,
    String? buyerNotes,
    required List<OrderItemRequest> items,
  }) async {
    try {
      final response = await _apiClient
          .post(
            '/procurement/orders',
            data: {
              'supplierId': supplierId,
              'buyerId': buyerId,
              'buyerBranchId': buyerBranchId,
              'priority': priority,
              'expectedDeliveryDate': expectedDeliveryDate,
              'paymentTerm': paymentTerm,
              'organizationId': orgId,
              'deliveryAddress': deliveryAddress,
              'deliveryCity': deliveryCity,
              'deliveryState': deliveryState,
              if (deliveryInstructions != null)
                'deliveryInstructions': deliveryInstructions,
              if (buyerNotes != null) 'buyerNotes': buyerNotes,
              'items': items.map((item) => item.toJson()).toList(),
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      final data = response.data;

      // Check for error response
      if (data is Map<String, dynamic>) {
        if (data['statusCode'] != null) {
          final statusCode = data['statusCode'];
          if (statusCode >= 400) {
            return ApiResponse.errorMessage(_parseErrorFromResponse(data));
          }
        }

        // Success response
        return ApiResponse.success(data);
      }

      return ApiResponse.success(<String, dynamic>{});
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

  String _parseErrorFromResponse(Map<String, dynamic> data) {
    final statusCode = data['statusCode'];
    final message = data['message'] ?? 'An error occurred';

    if (statusCode == 500) {
      return 'Server error. Please try again later.';
    } else if (statusCode == 404) {
      return 'Resource not found. Please check if the branch ID is valid.';
    } else if (statusCode == 401) {
      return 'Unauthorized. Please login again.';
    } else if (statusCode == 403) {
      return 'Access forbidden.';
    } else if (statusCode == 400) {
      return message; // Return the actual validation error message
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
      return 'Resource not found. Please check if the branch ID is valid.';
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

    if (lowercaseError.contains('branch')) {
      return 'Invalid branch. Please ensure you have selected a valid branch.';
    }

    return 'Failed to create order. Please try again later.';
  }
}

class OrderItemRequest {
  final String productId;
  final int quantityOrdered;
  final String? notes;

  OrderItemRequest({
    required this.productId,
    required this.quantityOrdered,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantityOrdered': quantityOrdered,
    if (notes != null) 'notes': notes,
  };
}
