import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/payment_repo.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepositoryInterface _repository;

  PaymentBloc({required PaymentRepositoryInterface repository})
    : _repository = repository,
      super(const PaymentInitial()) {
    on<ProcessCashPayment>(_onProcessCashPayment);
    on<ProcessBankTransferPayment>(_onProcessBankTransferPayment);
    on<ResetPaymentState>(_onResetPaymentState);
  }

  Future<void> _onProcessCashPayment(
    ProcessCashPayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(const PaymentProcessing());

      final response = await _repository.processCashPayment(
        request: event.request,
      );

      await response.when(
        success: (paymentResponse) async {
          emit(PaymentSuccess(paymentResponse: paymentResponse));
        },
        error: (error) async {
          emit(PaymentError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        PaymentError(error: 'An unexpected error occurred: ${e.toString()}'),
      );
    }
  }

  Future<void> _onProcessBankTransferPayment(
    ProcessBankTransferPayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(const PaymentProcessing());

      final response = await _repository.processBankTransferPayment(
        request: event.request,
      );

      await response.when(
        success: (paymentResponse) async {
          emit(PaymentSuccess(paymentResponse: paymentResponse));
        },
        error: (error) async {
          emit(PaymentError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        PaymentError(error: 'An unexpected error occurred: ${e.toString()}'),
      );
    }
  }

  void _onResetPaymentState(
    ResetPaymentState event,
    Emitter<PaymentState> emit,
  ) {
    emit(const PaymentInitial());
  }
}
