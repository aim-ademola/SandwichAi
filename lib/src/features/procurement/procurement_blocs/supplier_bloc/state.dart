// supplier_state.dart
enum SupplierErrorType { network, timeout, server, validation, general }

abstract class SupplierState {
  const SupplierState();
}

class SupplierInitial extends SupplierState {
  const SupplierInitial();
}

class SupplierLoading extends SupplierState {
  const SupplierLoading();
}

class SupplierRefreshing extends SupplierState {
  final List<dynamic> currentSuppliers;

  const SupplierRefreshing({required this.currentSuppliers});
}

class SupplierListLoaded extends SupplierState {
  final List<dynamic> suppliers;
  final String? currentFilter;
  final String? currentSearch;

  const SupplierListLoaded({
    required this.suppliers,
    this.currentFilter,
    this.currentSearch,
  });
}

class SupplierProductsLoaded extends SupplierState {
  final List<dynamic> products;
  final String supplierId;

  const SupplierProductsLoaded({
    required this.products,
    required this.supplierId,
  });
}

class SupplierEmpty extends SupplierState {
  const SupplierEmpty();
}

class SupplierError extends SupplierState {
  final String error;
  final SupplierErrorType errorType;

  const SupplierError({required this.error, required this.errorType});
}
