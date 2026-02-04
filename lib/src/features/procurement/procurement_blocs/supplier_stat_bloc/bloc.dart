import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/supplier_stat_repo.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_stat_bloc/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_stat_bloc/state.dart';

class SupplierStatsBloc extends Bloc<SupplierStatsEvent, SupplierStatsState> {
  final SupplierStatsRepositoryInterface _repository;

  SupplierStatsBloc({required SupplierStatsRepositoryInterface repository})
    : _repository = repository,
      super(const SupplierStatsInitial()) {
    on<LoadSupplierStats>(_onLoadSupplierStats);
    on<RefreshSupplierStats>(_onRefreshSupplierStats);
    on<ResetSupplierStats>(_onResetSupplierStats);
  }

  Future<void> _onLoadSupplierStats(
    LoadSupplierStats event,
    Emitter<SupplierStatsState> emit,
  ) async {
    try {
      emit(const SupplierStatsLoading());

      final response = await _repository.getSupplierStats();

      await response.when(
        success: (data) async {
          emit(SupplierStatsLoaded(stats: data));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            SupplierStatsError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const SupplierStatsError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: SupplierStatsErrorType.general,
        ),
      );
    }
  }

  Future<void> _onRefreshSupplierStats(
    RefreshSupplierStats event,
    Emitter<SupplierStatsState> emit,
  ) async {
    // Keep the current state but fetch fresh data
    try {
      final response = await _repository.getSupplierStats();

      await response.when(
        success: (data) async {
          emit(SupplierStatsLoaded(stats: data));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            SupplierStatsError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const SupplierStatsError(
          error: 'Failed to refresh supplier stats. Please try again.',
          errorType: SupplierStatsErrorType.general,
        ),
      );
    }
  }

  void _onResetSupplierStats(
    ResetSupplierStats event,
    Emitter<SupplierStatsState> emit,
  ) {
    emit(const SupplierStatsInitial());
  }

  SupplierStatsErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return SupplierStatsErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return SupplierStatsErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return SupplierStatsErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return SupplierStatsErrorType.validation;
    }

    return SupplierStatsErrorType.general;
  }
}
