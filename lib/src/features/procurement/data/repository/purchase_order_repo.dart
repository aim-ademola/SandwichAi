import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_action_model.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_draft_model.dart';

abstract class OrderRepositoryInterface {
  Future<ApiResponse<Map<String, dynamic>>> createOrder({
    required String supplierId,
    required String buyerId,
    required String buyerBranchId,
    required String priority,
    required String expectedDeliveryDate,
    required String paymentTerm,
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryState,
    required String orgId,
    String? deliveryInstructions,
    String? buyerNotes,
    required List<OrderItemRequest> items,
  });

  Future<ApiResponse<PurchaseOrderDraft>> createDraftOrder(
    PurchaseOrderDraftRequest request,
  );

  Future<ApiResponse<PurchaseOrderDraft>> updateDraftOrder({
    required String draftId,
    required PurchaseOrderDraftRequest request,
  });

  Future<ApiResponse<PurchaseOrderDraft>> getDraftOrder(String draftId);

  Future<ApiResponse<PurchaseOrderActionResponse>> updateOrder({
    required String orderId,
    required Map<String, dynamic> data,
  });

  Future<ApiResponse<PurchaseOrderActionResponse>> deleteOrder(String orderId);

  Future<ApiResponse<PurchaseOrderApprovalStatus>> getApprovalStatus(
    String orderId,
  );

  Future<ApiResponse<PurchaseOrderActionResponse>> submitApproval({
    required String orderId,
    SubmitPurchaseOrderApprovalRequest? request,
  });

  Future<ApiResponse<PurchaseOrderActionResponse>> dispatchOrder({
    required String orderId,
    required PurchaseOrderDispatchRequest request,
  });

  Future<ApiResponse<PurchaseOrderActionResponse>> bulkCreateOrders(
    BulkCreatePurchaseOrdersRequest request,
  );
}

class OrderRepository implements OrderRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  OrderRepository();

  @override
  Future<ApiResponse<Map<String, dynamic>>> createOrder({
    required String supplierId,
    required String buyerId,
    required String buyerBranchId,
    required String priority,
    required String expectedDeliveryDate,
    required String paymentTerm,
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryState,
    required String orgId,
    String? deliveryInstructions,
    String? buyerNotes,
    required List<OrderItemRequest> items,
  }) async {
    final data = <String, dynamic>{
      'supplierId': supplierId,
      'buyerId': buyerId,
      'buyerBranchId': buyerBranchId,
      'priority': priority,
      'expectedDeliveryDate': expectedDeliveryDate,
      'paymentTerm': paymentTerm,
      'organizationId': orgId,
      'deliveryAddress': deliveryAddress,
      'deliveryCity': deliveryCity,
      'deliveryState': deliveryState,
      'items': items.map((item) => item.toJson()).toList(),
    };
    if (deliveryInstructions != null) {
      data['deliveryInstructions'] = deliveryInstructions;
    }
    if (buyerNotes != null) {
      data['buyerNotes'] = buyerNotes;
    }

    return _apiClient.post<Map<String, dynamic>>(
      '/procurement/orders',
      data: data,
      fromJson: (json) =>
          json is Map ? json.cast<String, dynamic>() : <String, dynamic>{},
    );
  }

  @override
  Future<ApiResponse<PurchaseOrderDraft>> createDraftOrder(
    PurchaseOrderDraftRequest request,
  ) async {
    return _apiClient.post<PurchaseOrderDraft>(
      '/procurement/orders/drafts',
      data: request.toJson(),
      fromJson: (json) =>
          PurchaseOrderDraft.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<ApiResponse<PurchaseOrderDraft>> updateDraftOrder({
    required String draftId,
    required PurchaseOrderDraftRequest request,
  }) async {
    return _apiClient.patch<PurchaseOrderDraft>(
      '/procurement/orders/drafts/$draftId',
      data: request.toJson(),
      fromJson: (json) =>
          PurchaseOrderDraft.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<ApiResponse<PurchaseOrderDraft>> getDraftOrder(String draftId) async {
    return _apiClient.get<PurchaseOrderDraft>(
      '/procurement/orders/drafts/$draftId',
      fromJson: (json) =>
          PurchaseOrderDraft.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  @override
  Future<ApiResponse<PurchaseOrderActionResponse>> updateOrder({
    required String orderId,
    required Map<String, dynamic> data,
  }) {
    if (orderId.isEmpty) {
      return Future.value(
        ApiResponse.errorMessage('Order ID cannot be empty.'),
      );
    }
    return _action(
      () => _apiClient.patch('/procurement/orders/$orderId', data: data),
    );
  }

  @override
  Future<ApiResponse<PurchaseOrderActionResponse>> deleteOrder(String orderId) {
    if (orderId.isEmpty) {
      return Future.value(
        ApiResponse.errorMessage('Order ID cannot be empty.'),
      );
    }
    return _action(() => _apiClient.delete('/procurement/orders/$orderId'));
  }

  @override
  Future<ApiResponse<PurchaseOrderApprovalStatus>> getApprovalStatus(
    String orderId,
  ) async {
    if (orderId.isEmpty) {
      return ApiResponse.errorMessage('Order ID cannot be empty.');
    }
    final response = await _apiClient.get(
      '/procurement/orders/$orderId/approval-status',
    );
    return response.when(
      success: (data) {
        final json = data is Map
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
        return ApiResponse.success(PurchaseOrderApprovalStatus.fromJson(json));
      },
      error: (error) => ApiResponse.error(error),
    );
  }

  @override
  Future<ApiResponse<PurchaseOrderActionResponse>> submitApproval({
    required String orderId,
    SubmitPurchaseOrderApprovalRequest? request,
  }) {
    if (orderId.isEmpty) {
      return Future.value(
        ApiResponse.errorMessage('Order ID cannot be empty.'),
      );
    }
    return _action(
      () => _apiClient.post(
        '/procurement/orders/$orderId/submit-approval',
        data: request?.toJson() ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  Future<ApiResponse<PurchaseOrderActionResponse>> dispatchOrder({
    required String orderId,
    required PurchaseOrderDispatchRequest request,
  }) {
    if (orderId.isEmpty) {
      return Future.value(
        ApiResponse.errorMessage('Order ID cannot be empty.'),
      );
    }
    if (request.dispatchedBy.isEmpty) {
      return Future.value(
        ApiResponse.errorMessage('Dispatched by field cannot be empty.'),
      );
    }
    return _action(
      () => _apiClient.post(
        '/procurement/orders/$orderId/dispatch',
        data: request.toJson(),
      ),
    );
  }

  @override
  Future<ApiResponse<PurchaseOrderActionResponse>> bulkCreateOrders(
    BulkCreatePurchaseOrdersRequest request,
  ) {
    if (request.orders.isEmpty) {
      return Future.value(
        ApiResponse.errorMessage('At least one order is required.'),
      );
    }
    return _action(
      () => _apiClient.post(
        '/procurement/orders/bulk-create',
        data: request.toJson(),
      ),
    );
  }

  Future<ApiResponse<PurchaseOrderActionResponse>> _action(
    Future<ApiResponse<dynamic>> Function() call,
  ) async {
    final response = await call();
    return response.when(
      success: (data) {
        final json = data is Map
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
        return ApiResponse.success(PurchaseOrderActionResponse.fromJson(json));
      },
      error: (error) => ApiResponse.error(error),
    );
  }
}
