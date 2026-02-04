import 'package:equatable/equatable.dart';

sealed class BranchStockEvent extends Equatable {
  const BranchStockEvent();

  @override
  List<Object?> get props => [];
}

class LoadBranchStock extends BranchStockEvent {
  final String? branchId;

  const LoadBranchStock({this.branchId});

  @override
  List<Object?> get props => [branchId];
}

class SelectCategory extends BranchStockEvent {
  final String category;

  const SelectCategory({required this.category});

  @override
  List<Object?> get props => [category];
}

class SearchItems extends BranchStockEvent {
  final String query;

  const SearchItems({required this.query});

  @override
  List<Object?> get props => [query];
}

class ToggleViewMode extends BranchStockEvent {
  const ToggleViewMode();
}

class RefreshBranchStock extends BranchStockEvent {
  final String? branchId;

  const RefreshBranchStock({this.branchId});

  @override
  List<Object?> get props => [branchId];
}

class ClearSearch extends BranchStockEvent {
  const ClearSearch();
}
