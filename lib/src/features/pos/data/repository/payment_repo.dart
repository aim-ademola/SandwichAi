import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/pos/data/model/payment_model.dart';

abstract class PaymentRepositoryInterface {
  Future<ApiResponse<PaymentResponseModel>> processCashPayment({
    required CashPaymentRequest request,
  });

  Future<ApiResponse<PaymentResponseModel>> processBankTransferPayment({
    required BankTransferPaymentRequest request,
  });
}

class PaymentRepository extends BaseRepository
    implements PaymentRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<PaymentResponseModel>> processCashPayment({
    required CashPaymentRequest request,
  }) async {
    try {
      // Validate required fields
      _validateCashPaymentRequest(request);

      // Make API request
      final response = await _apiClient
          .post('payments/customer/cash', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      // Parse response
      if (response.data == null) {
        return ApiResponse.errorMessage('Failed to process cash payment');
      }

      final paymentResponse = PaymentResponseModel.fromJson(response.data);
      return ApiResponse.success(paymentResponse);
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

  @override
  Future<ApiResponse<PaymentResponseModel>> processBankTransferPayment({
    required BankTransferPaymentRequest request,
  }) async {
    try {
      // Validate required fields
      _validateBankTransferRequest(request);

      // Make API request
      final response = await _apiClient
          .post('payments/customer/transfer', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      // Parse response
      if (response.data == null) {
        return ApiResponse.errorMessage('Failed to process bank transfer');
      }

      final paymentResponse = PaymentResponseModel.fromJson(response.data);
      return ApiResponse.success(paymentResponse);
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

  // Validation methods
  void _validateCashPaymentRequest(CashPaymentRequest request) {
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

  void _validateBankTransferRequest(BankTransferPaymentRequest request) {
    if (request.amount <= 0) {
      throw FormatException('Payment amount must be greater than zero');
    }
    if (request.customerName.isEmpty) {
      throw FormatException('Customer name is required');
    }
    if (request.branchId.isEmpty) {
      throw FormatException('Branch ID is required');
    }
    if (request.bankReference.isEmpty) {
      throw FormatException('Bank reference is required');
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
      return 'Access denied. You do not have permission to process payments.';
    }
    if (lowercaseError.contains('404') ||
        lowercaseError.contains('not found')) {
      return 'Payment endpoint not found. Please contact support.';
    }
    if (lowercaseError.contains('400') ||
        lowercaseError.contains('bad request')) {
      return 'Invalid payment data. Please check your payment details.';
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

    return 'An error occurred while processing payment. Please try again.';
  }
}
