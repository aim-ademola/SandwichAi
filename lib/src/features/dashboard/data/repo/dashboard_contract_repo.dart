import 'dart:async';
import 'dart:io';

import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/features/dashboard/data/model/dashboard_contract_model.dart';

abstract class DashboardContractRepositoryInterface {
  Future<ApiResponse<DashboardResponse>> getDashboard(
    DashboardFilterRequest request,
  );
}

class DashboardContractRepository implements DashboardContractRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  static const Map<DashboardDomain, String> _endpointPlaceholders = {
    DashboardDomain.pos: 'customer-service/analytics/dashboard/summary',
    DashboardDomain.procurement: 'procurement/dashboard',
    DashboardDomain.processing: 'processing/dashboard',
    DashboardDomain.kitchen: 'kitchen/dashboard',
    DashboardDomain.stockControl: 'branch-stock/dashboard',
  };

  @override
  Future<ApiResponse<DashboardResponse>> getDashboard(
    DashboardFilterRequest request,
  ) async {
    try {
      if (request.organizationId.isEmpty) {
        return ApiResponse.errorMessage('Organization ID cannot be empty.');
      }

      final endpoint = _endpointPlaceholders[request.domain]!;
      final response = await _apiClient
          .get(endpoint, queryParameters: request.toQueryParameters())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Request timed out.'),
          );

      return response.when(
        success: (data) {
          final json = data is Map
              ? data.cast<String, dynamic>()
              : <String, dynamic>{};
          return ApiResponse.success(
            DashboardResponse.fromJson(json, domain: request.domain),
          );
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
    } catch (e) {
      return ApiResponse.errorMessage(
        'Failed to load ${request.domain.title}. Please try again later.',
      );
    }
  }
}
