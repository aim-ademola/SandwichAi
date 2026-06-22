import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_draft_model.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class CreateOrder extends OrderEvent {
  final String supplierId;
  final String priority;
  final String expectedDeliveryDate;
  final String paymentTerm;
  final String deliveryAddress;
  final String deliveryCity;
  final String deliveryState;
  final String? deliveryInstructions;
  final String? buyerNotes;
  final List<OrderItemRequest> items;

  const CreateOrder({
    required this.supplierId,
    required this.priority,
    required this.expectedDeliveryDate,
    required this.paymentTerm,
    required this.deliveryAddress,
    required this.deliveryCity,
    required this.deliveryState,
    this.deliveryInstructions,
    this.buyerNotes,
    required this.items,
  });

  @override
  List<Object?> get props => [
    supplierId,
    priority,
    expectedDeliveryDate,
    paymentTerm,
    deliveryAddress,
    deliveryCity,
    deliveryState,
    deliveryInstructions,
    buyerNotes,
    items,
  ];
}

class ResetOrderState extends OrderEvent {
  const ResetOrderState();
}

class SaveOrderDraft extends OrderEvent {
  final String supplierId;
  final String priority;
  final String? expectedDeliveryDate;
  final String? paymentTerm;
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? deliveryState;
  final String? deliveryInstructions;
  final String? buyerNotes;
  final List<OrderItemRequest> items;

  const SaveOrderDraft({
    required this.supplierId,
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

  @override
  List<Object?> get props => [
    supplierId,
    priority,
    expectedDeliveryDate,
    paymentTerm,
    deliveryAddress,
    deliveryCity,
    deliveryState,
    deliveryInstructions,
    buyerNotes,
    items,
  ];
}

class UpdateOrderDraft extends SaveOrderDraft {
  final String draftId;

  const UpdateOrderDraft({
    required this.draftId,
    required super.supplierId,
    required super.priority,
    super.expectedDeliveryDate,
    super.paymentTerm,
    super.deliveryAddress,
    super.deliveryCity,
    super.deliveryState,
    super.deliveryInstructions,
    super.buyerNotes,
    required super.items,
  });

  @override
  List<Object?> get props => [draftId, ...super.props];
}

class LoadOrderDraft extends OrderEvent {
  final String draftId;

  const LoadOrderDraft({required this.draftId});

  @override
  List<Object?> get props => [draftId];
}

class SubmitDraftForApproval extends OrderEvent {
  final PurchaseOrderDraft draft;

  const SubmitDraftForApproval({required this.draft});

  @override
  List<Object?> get props => [draft.id];
}
