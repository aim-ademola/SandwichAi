import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_order_repo.dart';

abstract class PosOrderEvent extends Equatable {
  const PosOrderEvent();

  @override
  List<Object?> get props => [];
}

class CreatePosOrder extends PosOrderEvent {
  final String orderType;
  final String? tableNumber;
  final String? customerName;
  final String? customerPhone;
  final List<PosOrderItemPayload> items;
  final double discount;
  final String? specialInstructions;
  final bool confirmForKitchen;

  const CreatePosOrder({
    required this.orderType,
    this.tableNumber,
    this.customerName,
    this.customerPhone,
    required this.items,
    this.discount = 0,
    this.specialInstructions,
    this.confirmForKitchen = false,
  });

  @override
  List<Object?> get props => [
    orderType,
    tableNumber,
    customerName,
    customerPhone,
    items,
    discount,
    specialInstructions,
    confirmForKitchen,
  ];
}

class ResetPosOrderState extends PosOrderEvent {
  const ResetPosOrderState();
}
