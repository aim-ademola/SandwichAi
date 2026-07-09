// ignore_for_file: unused_catch_clause

import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/auth/data/models/forgot_pwd_model.dart';

abstract class ForgotPasswordRepositoryInterface {
  Future<ApiResponse<ForgotPasswordResponse>> forgotPassword(
    ForgotPasswordRequest request,
  );
  Future<ApiResponse<ResetPasswordResponse>> resetPassword(
    ResetPasswordRequest request,
  );
}

class ForgotPasswordRepository extends BaseRepository
    implements ForgotPasswordRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<ForgotPasswordResponse>> forgotPassword(
    ForgotPasswordRequest request,
  ) async {
    try {
      // Validate request before sending
      _validateForgotPasswordRequest(request);

      final response = await _apiClient
          .post('auth/forgot-password', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseForgotPasswordResponse(json),
      );
    } on SocketException catch (e) {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(
        'Invalid response from server. Please try again later.',
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<ResetPasswordResponse>> resetPassword(
    ResetPasswordRequest request,
  ) async {
    try {
      // Validate request before sending
      _validateResetPasswordRequest(request);

      final response = await _apiClient
          .post('auth/reset-password', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseResetPasswordResponse(json),
      );
    } on SocketException catch (e) {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(
        'Invalid response from server. Please try again later.',
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  /// Validates forgot password request fields
  void _validateForgotPasswordRequest(ForgotPasswordRequest request) {
    if (request.email.isEmpty) {
      throw FormatException('Email cannot be empty');
    }

    if (!_isValidEmail(request.email)) {
      throw FormatException('Please enter a valid email address');
    }

    if (request.organizationCode.isEmpty) {
      throw FormatException('Organization code cannot be empty');
    }
  }

  /// Validates reset password request fields
  void _validateResetPasswordRequest(ResetPasswordRequest request) {
    if (request.email.isEmpty) {
      throw FormatException('Email cannot be empty');
    }

    if (!_isValidEmail(request.email)) {
      throw FormatException('Please enter a valid email address');
    }

    if (request.otp.isEmpty) {
      throw FormatException('OTP cannot be empty');
    }

    if (request.otp.length != 6) {
      throw FormatException('OTP must be 6 digits');
    }

    if (request.password.isEmpty) {
      throw FormatException('Password cannot be empty');
    }

    if (request.password.length < 6) {
      throw FormatException('Password must be at least 6 characters');
    }
  }

  /// Validates email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Parse forgot password response
  ForgotPasswordResponse _parseForgotPasswordResponse(
    Map<String, dynamic> json,
  ) {
    try {
      final response = ForgotPasswordResponse.fromJson(json);

      if (!response.isValid) {
        throw FormatException('Invalid response received');
      }

      return response;
    } catch (e) {
      throw FormatException('Unable to process response: ${e.toString()}');
    }
  }

  /// Parse reset password response
  ResetPasswordResponse _parseResetPasswordResponse(Map<String, dynamic> json) {
    try {
      final response = ResetPasswordResponse.fromJson(json);

      if (!response.isValid) {
        throw FormatException('Invalid response received');
      }

      return response;
    } catch (e) {
      throw FormatException('Unable to process response: ${e.toString()}');
    }
  }

  /// Parse error messages to user-friendly format
  String _parseErrorMessage(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('404') ||
        lowercaseError.contains('not found')) {
      return 'Email not found. Please check and try again.';
    }

    if (lowercaseError.contains('400') ||
        lowercaseError.contains('bad request')) {
      return 'Invalid request. Please check your details.';
    }

    if (lowercaseError.contains('401') ||
        lowercaseError.contains('unauthorized')) {
      return 'Invalid OTP or credentials. Please try again.';
    }

    if (lowercaseError.contains('429') ||
        lowercaseError.contains('too many requests')) {
      return 'Too many attempts. Please try again later.';
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

    if (lowercaseError.contains('otp')) {
      return 'Invalid or expired OTP. Please try again.';
    }

    return 'Request failed. Please try again later.';
  }
}
