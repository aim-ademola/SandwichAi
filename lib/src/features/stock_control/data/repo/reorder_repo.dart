import 'dart:async';
import 'dart:io';

import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/reorder_model.dart';

abstract class ReorderRepositoryInterface {
  Future<ApiResponse<ReorderSuggestionsResponse>> getReorderSuggestions();
  Future<ApiResponse<ReorderReportResponse>> getReorderReport(String branchId);
  Future<ApiResponse<ReorderAcknowledgeResponse>> acknowledgeReorder(
    String branchStockId,
  );
}

class ReorderRepository implements ReorderRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<ReorderSuggestionsResponse>> getReorderSuggestions() {
    return _request(
      () => _apiClient.get('reorder/suggestions'),
      ReorderSuggestionsResponse.fromJson,
    );
  }

  @override
  Future<ApiResponse<ReorderReportResponse>> getReorderReport(String branchId) {
    if (branchId.isEmpty) {
      return Future.value(
        ApiResponse.errorMessage('Branch ID cannot be empty.'),
      );
    }
    return _request(
      () => _apiClient.get('reorder/report/$branchId'),
      ReorderReportResponse.fromJson,
    );
  }

  @override
  Future<ApiResponse<ReorderAcknowledgeResponse>> acknowledgeReorder(
    String branchStockId,
  ) {
    if (branchStockId.isEmpty) {
      return Future.value(
        ApiResponse.errorMessage('Branch stock ID cannot be empty.'),
      );
    }
    return _request(
      () => _apiClient.post('reorder/acknowledge/$branchStockId'),
      ReorderAcknowledgeResponse.fromJson,
    );
  }

  Future<ApiResponse<T>> _request<T>(
    Future<ApiResponse<dynamic>> Function() call,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await call().timeout(const Duration(seconds: 30));
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
      return ApiResponse.errorMessage('Failed to process reorder request.');
    }
  }
}
