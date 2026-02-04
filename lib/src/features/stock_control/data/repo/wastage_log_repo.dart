import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/wastage_log.dart';

abstract class WasteLogsRepositoryInterface {
  Future<ApiResponse<WasteLogsResponse>> getWasteLogs({
    required String branchId,
    String? reason,
    String? startDate,
    String? endDate,
  });

  Future<ApiResponse<WasteLogItem>> createWasteLog(WasteLogRequest request);
}

class WasteLogsRepository extends BaseRepository
    implements WasteLogsRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<WasteLogsResponse>> getWasteLogs({
    required String branchId,
    String? reason,
    String? startDate,
    String? endDate,
  }) async {
    try {
      _validateBranchId(branchId);

      // Build query parameters
      final queryParams = <String, dynamic>{'branchId': branchId};

      if (reason != null && reason.isNotEmpty) {
        queryParams['reason'] = reason;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }

      final response = await _apiClient
          .get('processing/waste-logs', queryParameters: queryParams)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      // Handle the list response manually since we're wrapping it in WasteLogsResponse
      return response.when(
        success: (data) {
          try {
            if (data is! List) {
              return ApiResponse.error(
                NetworkException.formatException(
                  'Expected list but got ${data.runtimeType}',
                ),
              );
            }

            final wasteLogsResponse = _parseWasteLogsResponse(data);
            return ApiResponse.success(wasteLogsResponse);
          } catch (e) {
            return ApiResponse.error(
              NetworkException.formatException(
                'Failed to parse waste logs: $e',
              ),
            );
          }
        },
        error: (error) => ApiResponse.error(error),
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
      return ApiResponse.errorMessage(
        'Invalid response from server: ${e.message}',
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  WasteLogsResponse _parseWasteLogsResponse(dynamic json) {
    try {
      if (json is! List) {
        throw const FormatException('Expected a list of waste logs');
      }

      if (json.isEmpty) {
        return WasteLogsResponse.fromJson([]);
      }

      final response = WasteLogsResponse.fromJson(json);

      return response;
    } catch (e) {
      throw FormatException('Failed to parse waste logs: $e');
    }
  }

  @override
  Future<ApiResponse<WasteLogItem>> createWasteLog(
    WasteLogRequest request,
  ) async {
    try {
      final response = await _apiClient
          .post('processing/waste-logs', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return handleObjectResponse(
        Future.value(response),
        (json) => WasteLogItem.fromJson(json),
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
      return ApiResponse.errorMessage(
        'Invalid response from server: ${e.message}',
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
      return 'Waste logs not found.';
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

    return 'Failed to load waste logs. Please try again later.';
  }
}
