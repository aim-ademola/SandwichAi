import 'package:sandwich_ai/src/features/stock_control/data/model/procurement_req_model.dart';

abstract class ProcurementRequestEvent {
  const ProcurementRequestEvent();
}

class CreateProcurementRequestEvent extends ProcurementRequestEvent {
  final CreateProcurementRequest request;

  const CreateProcurementRequestEvent({required this.request});
}

class ResetProcurementRequest extends ProcurementRequestEvent {
  const ResetProcurementRequest();
}
