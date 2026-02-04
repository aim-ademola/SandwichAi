import 'package:sandwich_ai/src/features/stock_control/data/model/procurement_req_model.dart';

enum ProcurementRequestErrorType {
  network,
  timeout,
  server,
  validation,
  general,
}

abstract class ProcurementRequestState {
  const ProcurementRequestState();
}

class ProcurementRequestInitial extends ProcurementRequestState {
  const ProcurementRequestInitial();
}

class ProcurementRequestLoading extends ProcurementRequestState {
  const ProcurementRequestLoading();
}

class ProcurementRequestSuccess extends ProcurementRequestState {
  final ProcurementRequestResponse response;
  final String message;

  const ProcurementRequestSuccess({
    required this.response,
    this.message = 'Procurement request created successfully!',
  });

  @override
  String toString() => 'ProcurementRequestSuccess(message: $message)';
}

class ProcurementRequestError extends ProcurementRequestState {
  final String error;
  final ProcurementRequestErrorType errorType;

  const ProcurementRequestError({
    required this.error,
    this.errorType = ProcurementRequestErrorType.general,
  });

  @override
  String toString() =>
      'ProcurementRequestError(error: $error, errorType: $errorType)';
}
