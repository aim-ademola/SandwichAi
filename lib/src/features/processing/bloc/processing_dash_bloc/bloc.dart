// ============================================================================
// BLOC
// ============================================================================
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_dash_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_dash_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/processing_dashboard_repo.dart';

class ProcessingDashboardBloc
    extends Bloc<ProcessingDashboardEvent, ProcessingDashboardState> {
  final ProcessingDashboardRepositoryInterface _repository;

  ProcessingDashboardBloc({
    required ProcessingDashboardRepositoryInterface repository,
  }) : _repository = repository,
       super(const ProcessingDashboardInitial()) {
    getBranchid();
    on<LoadProcessingDashboard>(_onLoadProcessingDashboard);
    on<RefreshProcessingDashboard>(_onRefreshProcessingDashboard);
  }

  void getBranchid() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  String branchId = '';

  /// Load processing dashboard
  Future<void> _onLoadProcessingDashboard(
    LoadProcessingDashboard event,
    Emitter<ProcessingDashboardState> emit,
  ) async {
    try {
      emit(const ProcessingDashboardLoading());

      final response = await _repository.getProcessingDashboard(branchId);

      await response.when(
        success: (data) async {
          emit(ProcessingDashboardLoaded(data: data));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            ProcessingDashboardError(
              error: error.toString(),
              errorType: errorType,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        const ProcessingDashboardError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: ProcessingDashboardErrorType.general,
        ),
      );
    }
  }

  /// Refresh processing dashboard
  Future<void> _onRefreshProcessingDashboard(
    RefreshProcessingDashboard event,
    Emitter<ProcessingDashboardState> emit,
  ) async {
    if (state is! ProcessingDashboardLoaded) {
      add(LoadProcessingDashboard());
      return;
    }

    final currentState = state as ProcessingDashboardLoaded;
    emit(ProcessingDashboardRefreshing(currentData: currentState.data));

    final response = await _repository.getProcessingDashboard(branchId);

    await response.when(
      success: (data) async {
        emit(ProcessingDashboardLoaded(data: data));
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(
          ProcessingDashboardError(
            error: error.toString(),
            errorType: errorType,
          ),
        );
      },
    );
  }

  /// Determine error type from error message
  ProcessingDashboardErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return ProcessingDashboardErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return ProcessingDashboardErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return ProcessingDashboardErrorType.server;
    }

    if (lowercaseError.contains('not found') ||
        lowercaseError.contains('404')) {
      return ProcessingDashboardErrorType.notFound;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return ProcessingDashboardErrorType.validation;
    }

    return ProcessingDashboardErrorType.general;
  }
}
