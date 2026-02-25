import 'dart:async';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/core/network/connectivity_service.dart';
import 'package:sandwich_ai/src/core/offline/offline_queue_manager.dart';
import 'package:sandwich_ai/src/core/offline/pending_req.dart';
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/data/model/stock_reuest_model.dart';

abstract class StockRequestRepositoryInterface {
  Future<ApiResponse<StockRequestResponse>> getStockRequests({
    required String branchId,
    String? status,
  });

  Future<ApiResponse<CreateStockRequestResponse>> createStockRequest(
    CreateStockRequestRequest request,
  );

  Future<ApiResponse<StockRequest>> getStockRequestDetails(String requestId);

  /// Unified action method — replaces completeStockRequest and future equivalents
  Future<ApiResponse<StockRequest>> performAction(
    String requestId,
    StockRequestAction action,
  );

  Future<ApiResponse<Map<String, dynamic>>> getStockRequestStatus(
    String requestId,
  );
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

      if (!await ConnectivityService.instance.isOnline) {
        return ApiResponse.errorMessage(
          'No internet connection. Please check your network.',
        );
      }

      final queryParams = <String, dynamic>{'branchId': branchId};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final response = await _apiClient
          .get('stock-requests', queryParameters: queryParams)
          .timeout(const Duration(seconds: 30));

      return handleObjectResponse(
        Future.value(response),
        _parseStockRequestsResponse,
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

      if (!await ConnectivityService.instance.isOnline) {
        await OfflineQueueManager.instance.add(
          PendingRequest(
            method: "POST",
            url: "stock-requests",
            body: request.toJson(),
          ),
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
        _parseCreateStockRequestResponse,
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

      if (!await ConnectivityService.instance.isOnline) {
        return ApiResponse.errorMessage(
          'No internet connection. Please check your network.',
        );
      }

      final response = await _apiClient
          .get('stock-requests/$requestId')
          .timeout(const Duration(seconds: 30));

      return handleObjectResponse(
        Future.value(response),
        _parseStockRequestDetails,
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<StockRequest>> performAction(
    String requestId,
    StockRequestAction action,
  ) async {
    try {
      if (requestId.isEmpty) {
        return ApiResponse.errorMessage('Request ID is required');
      }

      if (!await ConnectivityService.instance.isOnline) {
        return ApiResponse.errorMessage(
          'No internet connection. Please check your network.',
        );
      }

      final response = await _apiClient
          .patch('stock-requests/$requestId/${action.endpoint}')
          .timeout(const Duration(seconds: 30));

      if (response.data == null) {
        return ApiResponse.errorMessage('Invalid response from server');
      }

      final responseData = response.data is Map<String, dynamic>
          ? (response.data.containsKey('data')
                ? response.data['data'] as Map<String, dynamic>
                : response.data as Map<String, dynamic>)
          : throw const FormatException('Invalid response format');

      return ApiResponse.success(StockRequest.fromJson(responseData));
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getStockRequestStatus(
    String requestId,
  ) async {
    try {
      if (requestId.isEmpty) {
        return ApiResponse.errorMessage('Request ID is required');
      }

      if (!await ConnectivityService.instance.isOnline) {
        return ApiResponse.errorMessage(
          'No internet connection. Please check your network.',
        );
      }

      final response = await _apiClient
          .get('stock-requests/$requestId/status')
          .timeout(const Duration(seconds: 30));

      if (response.data == null) {
        return ApiResponse.errorMessage('Invalid response from server');
      }

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : throw const FormatException('Invalid response format');

      return ApiResponse.success(data);
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  // ─── Parsers ─────────────────────────────────────────────────────────────

  StockRequestResponse _parseStockRequestsResponse(Map<String, dynamic> json) {
    try {
      return StockRequestResponse.fromJson(json);
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
    final e = error.toLowerCase();
    if (e.contains('401') || e.contains('unauthorized')) {
      return 'Unauthorized. Please log in again.';
    }
    if (e.contains('403') || e.contains('forbidden')) {
      return 'Access denied. You do not have permission.';
    }
    if (e.contains('404') || e.contains('not found')) {
      return 'Stock request not found.';
    }
    if (e.contains('409') || e.contains('conflict')) {
      return 'Stock request already exists.';
    }
    if (e.contains('422') || e.contains('unprocessable')) {
      return 'Invalid data provided. Please check your input.';
    }
    if (e.contains('429') || e.contains('too many requests')) {
      return 'Too many requests. Please try again later.';
    }
    if (e.contains('500') || e.contains('internal server')) {
      return 'Server error. Please try again later.';
    }
    if (e.contains('503') || e.contains('service unavailable')) {
      return 'Service temporarily unavailable. Please try again.';
    }
    if (e.contains('network') || e.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (e.contains('timeout')) return 'Request timeout. Please try again.';
    if (e.contains('format') || e.contains('parse')) {
      return 'Invalid response format. Please try again.';
    }
    return 'Operation failed. Please try again later.';
  }

  void _validateCreateRequest(CreateStockRequestRequest request) {
    if (request.requestingBranchId.isEmpty) {
      throw const FormatException('Requesting branch ID cannot be empty');
    }
    if (request.requestedBy.isEmpty) {
      throw const FormatException('Requested by cannot be empty');
    }
    if (request.department.isEmpty) {
      throw const FormatException('Department cannot be empty');
    }
    if (request.items.isEmpty) {
      throw const FormatException('At least one item is required');
    }
    for (final item in request.items) {
      if (item.itemId.isEmpty) {
        throw const FormatException('Item ID cannot be empty');
      }
      if (item.qtyRequested <= 0) {
        throw const FormatException('Quantity must be greater than zero');
      }
    }
  }
}
