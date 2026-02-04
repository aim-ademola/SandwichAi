import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

// ============================================================================
// EVENTS
// ============================================================================
abstract class ProcessingDashboardEvent {
  const ProcessingDashboardEvent();
}

class LoadProcessingDashboard extends ProcessingDashboardEvent {
  const LoadProcessingDashboard();
}

class RefreshProcessingDashboard extends ProcessingDashboardEvent {
  const RefreshProcessingDashboard();
}
