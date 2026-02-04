import 'package:sandwich_ai/src/features/stock_control/data/model/wastage_log.dart';

abstract class WasteLogsState {
  const WasteLogsState();
}

class WasteLogsInitial extends WasteLogsState {
  const WasteLogsInitial();
}

class WasteLogsLoading extends WasteLogsState {
  const WasteLogsLoading();
}

class WasteLogsLoaded extends WasteLogsState {
  final WasteLogsResponse response;
  final String? selectedReason;
  final String? startDate;
  final String? endDate;

  const WasteLogsLoaded({
    required this.response,
    this.selectedReason,
    this.startDate,
    this.endDate,
  });

  WasteLogsLoaded copyWith({
    WasteLogsResponse? response,
    String? selectedReason,
    String? startDate,
    String? endDate,
  }) {
    return WasteLogsLoaded(
      response: response ?? this.response,
      selectedReason: selectedReason ?? this.selectedReason,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class WasteLogsEmpty extends WasteLogsState {
  const WasteLogsEmpty();
}

class WasteLogsError extends WasteLogsState {
  final String error;

  const WasteLogsError({required this.error});
}

class WasteLogCreating extends WasteLogsState {
  const WasteLogCreating();
}

class WasteLogCreated extends WasteLogsState {
  final WasteLogItem item;

  const WasteLogCreated({required this.item});
}

class WasteLogCreateError extends WasteLogsState {
  final String error;

  const WasteLogCreateError({required this.error});
}
