import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/payment_repo.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepositoryInterface _repository;

  PaymentBloc({required PaymentRepositoryInterface repository})
    : _repository = repository,
      super(const PaymentInitial()) {
    on<RecordCashPayment>(_onRecordCashPayment);
    on<PollCashApprovalStatus>(_onPollCashApprovalStatus);
    on<InitializeOnlinePayment>(_onInitializeOnlinePayment);
    on<PollOnlinePaymentStatus>(_onPollOnlinePaymentStatus);
    on<ResetPaymentState>(_onResetPaymentState);
  }

  // ─── Cash ────────────────────────────────────────────────────────────────

  Future<void> _onRecordCashPayment(
    RecordCashPayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(const PaymentProcessing());

      final response = await _repository.recordCashPayment(
        request: event.request,
      );

      await response.when(
        success: (data) async {
          AppLogger.log(
            'Cash recorded: ${data.data.transaction.transactionId}',
          );
          emit(CashPaymentPendingApproval(transaction: data.data.transaction));
        },
        error: (error) async {
          emit(PaymentError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(PaymentError(error: 'Unexpected error: ${e.toString()}'));
    }
  }

  Future<void> _onPollCashApprovalStatus(
    PollCashApprovalStatus event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final response = await _repository.getPendingCashTransactions(
        branchId: event.branchId,
      );

      await response.when(
        success: (data) async {
          // If our transaction ID is NOT in the pending list → approved/completed
          final stillPending = data.data.any(
            (t) => t.transactionId == event.transactionId,
          );

          if (stillPending) {
            emit(const CashPaymentStillPending());
          } else {
            AppLogger.log(
              '${event.transactionId} not in pending list → approved',
            );
            emit(const CashPaymentApproved());
          }
        },
        error: (error) async {
          AppLogger.log('Poll error (ignored): $error');
          emit(const CashPaymentStillPending());
        },
      );
    } catch (e) {
      AppLogger.log('Poll exception (ignored): $e');
      emit(const CashPaymentStillPending());
    }
  }

  // ─── Online ──────────────────────────────────────────────────────────────

  Future<void> _onInitializeOnlinePayment(
    InitializeOnlinePayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(const PaymentProcessing());

      final response = await _repository.initializeOnlinePayment(
        request: event.request,
      );

      await response.when(
        success: (data) async {
          AppLogger.log('Online payment initialized: ${data.data.reference}');
          emit(OnlinePaymentInitialized(initData: data.data));
        },
        error: (error) async {
          emit(PaymentError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(PaymentError(error: 'Unexpected error: ${e.toString()}'));
    }
  }

  Future<void> _onPollOnlinePaymentStatus(
    PollOnlinePaymentStatus event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final response = await _repository.checkOnlinePaymentStatus(
        reference: event.reference,
      );

      await response.when(
        success: (data) async {
          final status = data.data.status;
          AppLogger.log('Online payment status: $status');

          if (status == 'COMPLETED') {
            emit(OnlinePaymentCompleted(statusData: data.data));
          } else if (status == 'FAILED') {
            emit(OnlinePaymentFailed(reason: data.data.failureReason));
          } else {
            emit(const OnlinePaymentStillPending());
          }
        },
        error: (error) async {
          AppLogger.log('Online poll error (ignored): $error');
          emit(const OnlinePaymentStillPending());
        },
      );
    } catch (e) {
      AppLogger.log('Online poll exception (ignored): $e');
      emit(const OnlinePaymentStillPending());
    }
  }

  void _onResetPaymentState(
    ResetPaymentState event,
    Emitter<PaymentState> emit,
  ) {
    emit(const PaymentInitial());
  }
}
