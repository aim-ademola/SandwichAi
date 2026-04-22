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
    Object? selectedReason = const _Unset(),
    Object? startDate = const _Unset(),
    Object? endDate = const _Unset(),
  }) {
    return WasteLogsLoaded(
      response: response ?? this.response,
      selectedReason: selectedReason is _Unset
          ? this.selectedReason
          : selectedReason as String?,
      startDate: startDate is _Unset ? this.startDate : startDate as String?,
      endDate: endDate is _Unset ? this.endDate : endDate as String?,
    );
  }
}

class _Unset {
  const _Unset();
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
