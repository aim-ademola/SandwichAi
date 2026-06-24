import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
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
    return _apiClient.post<Map<String, dynamic>>(
      '/procurement/orders',
      data: {
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
        if (deliveryInstructions != null)
          'deliveryInstructions': deliveryInstructions,
        if (buyerNotes != null) 'buyerNotes': buyerNotes,
        'items': items.map((item) => item.toJson()).toList(),
      },
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
}
