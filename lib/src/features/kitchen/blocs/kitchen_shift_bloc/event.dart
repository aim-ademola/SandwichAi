import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/kitchen/data/model/kitchen_shift_model.dart';

// Events
abstract class KitchenShiftEvent {
  const KitchenShiftEvent();
}

class LoadKitchenShifts extends KitchenShiftEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? employeeId;

  const LoadKitchenShifts({this.startDate, this.endDate, this.employeeId});
}

class LoadKitchenEmployees extends KitchenShiftEvent {
  const LoadKitchenEmployees();
}

class CreateShift extends KitchenShiftEvent {
  final CreateKitchenShiftRequest request;

  const CreateShift({required this.request});
}

class UpdateShift extends KitchenShiftEvent {
  final String shiftId;
  final UpdateKitchenShiftRequest request;

  const UpdateShift({required this.shiftId, required this.request});
}

class DeleteShift extends KitchenShiftEvent {
  final String shiftId;

  const DeleteShift({required this.shiftId});
}

class FilterShiftsByEmployee extends KitchenShiftEvent {
  final String? employeeId;

  const FilterShiftsByEmployee({this.employeeId});
}

class FilterShiftsByDateRange extends KitchenShiftEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterShiftsByDateRange({this.startDate, this.endDate});
}

class RefreshKitchenShifts extends KitchenShiftEvent {
  const RefreshKitchenShifts();
}

class ClearShiftFilters extends KitchenShiftEvent {
  const ClearShiftFilters();
}
