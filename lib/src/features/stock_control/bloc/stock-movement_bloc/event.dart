// lib/src/features/stock_control/bloc/stock_movement_bloc/event.dart

import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/stock_movement.dart';

abstract class StockMovementEvent extends Equatable {
  const StockMovementEvent();

  @override
  List<Object?> get props => [];
}

/// Load stock movements with optional filters
class LoadStockMovements extends StockMovementEvent {
  final StockMovementQuery query;

  const LoadStockMovements({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Refresh current stock movements
class RefreshStockMovements extends StockMovementEvent {
  const RefreshStockMovements();
}

/// Load next page of stock movements
class LoadMoreStockMovements extends StockMovementEvent {
  const LoadMoreStockMovements();
}

/// Filter by movement type
class FilterByMovementType extends StockMovementEvent {
  final String? movementType; // null means show all

  const FilterByMovementType({this.movementType});

  @override
  List<Object?> get props => [movementType];
}

/// Filter by date range
class FilterByDateRange extends StockMovementEvent {
  final String? startDate;
  final String? endDate;

  const FilterByDateRange({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Search stock movements
class SearchStockMovements extends StockMovementEvent {
  final String query;

  const SearchStockMovements({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Clear all filters
class ClearMovementFilters extends StockMovementEvent {
  const ClearMovementFilters();
}
