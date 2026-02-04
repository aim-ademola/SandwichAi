import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_model.dart';

enum OrdersErrorType { network, timeout, server, general }

abstract class OrdersListState extends Equatable {
  const OrdersListState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersListState {
  const OrdersInitial();
}

class OrdersLoading extends OrdersListState {
  const OrdersLoading();
}

class OrdersLoaded extends OrdersListState {
  final List<PurchaseOrder> orders;
  final int total;
  final int currentPage;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final String? activeStatus;
  final String? activePriority;
  final String? activeCategory;
  final String? searchQuery;

  const OrdersLoaded({
    required this.orders,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.activeStatus,
    this.activePriority,
    this.activeCategory,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [
    orders,
    total,
    currentPage,
    totalPages,
    hasNextPage,
    hasPreviousPage,
    activeStatus,
    activePriority,
    activeCategory,
    searchQuery,
  ];

  OrdersLoaded copyWith({
    List<PurchaseOrder>? orders,
    int? total,
    int? currentPage,
    int? totalPages,
    bool? hasNextPage,
    bool? hasPreviousPage,
    String? activeStatus,
    String? activePriority,
    String? activeCategory,
    String? searchQuery,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      activeStatus: activeStatus ?? this.activeStatus,
      activePriority: activePriority ?? this.activePriority,
      activeCategory: activeCategory ?? this.activeCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class OrdersLoadingMore extends OrdersListState {
  final List<PurchaseOrder> currentOrders;

  const OrdersLoadingMore(this.currentOrders);

  @override
  List<Object?> get props => [currentOrders];
}

class OrdersError extends OrdersListState {
  final String error;
  final OrdersErrorType errorType;

  const OrdersError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}

class OrdersEmpty extends OrdersListState {
  final String message;

  const OrdersEmpty({this.message = 'No orders found'});

  @override
  List<Object?> get props => [message];
}
