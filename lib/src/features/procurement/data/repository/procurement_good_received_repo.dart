// data/repo/goods_received_repo.dart

import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_good_recieved_model.dart'
    show InventoryItem, GoodsReceived, CreateGoodsReceivedRequest;

abstract class GoodsReceivedRepositoryInterface {
  Future<ApiResponse<List<InventoryItem>>> getInventoryItems({
    required String organizationId,
  });

  Future<ApiResponse<GoodsReceived>> createGoodsReceived({
    required CreateGoodsReceivedRequest request,
  });

  Future<ApiResponse<List<GoodsReceived>>> getGoodsReceived({
    required String branchId,
  });
}

class GoodsReceivedRepository extends BaseRepository
    implements GoodsReceivedRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<List<InventoryItem>>> getInventoryItems({
    required String organizationId,
  }) async {
    try {
      final response = await _apiClient
          .get(
            '/inventory-items',
            queryParameters: {
              'page': 1,
              'limit': 1000,
              if (organizationId.isNotEmpty) 'organizationId': organizationId,
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (body) {
          final items = _extractList(body);
          if (items == null) {
            return ApiResponse.errorMessage('Invalid response from server');
          }

          final inventoryItems = items
              .whereType<Map>()
              .map((e) => InventoryItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          return ApiResponse.success(inventoryItems);
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
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<GoodsReceived>> createGoodsReceived({
    required CreateGoodsReceivedRequest request,
  }) async {
    try {
      _validateGoodsReceivedData(request);

      final response = await _apiClient
          .post('procurement/goods-received', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Invalid response from server');
      }

      return ApiResponse.success(GoodsReceived.fromJson(response.data));
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

  @override
  Future<ApiResponse<List<GoodsReceived>>> getGoodsReceived({
    required String branchId,
  }) async {
    try {
      _validateBranchId(branchId);

      final listResponse = await handleListResponse<GoodsReceived>(
        _apiClient
            .get(
              'procurement/goods-received',
              queryParameters: {'branchId': branchId},
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Request timed out. Please try again.');
              },
            )
            .then((response) => ApiResponse.success(response.data)),
        (json) => GoodsReceived.fromJson(json),
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
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  void _validateBranchId(String branchId) {
    if (branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }
  }

  void _validateGoodsReceivedData(CreateGoodsReceivedRequest request) {
    if (request.branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }
    if (request.supplierName.isEmpty) {
      throw FormatException('Supplier name cannot be empty');
    }
    if (request.invoiceNo.isEmpty) {
      throw FormatException('Invoice number cannot be empty');
    }
    if (request.poNumber.isEmpty) {
      throw FormatException('PO number cannot be empty');
    }
    if (request.receivedBy.isEmpty) {
      throw FormatException('Received by field cannot be empty');
    }
    if (request.inspectedBy.isEmpty) {
      throw FormatException('Inspected by field cannot be empty');
    }
    if (request.items.isEmpty) {
      throw FormatException('At least one item must be added');
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
      return 'Resource not found.';
    }

    if (lowercaseError.contains('409') || lowercaseError.contains('conflict')) {
      return 'Conflict detected. Please check your data.';
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

    return 'Failed to process request. Please try again later.';
  }

  List<dynamic>? _extractList(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return null;

    for (final key in const ['data', 'items', 'results']) {
      if (body[key] is List) return body[key] as List;
    }

    final data = body['data'];
    if (data is Map) {
      for (final key in const ['items', 'data', 'results', 'inventoryItems']) {
        if (data[key] is List) return data[key] as List;
      }
    }

    return null;
  }
}
