import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_dashboard_state_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_dashboard_state_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_dashboradd_repo.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepositoryInterface _repository;
  String branchId = '';

  DashboardBloc({required DashboardRepositoryInterface repository})
    : _repository = repository,
      super(const DashboardInitial()) {
    _initializeIds();

    on<LoadDashboardSummary>(_onLoadDashboardSummary);
    on<RefreshDashboardSummary>(_onRefreshDashboardSummary);
  }

  void _initializeIds() async {
    branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
  }

  Future<void> _onLoadDashboardSummary(
    LoadDashboardSummary event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      emit(const DashboardLoading());

      // Ensure branch ID is loaded
      if (branchId.isEmpty) {
        branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
      }

      // Validate required fields
      if (branchId.isEmpty) {
        emit(
          const DashboardError(
            error: 'Branch ID not found. Please login again.',
          ),
        );
        return;
      }

      final response = await _repository.getDashboardSummary(
        branchId: branchId,
        date: event.date,
      );

      await response.when(
        success: (summary) async {
          emit(DashboardLoaded(summary: summary));
        },
        error: (error) async {
          emit(DashboardError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        DashboardError(error: 'An unexpected error occurred: ${e.toString()}'),
      );
    }
  }

  Future<void> _onRefreshDashboardSummary(
    RefreshDashboardSummary event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      // Show refreshing state with current data if available
      if (state is DashboardLoaded) {
        emit(
          DashboardRefreshing(
            currentSummary: (state as DashboardLoaded).summary,
          ),
        );
      } else {
        emit(const DashboardLoading());
      }

      // Ensure branch ID is loaded
      if (branchId.isEmpty) {
        branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
      }

      // Validate required fields
      if (branchId.isEmpty) {
        emit(
          const DashboardError(
            error: 'Branch ID not found. Please login again.',
          ),
        );
        return;
      }

      final response = await _repository.getDashboardSummary(
        branchId: branchId,
        date: event.date,
      );

      await response.when(
        success: (summary) async {
          emit(DashboardLoaded(summary: summary));
        },
        error: (error) async {
          emit(DashboardError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        DashboardError(error: 'An unexpected error occurred: ${e.toString()}'),
      );
    }
  }
}
