// ignore_for_file: unused_catch_clause

import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/auth/data/models/chnage-pwd-res.dart';

abstract class ChangePasswordRepositoryInterface {
  Future<ApiResponse<ChangePasswordResponse>> changePassword(
    ChangePasswordRequest request,
  );
}

class ChangePasswordRepository extends BaseRepository
    implements ChangePasswordRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<ChangePasswordResponse>> changePassword(
    ChangePasswordRequest request,
  ) async {
    try {
      _validateRequest(request);

      final response = await _apiClient
          .post('auth/employee/change-password', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseResponse(json),
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

  void _validateRequest(ChangePasswordRequest request) {
    if (request.currentPassword.isEmpty) {
      throw FormatException('Current password cannot be empty');
    }

    if (request.newPassword.isEmpty) {
      throw FormatException('New password cannot be empty');
    }

    if (request.newPassword.length < 6) {
      throw FormatException('New password must be at least 6 characters');
    }

    if (request.currentPassword == request.newPassword) {
      throw FormatException(
        'New password must be different from current password',
      );
    }
  }

  ChangePasswordResponse _parseResponse(Map<String, dynamic> json) {
    try {
      final response = ChangePasswordResponse.fromJson(json);
      if (!response.isValid) {
        throw FormatException('Invalid response received');
      }
      return response;
    } catch (e) {
      throw FormatException('Unable to process response: ${e.toString()}');
    }
  }

  String _parseErrorMessage(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('401') ||
        lowercaseError.contains('unauthorized')) {
      return 'Current password is incorrect. Please try again.';
    }

    if (lowercaseError.contains('400') ||
        lowercaseError.contains('bad request')) {
      return 'Invalid request. Please check your details.';
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

    return 'Request failed. Please try again later.';
  }
}
