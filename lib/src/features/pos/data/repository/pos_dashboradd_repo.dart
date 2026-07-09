import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/model/pos_dashboard_summary.dart';

abstract class DashboardRepositoryInterface {
  Future<ApiResponse<DashboardSummaryModel>> getDashboardSummary({
    required String branchId,
    String? date,
  });
}

class DashboardRepository extends BaseRepository
    implements DashboardRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<DashboardSummaryModel>> getDashboardSummary({
    required String branchId,
    String? date,
  }) async {
    try {
      // Validate required fields
      _validateBranchId(branchId);

      // Build query parameters
      final Map<String, dynamic> queryParams = {'branchId': branchId};

      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }

      // Make API request
      final response = await _apiClient
          .get(
            'customer-service/analytics/dashboard/summary',
            queryParameters: queryParams,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      // Parse response
      if (response.data == null) {
        return ApiResponse.errorMessage('Failed to fetch dashboard data');
      }

      final summary = DashboardSummaryModel.fromJson(response.data);
      return ApiResponse.success(summary);
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

  // Validation methods
  void _validateBranchId(String branchId) {
    if (branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
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
      return 'Access denied. You do not have permission to view dashboard.';
    }
    if (lowercaseError.contains('404') ||
        lowercaseError.contains('not found')) {
      return 'Dashboard data not found. Please contact support.';
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

    return 'An error occurred while fetching dashboard data. Please try again.';
  }
}
