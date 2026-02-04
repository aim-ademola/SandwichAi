abstract class SupplierEvent {}

class LoadSuppliers extends SupplierEvent {
  final String? status;
  final String? supplierType;
  final String? search;

  LoadSuppliers({this.status, this.supplierType, this.search});
}

class RefreshSuppliers extends SupplierEvent {
  final String? status;
  final String? supplierType;
  final String? search;

  RefreshSuppliers({this.status, this.supplierType, this.search});
}

class FilterSuppliers extends SupplierEvent {
  final String? status;
  final String? supplierType;
  final bool? isVerified;

  FilterSuppliers({this.status, this.supplierType, this.isVerified});
}

class SearchSuppliers extends SupplierEvent {
  final String query;

  SearchSuppliers(this.query);
}

class LoadSupplierProducts extends SupplierEvent {
  final String supplierId;
  final String? category;
  final String? status;

  LoadSupplierProducts({required this.supplierId, this.category, this.status});
}
