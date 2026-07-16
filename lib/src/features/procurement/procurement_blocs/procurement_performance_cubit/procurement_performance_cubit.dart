import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_performance_repo.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_performance_cubit/procurement_performance_state.dart';

class ProcurementPerformanceCubit extends Cubit<ProcurementPerformanceState> {
  final ProcurementPerformanceRepositoryInterface _repository;

  ProcurementPerformanceCubit({
    required ProcurementPerformanceRepositoryInterface repository,
  }) : _repository = repository,
       super(const ProcurementPerformanceState());

  Future<void> loadDashboardPerformance({String? branchId}) async {
    await Future.wait([
      loadPerformance(branchId: branchId),
      loadRankings(branchId: branchId),
    ]);
  }

  Future<void> loadPerformance({String? branchId}) async {
    emit(
      state.copyWith(
        performanceStatus: ProcurementPerformanceStatus.loading,
        clearPerformanceError: true,
      ),
    );

    final response = await _repository.getProcurementPerformance(
      branchId: branchId,
    );
    response.when(
      success: (data) {
        final isEmpty =
            data.totalOrders == 0 &&
            data.completedOrders == 0 &&
            data.totalSpend == 0 &&
            data.averageDeliveryDays == 0 &&
            data.onTimeDeliveryRate == 0 &&
            data.qualityPassRate == 0;
        emit(
          state.copyWith(
            performanceStatus: isEmpty
                ? ProcurementPerformanceStatus.empty
                : ProcurementPerformanceStatus.loaded,
            performance: data,
          ),
        );
      },
      error: (error) => emit(
        state.copyWith(
          performanceStatus: ProcurementPerformanceStatus.error,
          performanceError: error.message,
        ),
      ),
    );
  }

  Future<void> loadRankings({String? branchId}) async {
    emit(
      state.copyWith(
        rankingsStatus: ProcurementPerformanceStatus.loading,
        clearRankingsError: true,
      ),
    );

    final response = await _repository.getProcurementPerformanceRankings(
      branchId: branchId,
    );
    response.when(
      success: (data) => emit(
        state.copyWith(
          rankingsStatus: data.rankings.isEmpty
              ? ProcurementPerformanceStatus.empty
              : ProcurementPerformanceStatus.loaded,
          rankings: data,
        ),
      ),
      error: (error) => emit(
        state.copyWith(
          rankingsStatus: ProcurementPerformanceStatus.error,
          rankingsError: error.message,
        ),
      ),
    );
  }
}
