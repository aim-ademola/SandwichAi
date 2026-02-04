// bloc/kitchen_orders_bloc/event.dart

import 'package:equatable/equatable.dart';

abstract class KitchenOrdersEvent extends Equatable {
  const KitchenOrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadKitchenOrders extends KitchenOrdersEvent {
  const LoadKitchenOrders();
}

class RefreshKitchenOrders extends KitchenOrdersEvent {
  const RefreshKitchenOrders();
}

class FilterKitchenOrdersByStatus extends KitchenOrdersEvent {
  final String? status;

  const FilterKitchenOrdersByStatus({this.status});

  @override
  List<Object?> get props => [status];
}

class SearchKitchenOrders extends KitchenOrdersEvent {
  final String query;

  const SearchKitchenOrders({required this.query});

  @override
  List<Object> get props => [query];
}

class FilterKitchenOrdersByDateRange extends KitchenOrdersEvent {
  final String? startDate;
  final String? endDate;

  const FilterKitchenOrdersByDateRange({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
