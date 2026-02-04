import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/stock_movement_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/stock_movement.dart';

/// Error types for better error handling
enum StockMovementErrorType { network, timeout, server, validation, general }

abstract class StockMovementState extends Equatable {
  const StockMovementState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class StockMovementInitial extends StockMovementState {
  const StockMovementInitial();
}

/// Loading state
class StockMovementLoading extends StockMovementState {
  const StockMovementLoading();
}

/// Loaded state
class StockMovementLoaded extends StockMovementState {
  final StockMovementResponse response;
  final List<StockMovementItem> filteredItems;
  final StockMovementQuery currentQuery;
  final String searchQuery;
  final bool isLoadingMore;

  const StockMovementLoaded({
    required this.response,
    required this.filteredItems,
    required this.currentQuery,
    this.searchQuery = '',
    this.isLoadingMore = false,
  });

  StockMovementLoaded copyWith({
    StockMovementResponse? response,
    List<StockMovementItem>? filteredItems,
    StockMovementQuery? currentQuery,
    String? searchQuery,
    bool? isLoadingMore,
  }) {
    return StockMovementLoaded(
      response: response ?? this.response,
      filteredItems: filteredItems ?? this.filteredItems,
      currentQuery: currentQuery ?? this.currentQuery,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  // Computed properties
  int get totalReceived => response.inflowMovements.fold<int>(
    0,
    (sum, item) => sum + (int.tryParse(item.inflow ?? '0') ?? 0),
  );

  int get totalConsumed => response.outflowMovements.fold<int>(
    0,
    (sum, item) => sum + (int.tryParse(item.outflow ?? '0') ?? 0),
  );

  bool get hasMore => response.pagination.hasNextPage;

  @override
  List<Object?> get props => [
    response,
    filteredItems,
    currentQuery,
    searchQuery,
    isLoadingMore,
  ];
}

/// Refreshing state
class StockMovementRefreshing extends StockMovementState {
  final StockMovementResponse currentData;

  const StockMovementRefreshing({required this.currentData});

  @override
  List<Object?> get props => [currentData];
}

/// Error state
class StockMovementError extends StockMovementState {
  final String error;
  final StockMovementErrorType errorType;

  const StockMovementError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}
