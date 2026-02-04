import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/procurement_req_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/procurement_req_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/procurement_req_repo.dart';

class ProcurementRequestBloc
    extends Bloc<ProcurementRequestEvent, ProcurementRequestState> {
  final ProcurementRequestRepositoryInterface _repository;

  ProcurementRequestBloc({
    required ProcurementRequestRepositoryInterface repository,
  }) : _repository = repository,
       super(const ProcurementRequestInitial()) {
    on<CreateProcurementRequestEvent>(_onCreateProcurementRequest);
    on<ResetProcurementRequest>(_onResetProcurementRequest);
  }

  Future<void> _onCreateProcurementRequest(
    CreateProcurementRequestEvent event,
    Emitter<ProcurementRequestState> emit,
  ) async {
    try {
      emit(const ProcurementRequestLoading());

      final response = await _repository.createProcurementRequest(
        request: event.request,
      );

      await response.when(
        success: (data) async {
          emit(
            ProcurementRequestSuccess(
              response: data,
              message: 'Procurement request created successfully!',
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            ProcurementRequestError(
              error: error.toString(),
              errorType: errorType,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        const ProcurementRequestError(
          error: 'Failed to create procurement request. Please try again.',
          errorType: ProcurementRequestErrorType.general,
        ),
      );
    }
  }

  void _onResetProcurementRequest(
    ResetProcurementRequest event,
    Emitter<ProcurementRequestState> emit,
  ) {
    emit(const ProcurementRequestInitial());
  }

  ProcurementRequestErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return ProcurementRequestErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return ProcurementRequestErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return ProcurementRequestErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return ProcurementRequestErrorType.validation;
    }

    return ProcurementRequestErrorType.general;
  }
}
