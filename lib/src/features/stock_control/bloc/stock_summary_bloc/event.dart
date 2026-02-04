import 'package:equatable/equatable.dart';

abstract class BranchStockSummaryEvent extends Equatable {
  const BranchStockSummaryEvent();

  @override
  List<Object?> get props => [];
}

class LoadBranchStockSummary extends BranchStockSummaryEvent {
  final String branchId;

  const LoadBranchStockSummary({required this.branchId});

  @override
  List<Object?> get props => [branchId];
}

class RefreshBranchStockSummary extends BranchStockSummaryEvent {
  const RefreshBranchStockSummary();
}

class SearchStockCategories extends BranchStockSummaryEvent {
  final String query;

  const SearchStockCategories({required this.query});

  @override
  List<Object?> get props => [query];
}

class ClearStockSearch extends BranchStockSummaryEvent {
  const ClearStockSearch();
}
