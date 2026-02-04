import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/pos/data/model/payment_model.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentProcessing extends PaymentState {
  const PaymentProcessing();
}

class PaymentSuccess extends PaymentState {
  final PaymentResponseModel paymentResponse;

  const PaymentSuccess({required this.paymentResponse});

  @override
  List<Object?> get props => [paymentResponse];
}

class PaymentError extends PaymentState {
  final String error;

  const PaymentError({required this.error});

  @override
  List<Object?> get props => [error];
}
