import 'package:sandwich_ai/src/features/stock_control/data/model/wastage_log.dart';

abstract class WasteLogsEvent {}

class LoadWasteLogs extends WasteLogsEvent {
  final String branchId;
  final String? reason;
  final String? startDate;
  final String? endDate;

  LoadWasteLogs({
    required this.branchId,
    this.reason,
    this.startDate,
    this.endDate,
  });
}

class CreateWasteLog extends WasteLogsEvent {
  final WasteLogRequest request;

  CreateWasteLog({required this.request});
}

class FilterByReason extends WasteLogsEvent {
  final String? reason;

  FilterByReason({this.reason});
}

class FilterByDateRange extends WasteLogsEvent {
  final String? startDate;
  final String? endDate;

  FilterByDateRange({this.startDate, this.endDate});
}

class RefreshWasteLogs extends WasteLogsEvent {}
