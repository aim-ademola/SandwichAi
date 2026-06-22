import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/dashboard/data/model/dashboard_contract_model.dart';

abstract class DashboardContractState extends Equatable {
  const DashboardContractState();

  @override
  List<Object?> get props => [];
}

class DashboardContractInitial extends DashboardContractState {
  const DashboardContractInitial();
}

class DashboardContractLoading extends DashboardContractState {
  const DashboardContractLoading();
}

class DashboardContractRefreshing extends DashboardContractState {
  final DashboardResponse currentData;

  const DashboardContractRefreshing({required this.currentData});

  @override
  List<Object?> get props => [currentData];
}

class DashboardContractLoaded extends DashboardContractState {
  final DashboardResponse data;

  const DashboardContractLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class DashboardContractEmpty extends DashboardContractState {
  final DashboardDomain domain;

  const DashboardContractEmpty({required this.domain});

  @override
  List<Object?> get props => [domain];
}

class DashboardContractError extends DashboardContractState {
  final String message;

  const DashboardContractError({required this.message});

  @override
  List<Object?> get props => [message];
}
