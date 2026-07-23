import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_draft_model.dart';

enum OrderErrorType { network, timeout, server, validation, general }

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderCreating extends OrderState {
  const OrderCreating();
}

class OrderCreated extends OrderState {
  final Map<String, dynamic> orderData;
  final String orderNumber;

  const OrderCreated({required this.orderData, required this.orderNumber});

  @override
  List<Object?> get props => [orderData, orderNumber];
}

class BulkOrdersCreated extends OrderState {
  final String message;
  final Map<String, dynamic> data;

  const BulkOrdersCreated({required this.message, required this.data});

  @override
  List<Object?> get props => [message, data];
}

class OrderDraftSaving extends OrderState {
  const OrderDraftSaving();
}

class OrderDraftSaved extends OrderState {
  final PurchaseOrderDraft draft;

  const OrderDraftSaved({required this.draft});

  @override
  List<Object?> get props => [draft.id, draft.status];
}

class OrderDraftLoading extends OrderState {
  const OrderDraftLoading();
}

class OrderDraftLoaded extends OrderState {
  final PurchaseOrderDraft draft;

  const OrderDraftLoaded({required this.draft});

  @override
  List<Object?> get props => [draft.id, draft.status];
}

class OrderError extends OrderState {
  final String error;
  final OrderErrorType errorType;

  const OrderError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}
