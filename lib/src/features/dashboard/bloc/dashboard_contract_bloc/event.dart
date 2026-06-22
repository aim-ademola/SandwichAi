import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/dashboard/data/model/dashboard_contract_model.dart';

abstract class DashboardContractEvent extends Equatable {
  const DashboardContractEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardContract extends DashboardContractEvent {
  final DashboardFilterRequest request;

  const LoadDashboardContract({required this.request});

  @override
  List<Object?> get props => [request];
}

class RefreshDashboardContract extends LoadDashboardContract {
  const RefreshDashboardContract({required super.request});
}

class ResetDashboardContract extends DashboardContractEvent {
  const ResetDashboardContract();
}
