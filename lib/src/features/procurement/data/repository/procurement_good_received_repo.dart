// data/repo/goods_received_repo.dart

import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_good_recieved_model.dart'
    show
        InventoryItem,
        GoodsReceived,
        CreateGoodsReceivedRequest,
        UpdateGoodsReceivedQcRequest,
        GoodsReceivedPrefillResponse,
        PurchaseOrderDeliveryStatusResponse,
        GoodsReceivedQcStats;

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

  Future<ApiResponse<GoodsReceived>> getGoodsReceivedById(String id);

  Future<ApiResponse<GoodsReceived>> updateGoodsReceivedQc({
    required String id,
    required UpdateGoodsReceivedQcRequest request,
  });

  Future<ApiResponse<GoodsReceivedPrefillResponse>> getGoodsReceivedPrefill(
    String poId,
  );

  Future<ApiResponse<List<GoodsReceived>>> getGoodsReceivedByPurchaseOrder(
    String poId,
  );

  Future<ApiResponse<PurchaseOrderDeliveryStatusResponse>>
  getPurchaseOrderDeliveryStatus(String poId);

  Future<ApiResponse<Map<String, dynamic>>> markPurchaseOrderComplete(
    String poId,
  );

  Future<ApiResponse<GoodsReceivedQcStats>> getGoodsReceivedQcStats();
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

  @override
  Future<ApiResponse<GoodsReceived>> getGoodsReceivedById(String id) async {
    if (id.isEmpty) {
      return ApiResponse.errorMessage('Goods received ID cannot be empty');
    }
    return _getObject(
      'procurement/goods-received/$id',
      (json) => GoodsReceived.fromJson(_unwrapData(json)),
    );
  }

  @override
  Future<ApiResponse<GoodsReceived>> updateGoodsReceivedQc({
    required String id,
    required UpdateGoodsReceivedQcRequest request,
  }) async {
    if (id.isEmpty) {
      return ApiResponse.errorMessage('Goods received ID cannot be empty');
    }
    if (request.qcStatus.isEmpty) {
      return ApiResponse.errorMessage('QC status cannot be empty');
    }
    if (request.inspectedBy.isEmpty) {
      return ApiResponse.errorMessage('Inspected by field cannot be empty');
    }

    return _patchObject(
      'procurement/goods-received/$id/qc',
      request.toJson(),
      (json) => GoodsReceived.fromJson(_unwrapData(json)),
    );
  }

  @override
  Future<ApiResponse<GoodsReceivedPrefillResponse>> getGoodsReceivedPrefill(
    String poId,
  ) {
    if (poId.isEmpty) {
      return Future.value(
        ApiResponse.errorMessage('Purchase order ID cannot be empty'),
      );
    }
    return _getObject(
      'procurement/goods-received/prefill/$poId',
      GoodsReceivedPrefillResponse.fromJson,
    );
  }

  @override
  Future<ApiResponse<List<GoodsReceived>>> getGoodsReceivedByPurchaseOrder(
    String poId,
  ) async {
    if (poId.isEmpty) {
      return ApiResponse.errorMessage('Purchase order ID cannot be empty');
    }

    final response = await _getRaw('goods-received/purchase-order/$poId');
    return response.when(
      success: (json) {
        final list = _extractList(json);
        return ApiResponse.success(
          (list ?? const [])
              .whereType<Map>()
              .map(
                (item) =>
                    GoodsReceived.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(),
        );
      },
      error: (error) => ApiResponse.error(error),
    );
  }

  @override
  Future<ApiResponse<PurchaseOrderDeliveryStatusResponse>>
  getPurchaseOrderDeliveryStatus(String poId) {
    if (poId.isEmpty) {
      return Future.value(
        ApiResponse.errorMessage('Purchase order ID cannot be empty'),
      );
    }
    return _getObject(
      'goods-received/purchase-order/$poId/delivery-status',
      PurchaseOrderDeliveryStatusResponse.fromJson,
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> markPurchaseOrderComplete(
    String poId,
  ) async {
    if (poId.isEmpty) {
      return ApiResponse.errorMessage('Purchase order ID cannot be empty');
    }
    return _patchObject(
      'goods-received/purchase-order/$poId/mark-complete',
      const <String, dynamic>{},
      (json) => json,
    );
  }

  @override
  Future<ApiResponse<GoodsReceivedQcStats>> getGoodsReceivedQcStats() {
    return _getObject(
      'procurement/goods-received/stats/qc',
      GoodsReceivedQcStats.fromJson,
    );
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

  Future<ApiResponse<T>> _getObject<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await _getRaw(endpoint);
    return response.when(
      success: (json) => ApiResponse.success(fromJson(json)),
      error: (error) => ApiResponse.error(error),
    );
  }

  Future<ApiResponse<T>> _patchObject<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await _apiClient
          .patch(endpoint, data: body)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

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
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> _getRaw(String endpoint) async {
    try {
      final response = await _apiClient
          .get(endpoint)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (data) {
          final json = data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};
          return ApiResponse.success(json);
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

  Map<String, dynamic> _unwrapData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return json;
  }
}
