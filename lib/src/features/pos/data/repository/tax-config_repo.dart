import 'dart:async';
import 'dart:io';

import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/model/tax_config_model.dart';

abstract class TaxConfigRepositoryInterface {
  Future<ApiResponse<List<TaxConfiguration>>> getActiveTaxConfigurations();
}

class TaxConfigRepository extends BaseRepository
    implements TaxConfigRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<List<TaxConfiguration>>>
  getActiveTaxConfigurations() async {
    try {
      final listResponse = await handleListResponse<TaxConfiguration>(
        _apiClient
            .get('accounting/tax-configuration/active')
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Request timed out. Please try again.');
              },
            )
            .then((response) => ApiResponse.success(response.data)),
        (json) => TaxConfiguration.fromJson(json),
      );

      return listResponse;
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
        e.message.isNotEmpty ? e.message : 'Invalid data format received.',
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  String _parseErrorMessage(String error) {
    final lower = error.toLowerCase();

    if (lower.contains('401') || lower.contains('unauthorized')) {
      return 'Unauthorized access. Please login again.';
    }
    if (lower.contains('403') || lower.contains('forbidden')) {
      return 'Access denied. Please contact support.';
    }
    if (lower.contains('404') || lower.contains('not found')) {
      return 'Tax configuration not found.';
    }
    if (lower.contains('500') || lower.contains('internal server')) {
      return 'Server error. Please try again later.';
    }
    if (lower.contains('503') || lower.contains('service unavailable')) {
      return 'Service temporarily unavailable. Please try again later.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (lower.contains('timeout')) {
      return 'Request timeout. Please try again.';
    }

    return 'Failed to load tax configuration. Please try again later.';
  }
}
