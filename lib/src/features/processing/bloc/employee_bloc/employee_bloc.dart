// bloc/employee_bloc/event.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/processing/data/model/product_intake_model.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/employee_repo.dart';

abstract class EmployeeEvent {}

class LoadEmployeesByDepartment extends EmployeeEvent {
  final String branchId;
  final String department;
  final String? role;
  final String? status;
  final String? search;

  LoadEmployeesByDepartment({
    required this.branchId,
    required this.department,
    this.role,
    this.status,
    this.search,
  });
}

class SearchEmployees extends EmployeeEvent {
  final String query;

  SearchEmployees({required this.query});
}

// bloc/employee_bloc/state.dart

abstract class EmployeeState {
  const EmployeeState();
}

class EmployeeInitial extends EmployeeState {
  const EmployeeInitial();
}

class EmployeeLoading extends EmployeeState {
  const EmployeeLoading();
}

class EmployeeLoaded extends EmployeeState {
  final List<Employee> employees;

  const EmployeeLoaded({required this.employees});
}

class EmployeeError extends EmployeeState {
  final String error;

  const EmployeeError({required this.error});
}

// bloc/employee_bloc/bloc.dart

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final EmployeeRepositoryInterface _repository;

  EmployeeBloc({required EmployeeRepositoryInterface repository})
    : _repository = repository,
      super(const EmployeeInitial()) {
    on<LoadEmployeesByDepartment>(_onLoadEmployeesByDepartment);
    on<SearchEmployees>(_onSearchEmployees);
  }

  Future<void> _onLoadEmployeesByDepartment(
    LoadEmployeesByDepartment event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(const EmployeeLoading());

    final response = await _repository.getEmployeesByDepartment(
      branchId: event.branchId,
      department: event.department,
      role: event.role,
      status: event.status,
      search: event.search,
    );

    response.when(
      success: (employeesResponse) =>
          emit(EmployeeLoaded(employees: employeesResponse.data)),
      error: (error) => emit(EmployeeError(error: error.message)),
    );
  }

  Future<void> _onSearchEmployees(
    SearchEmployees event,
    Emitter<EmployeeState> emit,
  ) async {
    // This would trigger a new load with search parameter
    // For now, we'll handle search in the UI by filtering loaded employees
  }
}
