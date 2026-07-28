import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';

import 'package:sandwich_ai/src/features/stock_control/bloc/stock-movement_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock-movement_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/stock_movement_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/stock_movement.dart';

class StockMovementBloc extends Bloc<StockMovementEvent, StockMovementState> {
  final StockMovementRepositoryInterface _repository;
  String branchId = '';

  StockMovementBloc({required StockMovementRepositoryInterface repository})
    : _repository = repository,
      super(const StockMovementInitial()) {
    _getBranchId();
    on<LoadStockMovements>(_onLoadStockMovements);
    on<RefreshStockMovements>(_onRefreshStockMovements);
    on<LoadMoreStockMovements>(_onLoadMoreStockMovements);
    on<FilterByMovementType>(_onFilterByMovementType);
    on<FilterByDateRange>(_onFilterByDateRange);
    on<SearchStockMovements>(_onSearchStockMovements);
    on<ClearMovementFilters>(_onClearMovementFilters);
  }

  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  /// Load stock movements
  Future<void> _onLoadStockMovements(
    LoadStockMovements event,
    Emitter<StockMovementState> emit,
  ) async {
    try {
      emit(const StockMovementLoading());

      final response = await _repository.getStockMovements(event.query);

      await response.when(
        success: (data) async {
          emit(
            StockMovementLoaded(
              response: data,
              filteredItems: _applyFilters(
                data.data,
                movementType: event.query.movementType,
                searchQuery: '',
              ),
              currentQuery: event.query,
              searchQuery: '',
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            StockMovementError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const StockMovementError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: StockMovementErrorType.general,
        ),
      );
    }
  }

  /// Refresh stock movements
  Future<void> _onRefreshStockMovements(
    RefreshStockMovements event,
    Emitter<StockMovementState> emit,
  ) async {
    if (state is! StockMovementLoaded) {
      add(LoadStockMovements(query: StockMovementQuery(branchId: branchId)));
      return;
    }

    final currentState = state as StockMovementLoaded;
    emit(StockMovementRefreshing(currentData: currentState.response));

    final response = await _repository.getStockMovements(
      currentState.currentQuery,
    );

    await response.when(
      success: (data) async {
        final filteredItems = _applyFilters(
          data.data,
          movementType: currentState.currentQuery.movementType,
          searchQuery: currentState.searchQuery,
        );

        emit(
          StockMovementLoaded(
            response: data,
            filteredItems: filteredItems,
            currentQuery: currentState.currentQuery,
            searchQuery: currentState.searchQuery,
          ),
        );
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(StockMovementError(error: error.toString(), errorType: errorType));
      },
    );
  }

  /// Load more stock movements (pagination)
  Future<void> _onLoadMoreStockMovements(
    LoadMoreStockMovements event,
    Emitter<StockMovementState> emit,
  ) async {
    if (state is! StockMovementLoaded) return;

    final currentState = state as StockMovementLoaded;

    if (!currentState.hasMore || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.response.pagination.page + 1;
    final newQuery = StockMovementQuery(
      branchId: currentState.currentQuery.branchId,
      itemId: currentState.currentQuery.itemId,
      movementType: currentState.currentQuery.movementType,
      startDate: currentState.currentQuery.startDate,
      endDate: currentState.currentQuery.endDate,
      page: nextPage,
      limit: currentState.currentQuery.limit,
    );

    final response = await _repository.getStockMovements(newQuery);

    await response.when(
      success: (data) async {
        final combinedData = [...currentState.response.data, ...data.data];

        final newResponse = StockMovementResponse(
          message: data.message,
          data: combinedData,
          pagination: data.pagination,
        );

        final filteredItems = _applyFilters(
          combinedData,
          movementType: newQuery.movementType,
          searchQuery: currentState.searchQuery,
        );

        emit(
          StockMovementLoaded(
            response: newResponse,
            filteredItems: filteredItems,
            currentQuery: newQuery,
            searchQuery: currentState.searchQuery,
            isLoadingMore: false,
          ),
        );
      },
      error: (error) async {
        emit(currentState.copyWith(isLoadingMore: false));
      },
    );
  }

  /// Filter by movement type
  void _onFilterByMovementType(
    FilterByMovementType event,
    Emitter<StockMovementState> emit,
  ) {
    if (state is! StockMovementLoaded) return;

    final currentState = state as StockMovementLoaded;
    final newQuery = StockMovementQuery(
      branchId: currentState.currentQuery.branchId,
      itemId: currentState.currentQuery.itemId,
      movementType: event.movementType,
      startDate: currentState.currentQuery.startDate,
      endDate: currentState.currentQuery.endDate,
      page: 1,
      limit: currentState.currentQuery.limit,
    );

    final filteredItems = _applyFilters(
      currentState.response.data,
      movementType: event.movementType,
      searchQuery: currentState.searchQuery,
    );

    emit(
      currentState.copyWith(
        filteredItems: filteredItems,
        currentQuery: newQuery,
        isLoadingMore: false,
      ),
    );
  }

  /// Filter by date range
  void _onFilterByDateRange(
    FilterByDateRange event,
    Emitter<StockMovementState> emit,
  ) {
    if (state is! StockMovementLoaded) return;

    final currentState = state as StockMovementLoaded;

    final newQuery = StockMovementQuery(
      branchId: currentState.currentQuery.branchId,
      itemId: currentState.currentQuery.itemId,
      movementType: currentState.currentQuery.movementType,
      startDate: event.startDate,
      endDate: event.endDate,
      page: 1,
      limit: currentState.currentQuery.limit,
    );

    add(LoadStockMovements(query: newQuery));
  }

  /// Search stock movements
  void _onSearchStockMovements(
    SearchStockMovements event,
    Emitter<StockMovementState> emit,
  ) {
    if (state is! StockMovementLoaded) return;

    final currentState = state as StockMovementLoaded;

    final filteredItems = _applyFilters(
      currentState.response.data,
      movementType: currentState.currentQuery.movementType,
      searchQuery: event.query,
    );

    emit(
      currentState.copyWith(
        searchQuery: event.query,
        filteredItems: filteredItems,
      ),
    );
  }

  /// Clear all filters
  void _onClearMovementFilters(
    ClearMovementFilters event,
    Emitter<StockMovementState> emit,
  ) {
    final newQuery = StockMovementQuery(branchId: branchId, page: 1, limit: 20);

    add(LoadStockMovements(query: newQuery));
  }

  /// Filter items based on the active movement type and search query.
  List<StockMovementItem> _applyFilters(
    List<StockMovementItem> items, {
    String? movementType,
    required String searchQuery,
  }) {
    final query = searchQuery.toLowerCase();
    final filteredItems = items.where((item) {
      final matchesMovementType =
          movementType == null ||
          movementType.isEmpty ||
          item.movementType.name == movementType;

      final matchesSearch =
          query.isEmpty ||
          item.item.itemName.toLowerCase().contains(query) ||
          item.note?.toLowerCase().contains(query) == true ||
          item.reference?.toLowerCase().contains(query) == true ||
          item.branch.name.toLowerCase().contains(query);

      return matchesMovementType && matchesSearch;
    }).toList();

    filteredItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filteredItems;
  }

  /// Determine error type from error message
  StockMovementErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return StockMovementErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return StockMovementErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return StockMovementErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return StockMovementErrorType.validation;
    }

    return StockMovementErrorType.general;
  }
}
