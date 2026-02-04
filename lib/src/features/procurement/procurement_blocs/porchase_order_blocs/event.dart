import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/purchase_order_repo.dart';

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
