import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/config/app_environment.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/api_constants.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/processing/data/model/wastage_analysis_model.dart';

abstract class WastageAnalysisRepositoryInterface {
  Future<ApiResponse<WastageAnalysisResponse>> analyzeWastage({
    required String organizationId,
    required String branchId,
    int daysBack = 30,
  });
}

class WastageAnalysisRepository extends BaseRepository
    implements WastageAnalysisRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<WastageAnalysisResponse>> analyzeWastage({
    required String organizationId,
    required String branchId,
    int daysBack = 30,
  }) async {
    try {
      if (!AppEnvironment.current.isFeatureEnabled(
        AppFeature.wastageAnalysis,
      )) {
        return ApiResponse.errorMessage(
          AppEnvironment.current.disabledFeatureMessage(
            AppFeature.wastageAnalysis,
          ),
        );
      }

      _validateInput(organizationId, branchId, daysBack);

      final requestBody = {
        'organization_id': organizationId,
        'branch_id': branchId,
        'days_back': daysBack,
      };

      AppLogger.log('=== WASTAGE ANALYSIS REQUEST ===');
      AppLogger.log('Organization ID: $organizationId');
      AppLogger.log('Branch ID: $branchId');
      AppLogger.log('Days Back: $daysBack');
      AppLogger.log('================================');

      final response = await _apiClient
          .post('${ApiConstants.aiBaseUrl}wastage/analyze', data: requestBody)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw TimeoutException(
                'Wastage analysis timed out. Please try again.',
              );
            },
          );

      AppLogger.log('=== WASTAGE ANALYSIS RESPONSE ===');
      AppLogger.log('Response Data: ${response.data}');
      AppLogger.log('==================================');

      // Handle null or empty response data
      if (response.data == null) {
        AppLogger.log('Response data is null - returning empty analysis');
        return ApiResponse.success(_createEmptyAnalysis());
      }

      // Handle empty map or list responses
      if (response.data is Map && (response.data as Map).isEmpty) {
        AppLogger.log('Response data is empty map - returning empty analysis');
        return ApiResponse.success(_createEmptyAnalysis());
      }

      if (response.data is List && (response.data as List).isEmpty) {
        AppLogger.log('Response data is empty list - returning empty analysis');
        return ApiResponse.success(_createEmptyAnalysis());
      }

      try {
        final analysis = WastageAnalysisResponse.fromJson(response.data);
        return ApiResponse.success(analysis);
      } catch (e) {
        AppLogger.log('Failed to parse response: $e');
        // If parsing fails, return empty analysis instead of error
        return ApiResponse.success(_createEmptyAnalysis());
      }
    } on SocketException catch (e) {
      AppLogger.log('Socket Exception: $e');
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      AppLogger.log('Timeout Exception: $e');
      return ApiResponse.errorMessage(
        'Request timeout. The AI service is taking longer than expected.',
      );
    } on FormatException catch (e) {
      AppLogger.log('Format Exception: ${e.message}');
      return ApiResponse.errorMessage(e.message);
    } catch (e, stackTrace) {
      AppLogger.log('Error: $e');
      AppLogger.log('Stack Trace: $stackTrace');
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  // Create an empty analysis response for when there's no data
  WastageAnalysisResponse _createEmptyAnalysis() {
    return WastageAnalysisResponse(
      totalLogs: 0,
      daysAnalyzed: 30,
      anomalies: [],
      patterns: [],
      highRiskItems: [],
      financialImpact: FinancialImpact(
        totalValueLost: 0.0,
        avgDailyLoss: 0.0,
        peakWastageItems: [],
      ),
      recommendations: [],
      generatedAt: DateTime.now(),
    );
  }

  void _validateInput(String organizationId, String branchId, int daysBack) {
    if (organizationId.trim().isEmpty) {
      throw FormatException('Organization ID cannot be empty');
    }
    if (branchId.trim().isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }
    if (daysBack <= 0 || daysBack > 365) {
      throw FormatException('Days back must be between 1 and 365');
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
      return 'Wastage data not found for the specified period.';
    }
    if (lowercaseError.contains('500') ||
        lowercaseError.contains('internal server')) {
      return 'AI service error. Please try again later.';
    }
    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (lowercaseError.contains('timeout')) {
      return 'Request timeout. Please try again.';
    }

    return 'An error occurred while analyzing wastage. Please try again later.';
  }
}
