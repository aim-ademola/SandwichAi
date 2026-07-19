import 'dart:async';
import 'dart:io';

import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_performance_model.dart';

abstract class ProcurementPerformanceRepositoryInterface {
  Future<ApiResponse<ProcurementPerformanceResponse>>
  getProcurementPerformance({
    String? branchId,
    String? supplierId,
    String? dateFrom,
    String? dateTo,
  });

  Future<ApiResponse<ProcurementPerformanceRankingsResponse>>
  getProcurementPerformanceRankings({int? month, int? year, int limit = 10});
}

class ProcurementPerformanceRepository
    implements ProcurementPerformanceRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<ProcurementPerformanceResponse>>
  getProcurementPerformance({
    String? branchId,
    String? supplierId,
    String? dateFrom,
    String? dateTo,
  }) {
    return _get(
      'procurement/performance',
      ProcurementPerformanceResponse.fromJson,
      queryParameters: _query(
        branchId: branchId,
        supplierId: supplierId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      ),
    );
  }

  @override
  Future<ApiResponse<ProcurementPerformanceRankingsResponse>>
  getProcurementPerformanceRankings({int? month, int? year, int limit = 10}) {
    final now = DateTime.now();
    return _get(
      'procurement/performance/rankings',
      ProcurementPerformanceRankingsResponse.fromJson,
      queryParameters: {
        'month': month ?? now.month,
        'year': year ?? now.year,
        'limit': limit,
      },
    );
  }

  Future<ApiResponse<T>> _get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _apiClient
          .get(endpoint, queryParameters: queryParameters)
          .timeout(const Duration(seconds: 30));
      return response.when(
        success: (data) {
          final json = data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};
          return ApiResponse.success(fromJson(json));
        },
        error: (error) => ApiResponse.error(error),
      );
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage('Connection timeout. Please try again.');
    } catch (e) {
      return ApiResponse.errorMessage(
        'Failed to load procurement performance.',
      );
    }
  }

  Map<String, dynamic>? _query({
    String? branchId,
    String? supplierId,
    String? dateFrom,
    String? dateTo,
  }) {
    final query = <String, dynamic>{
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      if (supplierId != null && supplierId.isNotEmpty) 'supplierId': supplierId,
      if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
    };
    return query.isEmpty ? null : query;
  }
}
