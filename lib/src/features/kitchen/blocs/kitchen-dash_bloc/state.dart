import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/kitchen/data/model/kitchen_dash_model.dart';

enum DashboardErrorType {
  network,
  timeout,
  notFound,
  server,
  validation,
  general,
}

abstract class KitchenDashboardState extends Equatable {
  const KitchenDashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends KitchenDashboardState {
  const DashboardInitial();
}

class DashboardLoading extends KitchenDashboardState {
  const DashboardLoading();
}

class DashboardRefreshing extends KitchenDashboardState {
  final KitchenDashboardData currentData;

  const DashboardRefreshing({required this.currentData});

  @override
  List<Object?> get props => [currentData];
}

class DashboardLoaded extends KitchenDashboardState {
  final KitchenDashboardData dashboardData;
  final List<KitchenOrder> filteredOrders;
  final OrderFilter currentFilter;

  const DashboardLoaded({
    required this.dashboardData,
    required this.filteredOrders,
    this.currentFilter = OrderFilter.all,
  });

  @override
  List<Object?> get props => [dashboardData, filteredOrders, currentFilter];

  DashboardLoaded copyWith({
    KitchenDashboardData? dashboardData,
    List<KitchenOrder>? filteredOrders,
    OrderFilter? currentFilter,
  }) {
    return DashboardLoaded(
      dashboardData: dashboardData ?? this.dashboardData,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class DashboardEmpty extends KitchenDashboardState {
  const DashboardEmpty();
}

class DashboardError extends KitchenDashboardState {
  final String error;
  final DashboardErrorType errorType;

  const DashboardError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}

class OrderActionInProgress extends KitchenDashboardState {
  final String orderId;
  final String action;

  const OrderActionInProgress({required this.orderId, required this.action});

  @override
  List<Object?> get props => [orderId, action];
}

class OrderActionSuccess extends KitchenDashboardState {
  final String orderId;
  final String message;

  const OrderActionSuccess({required this.orderId, required this.message});

  @override
  List<Object?> get props => [orderId, message];
}

class OrderActionError extends KitchenDashboardState {
  final String orderId;
  final String error;

  const OrderActionError({required this.orderId, required this.error});

  @override
  List<Object?> get props => [orderId, error];
}
