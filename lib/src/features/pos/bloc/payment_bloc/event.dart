import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/pos/data/model/payment_model.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class ProcessCashPayment extends PaymentEvent {
  final CashPaymentRequest request;

  const ProcessCashPayment({required this.request});

  @override
  List<Object?> get props => [request];
}

class ProcessBankTransferPayment extends PaymentEvent {
  final BankTransferPaymentRequest request;

  const ProcessBankTransferPayment({required this.request});

  @override
  List<Object?> get props => [request];
}

class ResetPaymentState extends PaymentEvent {
  const ResetPaymentState();
}
