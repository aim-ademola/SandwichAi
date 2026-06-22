import 'package:sandwich_ai/src/features/procurement/data/model/order_item_request.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_draft/purchase_order_draft_status.dart';

class PurchaseOrderDraft {
  final String id;
  final String? orderNumber;
  final String supplierId;
  final String buyerId;
  final String buyerBranchId;
  final String organizationId;
  final PurchaseOrderDraftStatus status;
  final String priority;
  final String? expectedDeliveryDate;
  final String? paymentTerm;
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? deliveryState;
  final String? deliveryInstructions;
  final String? buyerNotes;
  final List<OrderItemRequest> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> rawData;

  const PurchaseOrderDraft({
    required this.id,
    this.orderNumber,
    required this.supplierId,
    required this.buyerId,
    required this.buyerBranchId,
    required this.organizationId,
    required this.status,
    required this.priority,
    this.expectedDeliveryDate,
    this.paymentTerm,
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryState,
    this.deliveryInstructions,
    this.buyerNotes,
    required this.items,
    this.createdAt,
    this.updatedAt,
    required this.rawData,
  });

  factory PurchaseOrderDraft.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return PurchaseOrderDraft(
      id: data['id']?.toString() ?? '',
      orderNumber: data['orderNumber']?.toString(),
      supplierId: data['supplierId']?.toString() ?? '',
      buyerId: data['buyerId']?.toString() ?? '',
      buyerBranchId: data['buyerBranchId']?.toString() ?? '',
      organizationId: data['organizationId']?.toString() ?? '',
      status: PurchaseOrderDraftStatusX.fromApiValue(
        data['status']?.toString(),
      ),
      priority: data['priority']?.toString() ?? '',
      expectedDeliveryDate: data['expectedDeliveryDate']?.toString(),
      paymentTerm: data['paymentTerm']?.toString(),
      deliveryAddress: data['deliveryAddress']?.toString(),
      deliveryCity: data['deliveryCity']?.toString(),
      deliveryState: data['deliveryState']?.toString(),
      deliveryInstructions: data['deliveryInstructions']?.toString(),
      buyerNotes: data['buyerNotes']?.toString(),
      items: ((data['items'] as List?) ?? [])
          .whereType<Map>()
          .map(
            (item) => OrderItemRequest.fromJson(item.cast<String, dynamic>()),
          )
          .toList(),
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? ''),
      rawData: data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (orderNumber != null) 'orderNumber': orderNumber,
      'supplierId': supplierId,
      'buyerId': buyerId,
      'buyerBranchId': buyerBranchId,
      'organizationId': organizationId,
      'status': status.apiValue,
      'priority': priority,
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
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
