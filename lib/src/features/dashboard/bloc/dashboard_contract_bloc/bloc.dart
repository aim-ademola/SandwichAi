import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/dashboard/bloc/dashboard_contract_bloc/event.dart';
import 'package:sandwich_ai/src/features/dashboard/bloc/dashboard_contract_bloc/state.dart';
import 'package:sandwich_ai/src/features/dashboard/data/repo/dashboard_contract_repo.dart';

class DashboardContractBloc extends Bloc<DashboardContractEvent, DashboardContractState> {
  final DashboardContractRepositoryInterface _repository;

  DashboardContractBloc({required DashboardContractRepositoryInterface repository})
    : _repository = repository,
      super(const DashboardContractInitial()) {
    on<LoadDashboardContract>(_onLoadDashboardContract);
    on<RefreshDashboardContract>(_onRefreshDashboardContract);
    on<ResetDashboardContract>(_onResetDashboardContract);
  }

  Future<void> _onLoadDashboardContract(
    LoadDashboardContract event,
    Emitter<DashboardContractState> emit,
  ) async {
    emit(const DashboardContractLoading());
    await _fetch(event, emit);
  }

  Future<void> _onRefreshDashboardContract(
    RefreshDashboardContract event,
    Emitter<DashboardContractState> emit,
  ) async {
    final currentState = state;
    if (currentState is DashboardContractLoaded) {
      emit(DashboardContractRefreshing(currentData: currentState.data));
    } else {
      emit(const DashboardContractLoading());
    }

    await _fetch(event, emit);
  }

  Future<void> _fetch(
    LoadDashboardContract event,
    Emitter<DashboardContractState> emit,
  ) async {
    final response = await _repository.getDashboard(event.request);
    response.when(
      success: (data) {
        if (data.isEmpty) {
          emit(DashboardContractEmpty(domain: data.domain));
          return;
        }
        emit(DashboardContractLoaded(data: data));
      },
      error: (error) => emit(DashboardContractError(message: error.message)),
    );
  }

  void _onResetDashboardContract(
    ResetDashboardContract event,
    Emitter<DashboardContractState> emit,
  ) {
    emit(const DashboardContractInitial());
  }
}
