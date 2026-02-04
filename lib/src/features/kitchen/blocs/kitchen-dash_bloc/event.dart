import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/kitchen/data/model/kitchen_dash_model.dart';

abstract class KitchenDashboardEvent extends Equatable {
  const KitchenDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends KitchenDashboardEvent {
  const LoadDashboardData();
}

class RefreshDashboardData extends KitchenDashboardEvent {
  const RefreshDashboardData();
}

class FilterOrders extends KitchenDashboardEvent {
  final OrderFilter filter;

  const FilterOrders(this.filter);

  @override
  List<Object?> get props => [filter];
}

class StartOrderPreparation extends KitchenDashboardEvent {
  final String orderId;

  const StartOrderPreparation(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class MarkOrderAsReady extends KitchenDashboardEvent {
  final String orderId;

  const MarkOrderAsReady(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
