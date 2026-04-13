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

//  Cash States ──

/// Cash payment recorded — awaiting manager approval
class CashPaymentPendingApproval extends PaymentState {
  final CashTransaction transaction;

  const CashPaymentPendingApproval({required this.transaction});

  @override
  List<Object?> get props => [transaction];
}

/// ID disappeared from pending list — payment approved
class CashPaymentApproved extends PaymentState {
  const CashPaymentApproved();
}

/// Still in pending list — continue polling
class CashPaymentStillPending extends PaymentState {
  const CashPaymentStillPending();
}

//  Online Payment States ─

/// Online payment initialized — show QR / link
class OnlinePaymentInitialized extends PaymentState {
  final OnlinePaymentInitData initData;

  const OnlinePaymentInitialized({required this.initData});

  @override
  List<Object?> get props => [initData];
}

/// Still PENDING — continue polling
class OnlinePaymentStillPending extends PaymentState {
  const OnlinePaymentStillPending();
}

/// Status = COMPLETED
class OnlinePaymentCompleted extends PaymentState {
  final OnlinePaymentStatusData statusData;

  const OnlinePaymentCompleted({required this.statusData});

  @override
  List<Object?> get props => [statusData];
}

/// Status = FAILED
class OnlinePaymentFailed extends PaymentState {
  final String? reason;

  const OnlinePaymentFailed({this.reason});

  @override
  List<Object?> get props => [reason];
}

//  Shared Error ─

class PaymentError extends PaymentState {
  final String error;

  const PaymentError({required this.error});

  @override
  List<Object?> get props => [error];
}
