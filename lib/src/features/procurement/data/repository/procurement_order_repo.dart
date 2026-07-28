import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_order_model.dart';

abstract class ProcurementRepositoryInterface {
  Future<ApiResponse<ProcurementResponse>> getProcurementOrders(
    String branchId,
  );
  Future<ApiResponse<ProcurementRequest>> approveProcurementRequest({
    required String requestId,
    required String approvedBy,
    String? notes,
  });
  Future<ApiResponse<ProcurementRequest>> rejectProcurementRequest({
    required String requestId,
    required String rejectedBy,
    required String rejectionNote,
  });
}

class ProcurementRepository extends BaseRepository
    implements ProcurementRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<ProcurementResponse>> getProcurementOrders(
    String branchId,
  ) async {
    try {
      _validateBranchId(branchId);

      final response = await _apiClient
          .get('/procurement/requests?branchId=$branchId')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );
      AppLogger.log('=== PROCUREMENT REQUESTS API RESPONSE ===');
      AppLogger.log('Endpoint: /procurement/requests?branchId=$branchId');
      response.when(
        success: (data) {
          AppLogger.log('Success data type: ${data.runtimeType}');
          AppLogger.log('Success data: $data');
        },
        error: (error) {
          AppLogger.log(
            'Error: ${error.message} | statusCode: ${error.statusCode}',
            level: LogLevel.warning,
          );
        },
      );
      AppLogger.log('=========================================');

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseProcurementResponse(json),
      );
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException {
      return ApiResponse.errorMessage(
        'Invalid response from server. Please try again later.',
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<ProcurementRequest>> approveProcurementRequest({
    required String requestId,
    required String approvedBy,
    String? notes,
  }) async {
    if (requestId.isEmpty) {
      return ApiResponse.errorMessage('Request ID cannot be empty.');
    }
    if (approvedBy.isEmpty) {
      return ApiResponse.errorMessage('Approver cannot be empty.');
    }

    try {
      final body = <String, dynamic>{
        'approvedBy': approvedBy,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      AppLogger.log('=== APPROVE PROCUREMENT REQUEST ===');
      AppLogger.log('Endpoint: /procurement/requests/$requestId/approve');
      AppLogger.log('Body: $body');

      final response = await _apiClient
          .post<ProcurementRequest>(
            '/procurement/requests/$requestId/approve',
            data: body,
            fromJson: _parseProcurementRequestObject,
          )
          .timeout(const Duration(seconds: 30));

      return response.when(
        success: ApiResponse.success,
        error: (error) =>
            ApiResponse.errorMessage(_parseErrorMessage(error.toString())),
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<ProcurementRequest>> rejectProcurementRequest({
    required String requestId,
    required String rejectedBy,
    required String rejectionNote,
  }) async {
    if (requestId.isEmpty) {
      return ApiResponse.errorMessage('Request ID cannot be empty.');
    }
    if (rejectedBy.isEmpty) {
      return ApiResponse.errorMessage('Rejector cannot be empty.');
    }
    if (rejectionNote.trim().isEmpty) {
      return ApiResponse.errorMessage('Rejection reason cannot be empty.');
    }

    try {
      final body = <String, dynamic>{
        'rejectedBy': rejectedBy,
        'rejectionNote': rejectionNote.trim(),
      };

      AppLogger.log('=== REJECT PROCUREMENT REQUEST ===');
      AppLogger.log('Endpoint: /procurement/requests/$requestId/reject');
      AppLogger.log('Body: $body');

      final response = await _apiClient
          .post<ProcurementRequest>(
            '/procurement/requests/$requestId/reject',
            data: body,
            fromJson: _parseProcurementRequestObject,
          )
          .timeout(const Duration(seconds: 30));

      return response.when(
        success: ApiResponse.success,
        error: (error) =>
            ApiResponse.errorMessage(_parseErrorMessage(error.toString())),
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
      throw FormatException('Branch ID cannot be empty');
    }
  }

  ProcurementResponse _parseProcurementResponse(Map<String, dynamic> json) {
    return ProcurementResponse.fromJson(json);
  }

  ProcurementRequest _parseProcurementRequestObject(dynamic data) {
    final json = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final payload = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    return ProcurementRequest.fromJson(payload);
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
      return 'No procurement orders found for this branch.';
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

    return 'Failed to load procurement orders. Please try again later.';
  }
}
