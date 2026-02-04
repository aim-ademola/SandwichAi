// bloc/kitchen_orders_bloc/state.dart

import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/pos/data/model/oder_status_model.dart';

enum KitchenOrdersErrorType {
  network,
  timeout,
  notFound,
  server,
  validation,
  general,
}

abstract class KitchenOrdersState extends Equatable {
  const KitchenOrdersState();

  @override
  List<Object?> get props => [];
}

class KitchenOrdersInitial extends KitchenOrdersState {
  const KitchenOrdersInitial();
}

class KitchenOrdersLoading extends KitchenOrdersState {
  const KitchenOrdersLoading();
}

class KitchenOrdersLoaded extends KitchenOrdersState {
  final List<KitchenOrder> orders;
  final List<KitchenOrder> filteredOrders;
  final String? selectedStatus;
  final String? searchQuery;
  final String? startDate;
  final String? endDate;

  const KitchenOrdersLoaded({
    required this.orders,
    required this.filteredOrders,
    this.selectedStatus,
    this.searchQuery,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [
    orders,
    filteredOrders,
    selectedStatus,
    searchQuery,
    startDate,
    endDate,
  ];

  KitchenOrdersLoaded copyWith({
    List<KitchenOrder>? orders,
    List<KitchenOrder>? filteredOrders,
    String? selectedStatus,
    String? searchQuery,
    String? startDate,
    String? endDate,
  }) {
    return KitchenOrdersLoaded(
      orders: orders ?? this.orders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class KitchenOrdersRefreshing extends KitchenOrdersState {
  final List<KitchenOrder> currentData;

  const KitchenOrdersRefreshing({required this.currentData});

  @override
  List<Object> get props => [currentData];
}

class KitchenOrdersEmpty extends KitchenOrdersState {
  const KitchenOrdersEmpty();
}

class KitchenOrdersError extends KitchenOrdersState {
  final String error;
  final KitchenOrdersErrorType errorType;

  const KitchenOrdersError({required this.error, required this.errorType});

  @override
  List<Object> get props => [error, errorType];
}
