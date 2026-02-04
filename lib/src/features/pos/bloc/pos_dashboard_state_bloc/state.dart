import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/pos/data/model/pos_dashboard_summary.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardSummaryModel summary;

  const DashboardLoaded({required this.summary});

  @override
  List<Object?> get props => [summary];
}

class DashboardError extends DashboardState {
  final String error;

  const DashboardError({required this.error});

  @override
  List<Object?> get props => [error];
}

class DashboardRefreshing extends DashboardState {
  final DashboardSummaryModel currentSummary;

  const DashboardRefreshing({required this.currentSummary});

  @override
  List<Object?> get props => [currentSummary];
}
