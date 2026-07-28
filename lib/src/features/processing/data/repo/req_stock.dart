import 'dart:async';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/core/network/connectivity_service.dart';
import 'package:sandwich_ai/src/core/offline/offline_queue_manager.dart';
import 'package:sandwich_ai/src/core/offline/pending_req.dart';
import 'package:sandwich_ai/src/features/processing/data/model/req_stock_model.dart';

abstract class StockRequestRepositoryInterface {
  Future<ApiResponse<StockRequestResponse>> getStockRequests({
    required String branchId,
    String? status,
  });

  Future<ApiResponse<CreateStockRequestResponse>> createStockRequest(
    CreateStockRequestRequest request,
  );

  Future<ApiResponse<StockRequest>> getStockRequestDetails(String requestId);

  Future<ApiResponse<StockRequest>> completeStockRequest(String requestId);
}

class StockRequestRepository extends BaseRepository
    implements StockRequestRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<StockRequestResponse>> getStockRequests({
    required String branchId,
    String? status,
  }) async {
    try {
      if (branchId.isEmpty) {
        return ApiResponse.errorMessage('Branch ID is required');
      }

      final online = await ConnectivityService.instance.isOnline;

      if (!online) {
        return ApiResponse.errorMessage(
          'No internet connection. Please check your network.',
        );
      }

      final queryParams = <String, dynamic>{'branchId': branchId};

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiClient
          .get('stock-requests', queryParameters: queryParams)
          .timeout(const Duration(seconds: 30));

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseStockRequestsResponse(json),
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<CreateStockRequestResponse>> createStockRequest(
    CreateStockRequestRequest request,
  ) async {
    try {
      _validateCreateRequest(request);

      final online = await ConnectivityService.instance.isOnline;

      if (!online) {
        await OfflineQueueManager.instance.add(
          PendingRequest(
            method: "POST",
            url: "stock-requests",
            body: request.toJson(),
          ),
          onSaved: () {
            // Optional: show toast notification
          },
        );

        return ApiResponse.errorMessage(
          "No internet. Request saved and will sync automatically.",
        );
      }

      final response = await _apiClient
          .post('stock-requests', data: request.toJson())
          .timeout(const Duration(seconds: 30));

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseCreateStockRequestResponse(json),
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<StockRequest>> getStockRequestDetails(
    String requestId,
  ) async {
    try {
      if (requestId.isEmpty) {
        return ApiResponse.errorMessage('Request ID is required');
      }

      final online = await ConnectivityService.instance.isOnline;

      if (!online) {
        return ApiResponse.errorMessage(
          'No internet connection. Please check your network.',
        );
      }

      final response = await _apiClient
          .get('stock-requests/$requestId')
          .timeout(const Duration(seconds: 30));

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseStockRequestDetails(json),
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<StockRequest>> completeStockRequest(
    String requestId,
  ) async {
    try {
      if (requestId.isEmpty) {
        return ApiResponse.errorMessage('Request ID is required');
      }

      final online = await ConnectivityService.instance.isOnline;

      if (!online) {
        return ApiResponse.errorMessage(
          'No internet connection. Please check your network.',
        );
      }

      final response = await _apiClient
          .patch('stock-requests/$requestId/complete')
          .timeout(const Duration(seconds: 30));

      if (response.data == null) {
        return ApiResponse.errorMessage('Invalid response from server');
      }

      // Parse the response
      final responseData = response.data is Map<String, dynamic>
          ? (response.data.containsKey('data')
                ? response.data['data'] as Map<String, dynamic>
                : response.data as Map<String, dynamic>)
          : throw FormatException('Invalid response format');

      return ApiResponse.success(StockRequest.fromJson(responseData));
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  void _validateCreateRequest(CreateStockRequestRequest request) {
    if (request.requestingBranchId.isEmpty) {
      throw FormatException('Requesting branch ID cannot be empty');
    }
    if (request.issuingBranchId != null &&
        request.issuingBranchId!.isNotEmpty &&
        request.issuingBranchId == request.requestingBranchId) {
      throw FormatException(
        'Leave issuing branch empty for interdepartment stock requests',
      );
    }

    if (request.requestedBy.isEmpty) {
      throw FormatException('Requested by cannot be empty');
    }

    if (request.department.isEmpty) {
      throw FormatException('Department cannot be empty');
    }

    if (request.items.isEmpty) {
      throw FormatException('At least one item is required');
    }

    for (final item in request.items) {
      if (item.itemId.isEmpty) {
        throw FormatException('Item ID cannot be empty');
      }

      if (item.qtyRequested <= 0) {
        throw FormatException('Quantity must be greater than zero');
      }
    }
  }

  StockRequestResponse _parseStockRequestsResponse(Map<String, dynamic> json) {
    try {
      final response = StockRequestResponse.fromJson(json);
      return response;
    } catch (e) {
      throw FormatException('Unable to process response: ${e.toString()}');
    }
  }

  CreateStockRequestResponse _parseCreateStockRequestResponse(
    Map<String, dynamic> json,
  ) {
    try {
      final response = CreateStockRequestResponse.fromJson(json);

      if (!response.isValid) {
        throw FormatException(
          response.message.isNotEmpty
              ? response.message
              : 'Invalid stock request data received',
        );
      }

      return response;
    } catch (e) {
      throw FormatException('Unable to process response: ${e.toString()}');
    }
  }

  StockRequest _parseStockRequestDetails(Map<String, dynamic> json) {
    try {
      return StockRequest.fromJson(json['data'] ?? json);
    } catch (e) {
      throw FormatException('Unable to process response: ${e.toString()}');
    }
  }

  String _parseErrorMessage(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('401') ||
        lowercaseError.contains('unauthorized')) {
      return 'Unauthorized. Please log in again.';
    }

    if (lowercaseError.contains('403') ||
        lowercaseError.contains('forbidden')) {
      return 'Access denied. You do not have permission.';
    }

    if (lowercaseError.contains('404') ||
        lowercaseError.contains('not found')) {
      return 'Stock request not found.';
    }

    if (lowercaseError.contains('409') || lowercaseError.contains('conflict')) {
      return 'Stock request already exists.';
    }

    if (lowercaseError.contains('422') ||
        lowercaseError.contains('unprocessable')) {
      return 'Invalid data provided. Please check your input.';
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

    return 'Operation failed. Please try again later.';
  }
}
