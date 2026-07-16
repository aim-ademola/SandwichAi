import 'dart:async';
import 'dart:io';

import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/stock_card_model.dart';

abstract class StockCardRepositoryInterface {
  Future<ApiResponse<StockExpiryReport>> getExpiryReport();
  Future<ApiResponse<StockExpirySummary>> getExpirySummary();
  Future<ApiResponse<StockExpiryReport>> getBranchExpiryReport(String branchId);
  Future<ApiResponse<List<StockBatch>>> getBatches({
    required String branchId,
    required String itemId,
  });
  Future<ApiResponse<StockBatch>> updateBatch({
    required String branchId,
    required String itemId,
    required String batchId,
    required StockBatchUpdateRequest request,
  });
  Future<ApiResponse<StockMovementTrendsResponse>> getMovementTrends({
    String? branchId,
    String? itemId,
    String? dateFrom,
    String? dateTo,
  });
}

class StockCardRepository implements StockCardRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<StockExpiryReport>> getExpiryReport() {
    return _getObject('stock-cards/expiry-report', StockExpiryReport.fromJson);
  }

  @override
  Future<ApiResponse<StockExpirySummary>> getExpirySummary() {
    return _getObject(
      'stock-cards/analytics/expiry-summary',
      StockExpirySummary.fromJson,
    );
  }

  @override
  Future<ApiResponse<StockExpiryReport>> getBranchExpiryReport(
    String branchId,
  ) {
    if (branchId.isEmpty) {
      return Future.value(
        ApiResponse.errorMessage('Branch ID cannot be empty.'),
      );
    }
    return _getObject(
      'stock-cards/$branchId/expiry-report',
      StockExpiryReport.fromJson,
    );
  }

  @override
  Future<ApiResponse<List<StockBatch>>> getBatches({
    required String branchId,
    required String itemId,
  }) async {
    if (branchId.isEmpty || itemId.isEmpty) {
      return ApiResponse.errorMessage('Branch ID and item ID are required.');
    }

    final response = await _getRaw('stock-cards/$branchId/$itemId/batches');
    return response.when(
      success: (json) {
        final list = _extractList(json);
        return ApiResponse.success(
          list
              .whereType<Map>()
              .map(
                (item) => StockBatch.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(),
        );
      },
      error: (error) => ApiResponse.error(error),
    );
  }

  @override
  Future<ApiResponse<StockBatch>> updateBatch({
    required String branchId,
    required String itemId,
    required String batchId,
    required StockBatchUpdateRequest request,
  }) async {
    if (branchId.isEmpty || itemId.isEmpty || batchId.isEmpty) {
      return ApiResponse.errorMessage(
        'Branch ID, item ID, and batch ID are required.',
      );
    }
    try {
      final response = await _apiClient
          .patch(
            'stock-cards/$branchId/$itemId/batches/$batchId',
            data: request.toJson(),
          )
          .timeout(const Duration(seconds: 30));

      return response.when(
        success: (data) {
          final json = _asMap(data);
          final payload = _asMap(json['data']).isNotEmpty
              ? _asMap(json['data'])
              : json;
          return ApiResponse.success(StockBatch.fromJson(payload));
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
      return ApiResponse.errorMessage('Failed to update batch.');
    }
  }

  @override
  Future<ApiResponse<StockMovementTrendsResponse>> getMovementTrends({
    String? branchId,
    String? itemId,
    String? dateFrom,
    String? dateTo,
  }) {
    final query = <String, dynamic>{
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      if (itemId != null && itemId.isNotEmpty) 'itemId': itemId,
      if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
    };
    return _getObject(
      'stock-cards/analytics/movement-trends',
      StockMovementTrendsResponse.fromJson,
      queryParameters: query.isNotEmpty ? query : null,
    );
  }

  Future<ApiResponse<T>> _getObject<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _getRaw(endpoint, queryParameters: queryParameters);
    return response.when(
      success: (json) => ApiResponse.success(fromJson(json)),
      error: (error) => ApiResponse.error(error),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> _getRaw(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _apiClient
          .get(endpoint, queryParameters: queryParameters)
          .timeout(const Duration(seconds: 30));
      return response.when(
        success: (data) => ApiResponse.success(_asMap(data)),
        error: (error) => ApiResponse.error(error),
      );
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage('Connection timeout. Please try again.');
    } catch (e) {
      return ApiResponse.errorMessage('Failed to load stock card data.');
    }
  }

  List<dynamic> _extractList(Map<String, dynamic> json) {
    for (final key in const ['data', 'items', 'results', 'batches']) {
      final value = json[key];
      if (value is List) return value;
    }
    final data = json['data'];
    if (data is Map) {
      for (final key in const ['items', 'results', 'batches']) {
        final value = data[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
