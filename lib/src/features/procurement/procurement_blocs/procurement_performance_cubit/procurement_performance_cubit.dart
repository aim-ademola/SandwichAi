import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';
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
          rankingsError: _backendVisibleError(error),
        ),
      ),
    );
  }

  String _backendVisibleError(NetworkException error) {
    final message = error.message.trim();
    if (!_isGenericServerError(message) || error.data == null) {
      return message.isEmpty ? 'Failed to load supplier rankings.' : message;
    }

    final backendDetails = _flattenBackendDetails(error.data)
        .where((detail) => detail.trim().isNotEmpty)
        .where((detail) => !_isGenericServerError(detail))
        .toSet()
        .join('\n');

    if (backendDetails.isEmpty) return message;
    return backendDetails;
  }

  bool _isGenericServerError(String message) {
    final normalized = message.trim().toLowerCase();
    return normalized == 'internal server error' ||
        normalized == 'internal server error. please try again later.';
  }

  Iterable<String> _flattenBackendDetails(dynamic data) sync* {
    if (data == null) return;
    if (data is String) {
      yield data;
      return;
    }
    if (data is List) {
      for (final item in data) {
        yield* _flattenBackendDetails(item);
      }
      return;
    }
    if (data is Map) {
      final map = data.cast<dynamic, dynamic>();
      for (final key in const [
        'message',
        'error',
        'detail',
        'details',
        'reason',
        'errorMessage',
        'description',
      ]) {
        yield* _flattenBackendDetails(map[key]);
      }
    }
  }
}
