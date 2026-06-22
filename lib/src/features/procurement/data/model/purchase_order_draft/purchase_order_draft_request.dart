import 'package:sandwich_ai/src/features/procurement/data/model/order_item_request.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_draft/purchase_order_draft_status.dart';

class PurchaseOrderDraftRequest {
  final String supplierId;
  final String buyerId;
  final String buyerBranchId;
  final String organizationId;
  final String priority;
  final String? expectedDeliveryDate;
  final String? paymentTerm;
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? deliveryState;
  final String? deliveryInstructions;
  final String? buyerNotes;
  final List<OrderItemRequest> items;

  const PurchaseOrderDraftRequest({
    required this.supplierId,
    required this.buyerId,
    required this.buyerBranchId,
    required this.organizationId,
    required this.priority,
    this.expectedDeliveryDate,
    this.paymentTerm,
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryState,
    this.deliveryInstructions,
    this.buyerNotes,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'buyerId': buyerId,
      'buyerBranchId': buyerBranchId,
      'organizationId': organizationId,
      'priority': priority,
      'status': PurchaseOrderDraftStatus.draft.apiValue,
      if (expectedDeliveryDate != null)
        'expectedDeliveryDate': expectedDeliveryDate,
      if (paymentTerm != null) 'paymentTerm': paymentTerm,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (deliveryCity != null) 'deliveryCity': deliveryCity,
      if (deliveryState != null) 'deliveryState': deliveryState,
      if (deliveryInstructions != null)
        'deliveryInstructions': deliveryInstructions,
      if (buyerNotes != null) 'buyerNotes': buyerNotes,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
