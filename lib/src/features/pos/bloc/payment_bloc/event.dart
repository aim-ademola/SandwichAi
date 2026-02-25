import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/pos/data/model/payment_model.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class RecordCashPayment extends PaymentEvent {
  final CashPaymentRequest request;

  const RecordCashPayment({required this.request});

  @override
  List<Object?> get props => [request];
}

class PollCashApprovalStatus extends PaymentEvent {
  final String transactionId;
  final String branchId;

  const PollCashApprovalStatus({
    required this.transactionId,
    required this.branchId,
  });

  @override
  List<Object?> get props => [transactionId, branchId];
}

class InitializeOnlinePayment extends PaymentEvent {
  final OnlinePaymentRequest request;

  const InitializeOnlinePayment({required this.request});

  @override
  List<Object?> get props => [request];
}

class PollOnlinePaymentStatus extends PaymentEvent {
  final String reference;

  const PollOnlinePaymentStatus({required this.reference});

  @override
  List<Object?> get props => [reference];
}

class ResetPaymentState extends PaymentEvent {
  const ResetPaymentState();
}
