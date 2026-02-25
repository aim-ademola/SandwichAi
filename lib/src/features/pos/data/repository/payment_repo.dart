import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/pos/data/model/payment_model.dart';

abstract class PaymentRepositoryInterface {
  Future<ApiResponse<CashRecordResponseModel>> recordCashPayment({
    required CashPaymentRequest request,
  });

  Future<ApiResponse<PendingCashListResponseModel>> getPendingCashTransactions({
    required String branchId,
  });

  Future<ApiResponse<OnlinePaymentInitResponseModel>> initializeOnlinePayment({
    required OnlinePaymentRequest request,
  });

  Future<ApiResponse<OnlinePaymentStatusResponseModel>>
  checkOnlinePaymentStatus({required String reference});
}

class PaymentRepository extends BaseRepository
    implements PaymentRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<CashRecordResponseModel>> recordCashPayment({
    required CashPaymentRequest request,
  }) async {
    try {
      _validateCashRequest(request);

      final response = await _apiClient
          .post('payments/cash/record', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Failed to record cash payment');
      }

      return ApiResponse.success(
        CashRecordResponseModel.fromJson(response.data),
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
      return ApiResponse.errorMessage(_parseError(e.toString()));
    }
  }

  @override
  Future<ApiResponse<PendingCashListResponseModel>> getPendingCashTransactions({
    required String branchId,
  }) async {
    try {
      final response = await _apiClient
          .get('payments/cash/pending', queryParameters: {'branchId': branchId})
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Failed to fetch pending transactions');
      }

      return ApiResponse.success(
        PendingCashListResponseModel.fromJson(response.data),
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
      return ApiResponse.errorMessage(_parseError(e.toString()));
    }
  }

  @override
  Future<ApiResponse<OnlinePaymentInitResponseModel>> initializeOnlinePayment({
    required OnlinePaymentRequest request,
  }) async {
    try {
      _validateOnlineRequest(request);

      final response = await _apiClient
          .post('payments/initialize', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Failed to initialize payment');
      }

      return ApiResponse.success(
        OnlinePaymentInitResponseModel.fromJson(response.data),
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
      return ApiResponse.errorMessage(_parseError(e.toString()));
    }
  }

  @override
  Future<ApiResponse<OnlinePaymentStatusResponseModel>>
  checkOnlinePaymentStatus({required String reference}) async {
    try {
      final response = await _apiClient
          .get('payments/status/$reference')
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Failed to check payment status');
      }

      return ApiResponse.success(
        OnlinePaymentStatusResponseModel.fromJson(response.data),
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
      return ApiResponse.errorMessage(_parseError(e.toString()));
    }
  }

  void _validateCashRequest(CashPaymentRequest request) {
    if (request.amount <= 0) {
      throw FormatException('Payment amount must be greater than zero');
    }
    if (request.customerName.isEmpty) {
      throw FormatException('Customer name is required');
    }
    if (request.branchId.isEmpty) {
      throw FormatException('Branch ID is required');
    }
  }

  void _validateOnlineRequest(OnlinePaymentRequest request) {
    if (request.amount <= 0) {
      throw FormatException('Payment amount must be greater than zero');
    }
    if (request.customerName.isEmpty) {
      throw FormatException('Customer name is required');
    }
    if (request.branchId.isEmpty) {
      throw FormatException('Branch ID is required');
    }
  }

  String _parseError(String error) {
    final e = error.toLowerCase();
    if (e.contains('401') || e.contains('unauthorized')) {
      return 'Unauthorized access. Please login again.';
    }
    if (e.contains('403') || e.contains('forbidden')) {
      return 'Access denied. You do not have permission to process payments.';
    }
    if (e.contains('404') || e.contains('not found')) {
      return 'Payment endpoint not found. Please contact support.';
    }
    if (e.contains('400') || e.contains('bad request')) {
      return 'Invalid payment data. Please check your payment details.';
    }
    if (e.contains('500') || e.contains('internal server')) {
      return 'Server error. Please try again later.';
    }
    if (e.contains('network') || e.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (e.contains('timeout')) {
      return 'Request timeout. Please try again.';
    }
    return 'An error occurred while processing payment. Please try again.';
  }
}
