import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/procurement_req_model.dart';

abstract class ProcurementRequestRepositoryInterface {
  Future<ApiResponse<ProcurementRequestResponse>> createProcurementRequest({
    required CreateProcurementRequest request,
  });
}

class ProcurementRequestRepository extends BaseRepository
    implements ProcurementRequestRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  @override
  Future<ApiResponse<ProcurementRequestResponse>> createProcurementRequest({
    required CreateProcurementRequest request,
  }) async {
    try {
      _validateProcurementRequest(request);

      final response = await _apiClient
          .post('/procurement/requests', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Invalid response from server');
      }

      // FIX: Check if data is wrapped or not
      final responseData = response.data is Map<String, dynamic>
          ? (response.data.containsKey('data')
                ? response.data['data'] as Map<String, dynamic>
                : response.data as Map<String, dynamic>)
          : throw FormatException('Invalid response format');

      return ApiResponse.success(
        ProcurementRequestResponse.fromJson(responseData),
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

  void _validateProcurementRequest(CreateProcurementRequest request) {
    if (request.branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }
    if (request.requestedBy.isEmpty) {
      throw FormatException('Requested by field cannot be empty');
    }
    if (request.requestingDepartment.isEmpty) {
      throw FormatException('Requesting department cannot be empty');
    }
    if (request.priority.isEmpty) {
      throw FormatException('Priority cannot be empty');
    }
    if (request.urgencyLevel.isEmpty) {
      throw FormatException('Urgency level cannot be empty');
    }
    if (request.urgencyReason.isEmpty) {
      throw FormatException('Urgency reason cannot be empty');
    }
    if (request.expectedDelivery.isEmpty) {
      throw FormatException('Expected delivery date cannot be empty');
    }
    if (request.primaryCategory.isEmpty) {
      throw FormatException('Primary category cannot be empty');
    }
    if (request.items.isEmpty) {
      throw FormatException('At least one item must be added');
    }

    // Validate each item
    for (var item in request.items) {
      if (item.itemId.isEmpty) {
        throw FormatException('Item ID cannot be empty');
      }
      if (item.qtyNeeded <= 0) {
        throw FormatException('Quantity needed must be greater than 0');
      }
      if (item.unitCost < 0) {
        throw FormatException('Unit cost cannot be negative');
      }
      if (item.currentStock < 0) {
        throw FormatException('Current stock cannot be negative');
      }
      if (item.minLevel < 0) {
        throw FormatException('Minimum level cannot be negative');
      }
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
      return 'Resource not found.';
    }

    if (lowercaseError.contains('409') || lowercaseError.contains('conflict')) {
      return 'Conflict detected. Please check your data.';
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

    return 'Failed to process request. Please try again later.';
  }
}
