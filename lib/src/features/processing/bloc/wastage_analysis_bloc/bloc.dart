import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/processing/bloc/wastage_analysis_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/wastage_analysis_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/wasage_analysis_repo.dart';

import '../../../../core/config/prod_print.dart';

class WastageAnalysisBloc
    extends Bloc<WastageAnalysisEvent, WastageAnalysisState> {
  final WastageAnalysisRepositoryInterface _repository;
  String branchId = '';
  String organizationId = '';

  WastageAnalysisBloc({required WastageAnalysisRepositoryInterface repository})
    : _repository = repository,
      super(const WastageAnalysisInitial()) {
    _getIds();
    on<LoadWastageAnalysis>(_onLoadWastageAnalysis);
    on<RefreshWastageAnalysis>(_onRefreshWastageAnalysis);
    on<UpdateAnalysisPeriod>(_onUpdateAnalysisPeriod);
  }

  _getIds() async {
    branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    organizationId = await AuthCacheHelper.instance.getOrgId() ?? '';
  }

  Future<void> _onLoadWastageAnalysis(
    LoadWastageAnalysis event,
    Emitter<WastageAnalysisState> emit,
  ) async {
    try {
      emit(const WastageAnalysisLoading());

      // Ensure we have the IDs
      if (branchId.isEmpty || organizationId.isEmpty) {
        await _getIds();
      }

      final response = await _repository.analyzeWastage(
        organizationId: organizationId,
        branchId: branchId,
        daysBack: event.daysBack,
      );

      await response.when(
        success: (analysis) async {
          if (analysis.totalLogs == 0) {
            emit(WastageAnalysisEmpty(daysBack: event.daysBack));
            return;
          }

          emit(
            WastageAnalysisLoaded(analysis: analysis, daysBack: event.daysBack),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            WastageAnalysisError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      AppLogger.log('Bloc Error: $e');
      emit(
        const WastageAnalysisError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: WastageAnalysisErrorType.general,
        ),
      );
    }
  }

  Future<void> _onRefreshWastageAnalysis(
    RefreshWastageAnalysis event,
    Emitter<WastageAnalysisState> emit,
  ) async {
    if (state is! WastageAnalysisLoaded) {
      add(LoadWastageAnalysis(daysBack: event.daysBack));
      return;
    }

    final currentState = state as WastageAnalysisLoaded;
    emit(WastageAnalysisRefreshing(currentData: currentState.analysis));

    final response = await _repository.analyzeWastage(
      organizationId: organizationId,
      branchId: branchId,
      daysBack: event.daysBack,
    );

    await response.when(
      success: (analysis) async {
        if (analysis.totalLogs == 0) {
          emit(WastageAnalysisEmpty(daysBack: event.daysBack));
          return;
        }

        emit(
          WastageAnalysisLoaded(analysis: analysis, daysBack: event.daysBack),
        );
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(
          WastageAnalysisError(error: error.toString(), errorType: errorType),
        );
      },
    );
  }

  Future<void> _onUpdateAnalysisPeriod(
    UpdateAnalysisPeriod event,
    Emitter<WastageAnalysisState> emit,
  ) async {
    add(LoadWastageAnalysis(daysBack: event.daysBack));
  }

  WastageAnalysisErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return WastageAnalysisErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return WastageAnalysisErrorType.timeout;
    }

    if (lowercaseError.contains('not found') ||
        lowercaseError.contains('404')) {
      return WastageAnalysisErrorType.notFound;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return WastageAnalysisErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return WastageAnalysisErrorType.validation;
    }

    return WastageAnalysisErrorType.general;
  }
}
