import 'dart:async';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/core/network/connectivity_service.dart';
import 'package:sandwich_ai/src/core/offline/offline_queue_manager.dart';
import 'package:sandwich_ai/src/core/offline/pending_req.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/add_branchstock.dart';

abstract class AddBranchStockRepositoryInterface {
  Future<ApiResponse<BranchStockResponse>> createBranchStock(
    BranchStockRequest request,
  );
  Future<ApiResponse<BranchStockResponse>> updateBranchStock(
    String stockId,
    BranchStockRequest request,
  );
  Future<ApiResponse<bool>> deleteBranchStock(String stockId);
  Future<ApiResponse<StockAdjustmentResponse>> adjustBranchStock(
    String stockId,
    StockAdjustmentRequest request,
  );
  Future<ApiResponse<BranchStockControlResponse>> allowNegativeStock(
    String stockId,
  );
  Future<ApiResponse<BranchStockControlResponse>> lockStock(String stockId);
  Future<ApiResponse<BranchStockControlResponse>> unlockStock(String stockId);
  Future<ApiResponse<BranchStockControlListResponse>> getLockedStock();
  Future<ApiResponse<BranchStockControlListResponse>> getNegativeStockReport();
}

class AddBranchStockRepository extends BaseRepository
    implements AddBranchStockRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<BranchStockResponse>> createBranchStock(
    BranchStockRequest request,
  ) async {
    try {
      _validateBranchStockRequest(request);

      final online = await ConnectivityService.instance.isOnline;

      if (!online) {
        await OfflineQueueManager.instance.add(
          PendingRequest(
            method: "POST",
            url: "branch-stock",
            body: request.toJson(),
          ),
          onSaved: () {
            // showToast("Request saved. Will retry automatically.");
          },
        );

        return ApiResponse.errorMessage(
          "No internet. Request saved for retry.",
        );
      }

      final response = await _apiClient
          .post("branch-stock", data: request.toJson())
          .timeout(const Duration(seconds: 30));

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseBranchStockResponse(json),
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<BranchStockResponse>> updateBranchStock(
    String stockId,
    BranchStockRequest request,
  ) async {
    try {
      _validateBranchStockRequest(request);

      final online = await ConnectivityService.instance.isOnline;

      if (!online) {
        await OfflineQueueManager.instance.add(
          PendingRequest(
            method: "PATCH",
            url: "branch-stock/$stockId",
            body: request.toJson(),
          ),
        );

        return ApiResponse.errorMessage(
          "Offline detected. Update request cached and will sync automatically.",
        );
      }

      final response = await _apiClient
          .patch("branch-stock/$stockId", data: request.toJson())
          .timeout(const Duration(seconds: 30));

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseBranchStockResponse(json),
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<bool>> deleteBranchStock(String stockId) async {
    try {
      if (stockId.isEmpty) {
        throw FormatException('Stock ID cannot be empty');
      }

      final online = await ConnectivityService.instance.isOnline;

      if (!online) {
        await OfflineQueueManager.instance.add(
          PendingRequest(
            method: "DELETE",
            url: "branch-stock/$stockId",
            body: {},
          ),
        );

        return ApiResponse.errorMessage(
          "Offline detected. Delete request cached and will sync automatically.",
        );
      }

      final response = await _apiClient
          .delete("branch-stock/$stockId")
          .timeout(const Duration(seconds: 30));

      return handleObjectResponse(Future.value(response), (json) => true);
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<StockAdjustmentResponse>> adjustBranchStock(
    String stockId,
    StockAdjustmentRequest request,
  ) async {
    try {
      // Get the current employee ID
      final empId = await AuthCacheHelper.instance.getEmpID() ?? '';

      // Create a new request with performedBy automatically
      final adjustedRequest = StockAdjustmentRequest(
        type: request.type,
        quantity: request.quantity,
        note: request.note,
        performedBy: empId, // ✅ automatically added
      );

      _validateStockAdjustmentRequest(adjustedRequest);

      final online = await ConnectivityService.instance.isOnline;

      if (!online) {
        await OfflineQueueManager.instance.add(
          PendingRequest(
            method: "PATCH",
            url: "branch-stock/$stockId/adjust",
            body: adjustedRequest.toJson(),
          ),
        );

        return ApiResponse.errorMessage(
          "Offline detected. Adjustment request cached and will sync automatically.",
        );
      }

      final response = await _apiClient
          .patch("branch-stock/$stockId/adjust", data: adjustedRequest.toJson())
          .timeout(const Duration(seconds: 30));

      return handleObjectResponse(
        Future.value(response),
        (json) => _parseStockAdjustmentResponse(json),
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<BranchStockControlResponse>> allowNegativeStock(
    String stockId,
  ) {
    return _patchStockControl('branch-stock/$stockId/allow-negative', stockId);
  }

  @override
  Future<ApiResponse<BranchStockControlResponse>> lockStock(String stockId) {
    return _patchStockControl('branch-stock/$stockId/lock', stockId);
  }

  @override
  Future<ApiResponse<BranchStockControlResponse>> unlockStock(String stockId) {
    return _patchStockControl('branch-stock/$stockId/unlock', stockId);
  }

  @override
  Future<ApiResponse<BranchStockControlListResponse>> getLockedStock() {
    return _getStockControlList('branch-stock/locked');
  }

  @override
  Future<ApiResponse<BranchStockControlListResponse>> getNegativeStockReport() {
    return _getStockControlList('branch-stock/negative-stock-report');
  }

  /// Validates branch stock request fields
  void _validateBranchStockRequest(BranchStockRequest request) {
    if (request.itemId.isEmpty) {
      throw FormatException('Item ID cannot be empty');
    }

    if (request.branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }

    if (request.currentStock < 0) {
      throw FormatException('Current stock cannot be negative');
    }

    if (request.reorderLevel < 0) {
      throw FormatException('Reorder level cannot be negative');
    }

    if (request.maxLevel <= 0) {
      throw FormatException('Max level must be greater than zero');
    }

    if (request.maxLevel < request.reorderLevel) {
      throw FormatException(
        'Max level must be greater than or equal to reorder level',
      );
    }

    if (request.unitCost < 0) {
      throw FormatException('Unit cost cannot be negative');
    }

    if (request.expiryDate.isEmpty) {
      throw FormatException('Expiry date cannot be empty');
    }

    if (!_isValidDate(request.expiryDate)) {
      throw FormatException('Invalid expiry date format. Use YYYY-MM-DD');
    }
  }

  /// Validates stock adjustment request
  void _validateStockAdjustmentRequest(StockAdjustmentRequest request) {
    if (request.type.isEmpty) {
      throw FormatException('Adjustment type cannot be empty');
    }

    final validTypes = ['ADD', 'SUBTRACT', 'SET'];
    if (!validTypes.contains(request.type.toUpperCase())) {
      throw FormatException(
        'Invalid adjustment type. Must be ADD, SUBTRACT, or SET',
      );
    }

    if (request.quantity <= 0) {
      throw FormatException('Quantity must be greater than zero');
    }

    if (request.performedBy.isEmpty) {
      throw FormatException('Performed by field cannot be empty');
    }
  }

  /// Validates date format
  bool _isValidDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return parsedDate.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Parse branch stock response with error handling
  BranchStockResponse _parseBranchStockResponse(Map<String, dynamic> json) {
    try {
      final response = BranchStockResponse.fromJson(json);

      if (!response.isValid) {
        throw FormatException(
          response.message.isNotEmpty
              ? response.message
              : 'Invalid stock data received',
        );
      }

      return response;
    } catch (e) {
      throw FormatException('Unable to process response: ${e.toString()}');
    }
  }

  /// Parse stock adjustment response with error handling
  StockAdjustmentResponse _parseStockAdjustmentResponse(
    Map<String, dynamic> json,
  ) {
    try {
      final response = StockAdjustmentResponse.fromJson(json);

      // ✅ FIX: Don't throw error if response has a valid message
      // The API might not include a 'success' field, but if there's a message, it's valid
      if (!response.isValid) {
        throw FormatException('Invalid adjustment data received');
      }

      return response;
    } catch (e) {
      // Only throw if it's a parsing error, not a validation error
      if (e is FormatException &&
          e.message == 'Invalid adjustment data received') {
        rethrow;
      }
      throw FormatException('Unable to process response: ${e.toString()}');
    }
  }

  /// Parse error messages to user-friendly format
  String _parseErrorMessage(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('401') ||
        lowercaseError.contains('unauthorized')) {
      return 'Unauthorized. Please log in again.';
    }

    if (lowercaseError.contains('403') ||
        lowercaseError.contains('forbidden')) {
      return 'Access denied. You do not have permission.';
    }

    if (lowercaseError.contains('404') ||
        lowercaseError.contains('not found')) {
      return 'Stock item not found.';
    }

    if (lowercaseError.contains('409') || lowercaseError.contains('conflict')) {
      return 'Stock item already exists for this branch.';
    }

    if (lowercaseError.contains('422') ||
        lowercaseError.contains('unprocessable')) {
      return 'Invalid data provided. Please check your input.';
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

    return 'Operation failed. Please try again later.';
  }

  Future<ApiResponse<BranchStockControlResponse>> _patchStockControl(
    String endpoint,
    String stockId,
  ) async {
    try {
      if (stockId.isEmpty) {
        throw FormatException('Stock ID cannot be empty');
      }

      final online = await ConnectivityService.instance.isOnline;
      if (!online) {
        await OfflineQueueManager.instance.add(
          PendingRequest(method: "PATCH", url: endpoint, body: {}),
        );
        return ApiResponse.errorMessage(
          "Offline detected. Stock control request cached and will sync automatically.",
        );
      }

      final response = await _apiClient
          .patch(endpoint, data: const <String, dynamic>{})
          .timeout(const Duration(seconds: 30));

      return response.when(
        success: (data) {
          final json = data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};
          return ApiResponse.success(BranchStockControlResponse.fromJson(json));
        },
        error: (error) => ApiResponse.error(error),
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  Future<ApiResponse<BranchStockControlListResponse>> _getStockControlList(
    String endpoint,
  ) async {
    try {
      final response = await _apiClient
          .get(endpoint)
          .timeout(const Duration(seconds: 30));

      return response.when(
        success: (data) {
          final json = data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};
          return ApiResponse.success(
            BranchStockControlListResponse.fromJson(json),
          );
        },
        error: (error) => ApiResponse.error(error),
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }
}

class BranchStockControlResponse {
  final bool success;
  final String message;
  final Map<String, dynamic> data;
  final Map<String, dynamic> raw;

  const BranchStockControlResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.raw,
  });

  factory BranchStockControlResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    return BranchStockControlResponse(
      success:
          json['success'] == true ||
          (json['message'] ?? '').toString().isNotEmpty,
      message: json['message']?.toString() ?? '',
      data: data.isNotEmpty ? data : json,
      raw: json,
    );
  }
}

class BranchStockControlListResponse {
  final String message;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> raw;

  const BranchStockControlListResponse({
    required this.message,
    required this.items,
    required this.summary,
    required this.raw,
  });

  factory BranchStockControlListResponse.fromJson(Map<String, dynamic> json) {
    final list = _extractControlList(json);
    return BranchStockControlListResponse(
      message: json['message']?.toString() ?? '',
      items: list
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      summary: _asMap(json['summary']),
      raw: json,
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> _extractControlList(Map<String, dynamic> json) {
  for (final key in const ['data', 'items', 'results']) {
    final value = json[key];
    if (value is List) return value;
  }
  final data = json['data'];
  if (data is Map) {
    for (final key in const ['items', 'results', 'stocks']) {
      final value = data[key];
      if (value is List) return value;
    }
  }
  return const [];
}

/// Stock Adjustment Request Model
class StockAdjustmentRequest {
  final String type; // ADD, SUBTRACT, SET
  final double quantity;
  final String note;
  final String performedBy;

  StockAdjustmentRequest({
    required this.type,
    required this.quantity,
    required this.note,
    required this.performedBy,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toUpperCase(),
    'quantity': quantity,
    'note': note,
    'performedBy': performedBy,
  };
}

/// Stock Adjustment Response Model
class StockAdjustmentResponse {
  final bool success;
  final String message;
  final int? previousQuantity;
  final int? newQuantity;
  final DateTime? adjustedAt;

  StockAdjustmentResponse({
    required this.success,
    required this.message,
    this.previousQuantity,
    this.newQuantity,
    this.adjustedAt,
  });

  factory StockAdjustmentResponse.fromJson(Map<String, dynamic> json) {
    return StockAdjustmentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      previousQuantity: json['previousQuantity'],
      newQuantity: json['newQuantity'],
      adjustedAt: json['adjustedAt'] != null
          ? DateTime.parse(json['adjustedAt'])
          : null,
    );
  }

  // ✅ FIX: Changed from AND to OR - if there's a message, consider it valid
  // Many APIs don't include an explicit 'success' field
  bool get isValid => success || message.isNotEmpty;
}
