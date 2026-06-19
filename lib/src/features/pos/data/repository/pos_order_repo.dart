import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/pos/data/model/pos_order_model.dart';

abstract class PosOrderRepositoryInterface {
  Future<ApiResponse<PosOrderResponseModel>> createPosOrder({
    required String branchId,
    required String orderType,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
    required List<PosOrderItemPayload> items,
    required double discount,
    String? specialInstructions,
    required String takenBy,
  });
}

class PosOrderItemPayload {
  final String menuItemId;
  final int quantity;
  final String? specialRequest;

  PosOrderItemPayload({
    required this.menuItemId,
    required this.quantity,
    this.specialRequest,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'menuItemId': menuItemId,
      'quantity': quantity,
    };

    if (specialRequest != null && specialRequest!.isNotEmpty) {
      json['specialRequest'] = specialRequest;
    }

    return json;
  }
}

class PosOrderRepository extends BaseRepository
    implements PosOrderRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<PosOrderResponseModel>> createPosOrder({
    required String branchId,
    required String orderType,
    String? tableNumber,
    String? customerName,
    String? customerPhone,
    required List<PosOrderItemPayload> items,
    required double discount,
    String? specialInstructions,
    required String takenBy,
  }) async {
    try {
      // Validate required fields
      _validateBranchId(branchId);
      _validateOrderType(orderType);
      _validateTakenBy(takenBy);
      _validateItems(items);
      _validateDiscount(discount);

      // Build request body
      final Map<String, dynamic> requestBody = {
        'branchId': branchId,
        'orderType': orderType,
        'items': items.map((item) => item.toJson()).toList(),
        'discount': discount,
        'takenBy': takenBy,
      };

      // Add optional fields only if they have values
      if (tableNumber != null && tableNumber.isNotEmpty) {
        requestBody['tableNumber'] = tableNumber;
      }
      if (customerName != null && customerName.isNotEmpty) {
        requestBody['customerName'] = customerName;
      }
      if (customerPhone != null && customerPhone.isNotEmpty) {
        requestBody['customerPhone'] = customerPhone;
      }
      if (specialInstructions != null && specialInstructions.isNotEmpty) {
        requestBody['specialInstructions'] = specialInstructions;
      }

      // Make API request
      final response = await _apiClient
          .post('kitchen/orders', data: requestBody)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      // Parse response
      if (response.data == null) {
        return ApiResponse.errorMessage('Failed to create order');
      }

      final order = PosOrderResponseModel.fromJson(response.data);
      return ApiResponse.success(order);
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

  // Validation methods
  void _validateBranchId(String branchId) {
    if (branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }
  }

  void _validateOrderType(String orderType) {
    const validTypes = [
      'DINE_IN',
      'TAKEAWAY',
      'DELIVERY',
      'ONLINE',
    ]; // ← fix this
    if (orderType.isEmpty) {
      throw FormatException('Order type cannot be empty');
    }
    if (!validTypes.contains(orderType)) {
      throw FormatException(
        'Invalid order type. Must be one of: ${validTypes.join(', ')}',
      );
    }
  }

  void _validateTakenBy(String takenBy) {
    if (takenBy.isEmpty) {
      throw FormatException('Employee ID (takenBy) cannot be empty');
    }
  }

  void _validateItems(List<PosOrderItemPayload> items) {
    if (items.isEmpty) {
      throw FormatException('Order must contain at least one item');
    }

    for (var item in items) {
      if (item.menuItemId.isEmpty) {
        throw FormatException('Menu item ID cannot be empty');
      }
      if (item.quantity <= 0) {
        throw FormatException('Item quantity must be greater than zero');
      }
    }
  }

  void _validateDiscount(double discount) {
    if (discount < 0) {
      throw FormatException('Discount cannot be negative');
    }
  }

  // Error message parser
  String _parseErrorMessage(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('401') ||
        lowercaseError.contains('unauthorized')) {
      return 'Unauthorized access. Please login again.';
    }
    if (lowercaseError.contains('403') ||
        lowercaseError.contains('forbidden')) {
      return 'Access denied. You do not have permission to create orders.';
    }
    if (lowercaseError.contains('404') ||
        lowercaseError.contains('not found')) {
      return 'Order endpoint not found. Please contact support.';
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

    // Don't swallow 400 errors — return the raw error so API validation
    // messages like "orderType must be one of..." surface to the user
    return error;
  }
}
