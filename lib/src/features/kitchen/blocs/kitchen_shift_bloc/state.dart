// States
import 'package:sandwich_ai/src/features/kitchen/data/model/kitchen_shift_model.dart';

abstract class KitchenShiftState {
  const KitchenShiftState();
}

class KitchenShiftInitial extends KitchenShiftState {
  const KitchenShiftInitial();
}

class KitchenShiftLoading extends KitchenShiftState {
  const KitchenShiftLoading();
}

class KitchenShiftRefreshing extends KitchenShiftState {
  final List<KitchenShift> currentData;

  const KitchenShiftRefreshing({required this.currentData});
}

class KitchenShiftLoaded extends KitchenShiftState {
  final List<KitchenShift> allShifts;
  final List<KitchenShift> filteredShifts;
  final List<Employee> employees;
  final String? selectedEmployeeId;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, List<KitchenShift>> shiftsByEmployee;
  final Map<String, List<KitchenShift>> shiftsByDate;

  const KitchenShiftLoaded({
    required this.allShifts,
    required this.filteredShifts,
    required this.employees,
    this.selectedEmployeeId,
    this.startDate,
    this.endDate,
    required this.shiftsByEmployee,
    required this.shiftsByDate,
  });

  KitchenShiftLoaded copyWith({
    List<KitchenShift>? allShifts,
    List<KitchenShift>? filteredShifts,
    List<Employee>? employees,
    String? selectedEmployeeId,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, List<KitchenShift>>? shiftsByEmployee,
    Map<String, List<KitchenShift>>? shiftsByDate,
  }) {
    return KitchenShiftLoaded(
      allShifts: allShifts ?? this.allShifts,
      filteredShifts: filteredShifts ?? this.filteredShifts,
      employees: employees ?? this.employees,
      selectedEmployeeId: selectedEmployeeId ?? this.selectedEmployeeId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      shiftsByEmployee: shiftsByEmployee ?? this.shiftsByEmployee,
      shiftsByDate: shiftsByDate ?? this.shiftsByDate,
    );
  }
}

class KitchenShiftEmpty extends KitchenShiftState {
  const KitchenShiftEmpty();
}

class KitchenShiftOperationSuccess extends KitchenShiftState {
  final String message;
  final KitchenShift? shift;

  const KitchenShiftOperationSuccess({required this.message, this.shift});
}

enum KitchenShiftErrorType {
  network,
  timeout,
  server,
  validation,
  conflict,
  general,
}

class KitchenShiftError extends KitchenShiftState {
  final String error;
  final KitchenShiftErrorType errorType;

  const KitchenShiftError({required this.error, required this.errorType});
}

class KitchenShiftOperationInProgress extends KitchenShiftState {
  const KitchenShiftOperationInProgress();
}
