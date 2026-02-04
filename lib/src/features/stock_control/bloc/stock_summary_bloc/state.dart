import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_summary_model.dart';

enum BranchStockSummaryErrorType {
  network,
  timeout,
  server,
  validation,
  general,
}

abstract class BranchStockSummaryState extends Equatable {
  const BranchStockSummaryState();

  @override
  List<Object?> get props => [];
}

class BranchStockSummaryInitial extends BranchStockSummaryState {
  const BranchStockSummaryInitial();
}

class BranchStockSummaryLoading extends BranchStockSummaryState {
  const BranchStockSummaryLoading();
}

class BranchStockSummaryLoaded extends BranchStockSummaryState {
  final BranchStockSummaryResponse response;
  final List<InventoryItem> filteredItems;
  final String searchQuery;

  const BranchStockSummaryLoaded({
    required this.response,
    required this.filteredItems,
    this.searchQuery = '',
  });

  BranchStockSummaryLoaded copyWith({
    BranchStockSummaryResponse? response,
    List<InventoryItem>? filteredItems,
    String? searchQuery,
  }) {
    return BranchStockSummaryLoaded(
      response: response ?? this.response,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [response, filteredItems, searchQuery];
}

class BranchStockSummaryRefreshing extends BranchStockSummaryState {
  final BranchStockSummaryResponse currentData;

  const BranchStockSummaryRefreshing({required this.currentData});

  @override
  List<Object?> get props => [currentData];
}

class BranchStockSummaryError extends BranchStockSummaryState {
  final String error;
  final BranchStockSummaryErrorType errorType;

  const BranchStockSummaryError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}

class BranchStockSummaryEmpty extends BranchStockSummaryState {
  const BranchStockSummaryEmpty();

  @override
  List<Object?> get props => [];
}
