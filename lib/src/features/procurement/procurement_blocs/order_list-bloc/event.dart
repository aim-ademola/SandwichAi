import 'package:equatable/equatable.dart';

abstract class OrdersListEvent extends Equatable {
  const OrdersListEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrdersListEvent {
  final String? status;
  final String? deliveryStatus;
  final String? paymentStatus;
  final String? supplierId;

  final String? priority;
  final String? primaryCategory;
  final String? search;
  final String? orderDateFrom;
  final String? orderDateTo;
  final String? deliveryDateFrom;
  final String? deliveryDateTo;
  final double? minAmount;
  final double? maxAmount;
  final int page;
  final int limit;
  final String sortBy;
  final String sortOrder;

  const LoadOrders({
    this.status,
    this.deliveryStatus,
    this.paymentStatus,
    this.supplierId,

    this.priority,
    this.primaryCategory,
    this.search,
    this.orderDateFrom,
    this.orderDateTo,
    this.deliveryDateFrom,
    this.deliveryDateTo,
    this.minAmount,
    this.maxAmount,
    this.page = 1,
    this.limit = 10,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });

  @override
  List<Object?> get props => [
    status,
    deliveryStatus,
    paymentStatus,
    supplierId,

    priority,
    primaryCategory,
    search,
    orderDateFrom,
    orderDateTo,
    deliveryDateFrom,
    deliveryDateTo,
    minAmount,
    maxAmount,
    page,
    limit,
    sortBy,
    sortOrder,
  ];
}

class RefreshOrders extends OrdersListEvent {
  const RefreshOrders();
}

class LoadMoreOrders extends OrdersListEvent {
  const LoadMoreOrders();
}

class FilterOrders extends OrdersListEvent {
  final String? status;
  final String? priority;
  final String? primaryCategory;

  const FilterOrders({this.status, this.priority, this.primaryCategory});

  @override
  List<Object?> get props => [status, priority, primaryCategory];
}

class SearchOrders extends OrdersListEvent {
  final String query;

  const SearchOrders(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearFilters extends OrdersListEvent {
  const ClearFilters();
}
