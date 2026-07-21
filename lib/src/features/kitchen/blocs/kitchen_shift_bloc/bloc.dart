// BLoC
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen_shift_bloc/event.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen_shift_bloc/state.dart';
import 'package:sandwich_ai/src/features/kitchen/data/model/kitchen_shift_model.dart'
    show CreateKitchenShiftRequest, Employee, KitchenShift;
import 'package:sandwich_ai/src/features/kitchen/data/repo/kitchn_shift_repo.dart';

class KitchenShiftBloc extends Bloc<KitchenShiftEvent, KitchenShiftState> {
  final KitchenShiftRepositoryInterface _repository;
  String branchId = '';

  KitchenShiftBloc({required KitchenShiftRepositoryInterface repository})
    : _repository = repository,
      super(const KitchenShiftInitial()) {
    _getBranchId();
    on<LoadKitchenShifts>(_onLoadKitchenShifts);
    on<LoadKitchenEmployees>(_onLoadKitchenEmployees);
    on<CreateShift>(_onCreateShift);
    on<UpdateShift>(_onUpdateShift);
    on<DeleteShift>(_onDeleteShift);
    on<FilterShiftsByEmployee>(_onFilterShiftsByEmployee);
    on<FilterShiftsByDateRange>(_onFilterShiftsByDateRange);
    on<RefreshKitchenShifts>(_onRefreshKitchenShifts);
    on<ClearShiftFilters>(_onClearShiftFilters);
  }

  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  Future<void> _onLoadKitchenShifts(
    LoadKitchenShifts event,
    Emitter<KitchenShiftState> emit,
  ) async {
    try {
      emit(const KitchenShiftLoading());
      final resolvedBranchId = await _resolveBranchId();

      if (resolvedBranchId.isEmpty) {
        emit(
          const KitchenShiftError(
            error: 'Branch ID not found. Please login again.',
            errorType: KitchenShiftErrorType.validation,
          ),
        );
        return;
      }

      // Load employees first
      final employeesResponse = await _repository.getKitchenEmployees(
        branchId: resolvedBranchId,
      );

      List<Employee> employees = [];
      await employeesResponse.when(
        success: (data) async {
          employees = data;
        },
        error: (error) async {
          // Continue even if employees fail to load
        },
      );

      // Load shifts
      final shiftsResponse = await _repository.getKitchenShifts(
        branchId: resolvedBranchId,
        startDate: event.startDate,
        endDate: event.endDate,
        employeeId: event.employeeId,
      );

      await shiftsResponse.when(
        success: (shifts) async {
          if (shifts.isEmpty) {
            emit(
              KitchenShiftEmpty(
                employees: employees,
                startDate: event.startDate,
                endDate: event.endDate,
              ),
            );
            return;
          }

          final shiftsByEmployee = _groupShiftsByEmployee(shifts);
          final shiftsByDate = _groupShiftsByDate(shifts);

          emit(
            KitchenShiftLoaded(
              allShifts: shifts,
              filteredShifts: shifts,
              employees: employees,
              startDate: event.startDate,
              endDate: event.endDate,
              selectedEmployeeId: event.employeeId,
              shiftsByEmployee: shiftsByEmployee,
              shiftsByDate: shiftsByDate,
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            KitchenShiftError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const KitchenShiftError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: KitchenShiftErrorType.general,
        ),
      );
    }
  }

  Future<void> _onLoadKitchenEmployees(
    LoadKitchenEmployees event,
    Emitter<KitchenShiftState> emit,
  ) async {
    final resolvedBranchId = await _resolveBranchId();

    if (resolvedBranchId.isEmpty) {
      return;
    }

    final response = await _repository.getKitchenEmployees(
      branchId: resolvedBranchId,
    );

    await response.when(
      success: (employees) async {
        if (state is KitchenShiftLoaded) {
          // Update employees inside the loaded state
          final currentState = state as KitchenShiftLoaded;
          emit(currentState.copyWith(employees: employees));
        } else if (state is KitchenShiftEmpty) {
          final currentState = state as KitchenShiftEmpty;
          emit(
            KitchenShiftEmpty(
              employees: employees,
              startDate: currentState.startDate,
              endDate: currentState.endDate,
            ),
          );
        } else {
          // If not loaded yet, emit a temporary state
          emit(
            KitchenShiftLoaded(
              allShifts: const [],
              filteredShifts: const [],
              employees: employees,
              startDate: null,
              endDate: null,
              selectedEmployeeId: null,
              shiftsByEmployee: const {},
              shiftsByDate: const {},
            ),
          );
        }
      },
      error: (error) async {
        // Keep state unchanged
      },
    );
  }

  Future<void> _onCreateShift(
    CreateShift event,
    Emitter<KitchenShiftState> emit,
  ) async {
    emit(const KitchenShiftOperationInProgress());
    final resolvedBranchId = await _resolveBranchId();

    if (resolvedBranchId.isEmpty) {
      emit(
        const KitchenShiftError(
          error: 'Branch ID not found. Please login again.',
          errorType: KitchenShiftErrorType.validation,
        ),
      );
      return;
    }

    final request = event.request.branchId.isEmpty
        ? CreateKitchenShiftRequest(
            employeeId: event.request.employeeId,
            branchId: resolvedBranchId,
            date: event.request.date,
            shiftType: event.request.shiftType,
            startTime: event.request.startTime,
            endTime: event.request.endTime,
            notes: event.request.notes,
          )
        : event.request;

    final response = await _repository.createKitchenShift(request: request);

    await response.when(
      success: (shift) async {
        emit(
          KitchenShiftOperationSuccess(
            message: 'Shift created successfully!',
            shift: shift,
          ),
        );
        // Reload shifts
        add(const LoadKitchenShifts());
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(KitchenShiftError(error: error.toString(), errorType: errorType));
      },
    );
  }

  Future<void> _onUpdateShift(
    UpdateShift event,
    Emitter<KitchenShiftState> emit,
  ) async {
    emit(const KitchenShiftOperationInProgress());

    final response = await _repository.updateKitchenShift(
      shiftId: event.shiftId,
      request: event.request,
    );

    await response.when(
      success: (shift) async {
        emit(
          KitchenShiftOperationSuccess(
            message: 'Shift updated successfully!',
            shift: shift,
          ),
        );
        // Reload shifts
        add(const LoadKitchenShifts());
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(KitchenShiftError(error: error.toString(), errorType: errorType));
      },
    );
  }

  Future<void> _onDeleteShift(
    DeleteShift event,
    Emitter<KitchenShiftState> emit,
  ) async {
    emit(const KitchenShiftOperationInProgress());

    final response = await _repository.deleteKitchenShift(
      shiftId: event.shiftId,
    );

    await response.when(
      success: (_) async {
        emit(
          const KitchenShiftOperationSuccess(
            message: 'Shift deleted successfully!',
          ),
        );
        // Reload shifts
        add(const LoadKitchenShifts());
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(KitchenShiftError(error: error.toString(), errorType: errorType));
      },
    );
  }

  void _onFilterShiftsByEmployee(
    FilterShiftsByEmployee event,
    Emitter<KitchenShiftState> emit,
  ) {
    if (state is! KitchenShiftLoaded) return;

    final currentState = state as KitchenShiftLoaded;
    final filtered = _applyFilters(
      currentState.allShifts,
      employeeId: event.employeeId,
      startDate: currentState.startDate,
      endDate: currentState.endDate,
    );

    emit(
      currentState.copyWith(
        selectedEmployeeId: event.employeeId,
        filteredShifts: filtered,
      ),
    );
  }

  void _onFilterShiftsByDateRange(
    FilterShiftsByDateRange event,
    Emitter<KitchenShiftState> emit,
  ) {
    if (state is! KitchenShiftLoaded) return;

    final currentState = state as KitchenShiftLoaded;
    final filtered = _applyFilters(
      currentState.allShifts,
      employeeId: currentState.selectedEmployeeId,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    emit(
      currentState.copyWith(
        startDate: event.startDate,
        endDate: event.endDate,
        filteredShifts: filtered,
      ),
    );
  }

  Future<void> _onRefreshKitchenShifts(
    RefreshKitchenShifts event,
    Emitter<KitchenShiftState> emit,
  ) async {
    if (state is! KitchenShiftLoaded) {
      add(const LoadKitchenShifts());
      return;
    }

    final currentState = state as KitchenShiftLoaded;
    emit(KitchenShiftRefreshing(currentData: currentState.allShifts));
    final resolvedBranchId = await _resolveBranchId();

    if (resolvedBranchId.isEmpty) {
      emit(
        const KitchenShiftError(
          error: 'Branch ID not found. Please login again.',
          errorType: KitchenShiftErrorType.validation,
        ),
      );
      return;
    }

    final response = await _repository.getKitchenShifts(
      branchId: resolvedBranchId,
      startDate: currentState.startDate,
      endDate: currentState.endDate,
      employeeId: currentState.selectedEmployeeId,
    );

    await response.when(
      success: (shifts) async {
        if (shifts.isEmpty) {
          emit(
            KitchenShiftEmpty(
              employees: currentState.employees,
              startDate: currentState.startDate,
              endDate: currentState.endDate,
            ),
          );
          return;
        }

        final filtered = _applyFilters(
          shifts,
          employeeId: currentState.selectedEmployeeId,
          startDate: currentState.startDate,
          endDate: currentState.endDate,
        );

        final shiftsByEmployee = _groupShiftsByEmployee(shifts);
        final shiftsByDate = _groupShiftsByDate(shifts);

        emit(
          KitchenShiftLoaded(
            allShifts: shifts,
            filteredShifts: filtered,
            employees: currentState.employees,
            selectedEmployeeId: currentState.selectedEmployeeId,
            startDate: currentState.startDate,
            endDate: currentState.endDate,
            shiftsByEmployee: shiftsByEmployee,
            shiftsByDate: shiftsByDate,
          ),
        );
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(KitchenShiftError(error: error.toString(), errorType: errorType));
      },
    );
  }

  void _onClearShiftFilters(
    ClearShiftFilters event,
    Emitter<KitchenShiftState> emit,
  ) {
    if (state is! KitchenShiftLoaded) return;

    final currentState = state as KitchenShiftLoaded;
    emit(
      currentState.copyWith(
        selectedEmployeeId: null,
        startDate: null,
        endDate: null,
        filteredShifts: currentState.allShifts,
      ),
    );
  }

  List<KitchenShift> _applyFilters(
    List<KitchenShift> shifts, {
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var filtered = shifts;

    if (employeeId != null && employeeId.isNotEmpty) {
      filtered = filtered.where((s) => s.employeeId == employeeId).toList();
    }

    if (startDate != null) {
      filtered = filtered.where((s) {
        final shiftDate = _parseShiftDate(s.date);
        if (shiftDate == null) return false;
        return shiftDate.isAfter(startDate) ||
            shiftDate.isAtSameMomentAs(startDate);
      }).toList();
    }

    if (endDate != null) {
      filtered = filtered.where((s) {
        final shiftDate = _parseShiftDate(s.date);
        if (shiftDate == null) return false;
        return shiftDate.isBefore(endDate) ||
            shiftDate.isAtSameMomentAs(endDate);
      }).toList();
    }

    return filtered;
  }

  Future<String> _resolveBranchId() async {
    if (branchId.isNotEmpty) return branchId;

    branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    return branchId;
  }

  DateTime? _parseShiftDate(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;

    return DateTime.tryParse(normalized);
  }

  Map<String, List<KitchenShift>> _groupShiftsByEmployee(
    List<KitchenShift> shifts,
  ) {
    final grouped = <String, List<KitchenShift>>{};
    for (var shift in shifts) {
      if (!grouped.containsKey(shift.employeeId)) {
        grouped[shift.employeeId] = [];
      }
      grouped[shift.employeeId]!.add(shift);
    }
    return grouped;
  }

  Map<String, List<KitchenShift>> _groupShiftsByDate(
    List<KitchenShift> shifts,
  ) {
    final grouped = <String, List<KitchenShift>>{};
    for (var shift in shifts) {
      final dateKey = shift.date.split('T')[0];
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(shift);
    }
    return grouped;
  }

  KitchenShiftErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return KitchenShiftErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return KitchenShiftErrorType.timeout;
    }

    if (lowercaseError.contains('conflict')) {
      return KitchenShiftErrorType.conflict;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return KitchenShiftErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return KitchenShiftErrorType.validation;
    }

    return KitchenShiftErrorType.general;
  }
}
