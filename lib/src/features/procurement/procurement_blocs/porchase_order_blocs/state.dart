import 'package:equatable/equatable.dart';

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

class OrderError extends OrderState {
  final String error;
  final OrderErrorType errorType;

  const OrderError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}
