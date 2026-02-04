import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardSummary extends DashboardEvent {
  final String? date;

  const LoadDashboardSummary({this.date});

  @override
  List<Object?> get props => [date];
}

class RefreshDashboardSummary extends DashboardEvent {
  final String? date;

  const RefreshDashboardSummary({this.date});

  @override
  List<Object?> get props => [date];
}
