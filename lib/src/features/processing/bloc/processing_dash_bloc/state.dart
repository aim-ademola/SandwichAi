// ============================================================================
// STATES
// ============================================================================
import 'package:sandwich_ai/src/features/processing/data/model/processing_dash_model.dart';

enum ProcessingDashboardErrorType {
  network,
  timeout,
  server,
  notFound,
  validation,
  general,
}

abstract class ProcessingDashboardState {
  const ProcessingDashboardState();
}

class ProcessingDashboardInitial extends ProcessingDashboardState {
  const ProcessingDashboardInitial();
}

class ProcessingDashboardLoading extends ProcessingDashboardState {
  const ProcessingDashboardLoading();
}

class ProcessingDashboardLoaded extends ProcessingDashboardState {
  final ProcessingDashboardData data;

  const ProcessingDashboardLoaded({required this.data});
}

class ProcessingDashboardRefreshing extends ProcessingDashboardState {
  final ProcessingDashboardData currentData;

  const ProcessingDashboardRefreshing({required this.currentData});
}

class ProcessingDashboardError extends ProcessingDashboardState {
  final String error;
  final ProcessingDashboardErrorType errorType;

  const ProcessingDashboardError({
    required this.error,
    required this.errorType,
  });
}
