// lib/src/features/auth/data/repository/login_repository.dart

// ignore_for_file: unused_catch_clause

import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/auth/data/models/login_model.dart';

abstract class LoginRepositoryInterface {
  Future<ApiResponse<LoginResponse>> loginUser(LoginRequest request);
}

class LoginRepository extends BaseRepository
    implements LoginRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<LoginResponse>> loginUser(LoginRequest request) async {
    try {
      // Validate request before sending
      _validateLoginRequest(request);

      final response = await _apiClient
          .post('auth/login', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Login request timed out. Please try again.',
              );
            },
          );

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseLoginResponse(json),
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

  /// Validates login request fields
  void _validateLoginRequest(LoginRequest request) {
    if (request.email.isEmpty) {
      throw FormatException('Email cannot be empty');
    }

    if (!_isValidEmail(request.email)) {
      throw FormatException('Please enter a valid email address');
    }

    if (request.password.isEmpty) {
      throw FormatException('Password cannot be empty');
    }

    if (request.password.length < 6) {
      throw FormatException('Password must be at least 6 characters');
    }

    if (request.organizationCode.isEmpty) {
      throw FormatException('Organization code cannot be empty');
    }

    if (request.organizationCode.length < 3) {
      throw FormatException('Organization code must be at least 3 characters');
    }
  }

  /// Validates email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Parse login response with better error handling
  LoginResponse _parseLoginResponse(Map<String, dynamic> json) {
    try {
      final response = LoginResponse.fromJson(json);

      // Validate response data
      if (!response.isValid) {
        throw FormatException('Invalid login credentials received');
      }

      if (response.accessToken.isEmpty) {
        throw FormatException('No authentication token received');
      }

      return response;
    } catch (e) {
      throw FormatException(
        'Unable to process login response: ${e.toString()}',
      );
    }
  }

  /// Parse error messages to user-friendly format
  String _parseErrorMessage(String error) {
    final lowercaseError = error.toLowerCase();

    // Common API error patterns
    if (lowercaseError.contains('401') ||
        lowercaseError.contains('unauthorized')) {
      return 'Invalid email, password, or organization code. Please try again.';
    }

    if (lowercaseError.contains('403') ||
        lowercaseError.contains('forbidden')) {
      return 'Access denied. Please contact support.';
    }

    if (lowercaseError.contains('404') ||
        lowercaseError.contains('not found')) {
      return 'Account or organization not found. Please check your credentials.';
    }

    if (lowercaseError.contains('429') ||
        lowercaseError.contains('too many requests')) {
      return 'Too many login attempts. Please try again later.';
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

    if (lowercaseError.contains('organization')) {
      return 'Invalid organization code. Please verify and try again.';
    }

    // Generic fallback
    return 'Login failed. Please try again later.';
  }
}
