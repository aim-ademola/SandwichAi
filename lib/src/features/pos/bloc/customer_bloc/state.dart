import 'package:sandwich_ai/src/features/pos/data/model/customer_model.dart';

abstract class CustomerState {
  const CustomerState();
}

// Initial state
class CustomerInitial extends CustomerState {
  const CustomerInitial();
}

// List states
class CustomersLoading extends CustomerState {
  const CustomersLoading();
}

class CustomersLoaded extends CustomerState {
  final List<CustomerModel> customers;
  final int currentPage;
  final int totalPages;
  final int total;
  final bool hasMore;

  const CustomersLoaded({
    required this.customers,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.hasMore,
  });
}

class CustomersLoadingMore extends CustomerState {
  final List<CustomerModel> currentCustomers;

  const CustomersLoadingMore({required this.currentCustomers});
}

class CustomersError extends CustomerState {
  final String error;

  const CustomersError({required this.error});
}

class CustomersRefreshing extends CustomerState {
  final List<CustomerModel> currentCustomers;

  const CustomersRefreshing({required this.currentCustomers});
}

// Single customer states
class CustomerDetailLoading extends CustomerState {
  const CustomerDetailLoading();
}

class CustomerDetailLoaded extends CustomerState {
  final CustomerModel customer;

  const CustomerDetailLoaded({required this.customer});
}

class CustomerDetailError extends CustomerState {
  final String error;

  const CustomerDetailError({required this.error});
}

// Action states
class CustomerActionLoading extends CustomerState {
  const CustomerActionLoading();
}

class CustomerCreated extends CustomerState {
  final CustomerModel customer;

  const CustomerCreated({required this.customer});
}

class CustomerUpdated extends CustomerState {
  final CustomerModel customer;

  const CustomerUpdated({required this.customer});
}

class CustomerDeleted extends CustomerState {
  const CustomerDeleted();
}

class CustomerActionError extends CustomerState {
  final String error;

  const CustomerActionError({required this.error});
}
