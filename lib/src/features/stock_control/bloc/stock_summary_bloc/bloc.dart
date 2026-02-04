import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_summary_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_summary_bloc/state.dart';

import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_summary_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/stock_summary_repo.dart';

class BranchStockSummaryBloc
    extends Bloc<BranchStockSummaryEvent, BranchStockSummaryState> {
  final BranchStockSummaryRepositoryInterface _repository;
  String branchId = '';

  BranchStockSummaryBloc({
    required BranchStockSummaryRepositoryInterface repository,
  }) : _repository = repository,
       super(const BranchStockSummaryInitial()) {
    _getBranchId();
    on<LoadBranchStockSummary>(_onLoadBranchStockSummary);
    on<RefreshBranchStockSummary>(_onRefreshBranchStockSummary);
    on<SearchStockCategories>(_onSearchStockCategories);
    on<ClearStockSearch>(_onClearStockSearch);
  }

  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  /// Load branch stock summary data
  Future<void> _onLoadBranchStockSummary(
    LoadBranchStockSummary event,
    Emitter<BranchStockSummaryState> emit,
  ) async {
    try {
      emit(const BranchStockSummaryLoading());

      final response = await _repository.getBranchStockSummary(branchId);

      await response.when(
        success: (data) async {
          // Convert stockByCategory to InventoryItem list
          final inventoryItems = data.data.stockByCategory
              .map((category) => category.toInventoryItem())
              .toList();

          // Empty inventory is a VALID state, not an error
          // Always emit loaded state, even if empty
          emit(
            BranchStockSummaryLoaded(
              response: data,
              filteredItems: inventoryItems,
              searchQuery: '',
            ),
          );
        },
        error: (error) async {
          // Extract error message from NetworkException
          final errorMessage = error.message ?? 'An unexpected error occurred';
          final errorType = _determineErrorType(errorMessage);

          emit(
            BranchStockSummaryError(error: errorMessage, errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const BranchStockSummaryError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: BranchStockSummaryErrorType.general,
        ),
      );
    }
  }

  /// Refresh branch stock summary
  Future<void> _onRefreshBranchStockSummary(
    RefreshBranchStockSummary event,
    Emitter<BranchStockSummaryState> emit,
  ) async {
    if (state is! BranchStockSummaryLoaded) {
      add(LoadBranchStockSummary(branchId: branchId));
      return;
    }

    final currentState = state as BranchStockSummaryLoaded;
    emit(BranchStockSummaryRefreshing(currentData: currentState.response));

    final response = await _repository.getBranchStockSummary(branchId);

    await response.when(
      success: (data) async {
        final inventoryItems = data.data.stockByCategory
            .map((category) => category.toInventoryItem())
            .toList();

        final filteredItems = _filterItems(
          inventoryItems,
          currentState.searchQuery,
        );

        // Always emit loaded state, even if empty
        emit(
          BranchStockSummaryLoaded(
            response: data,
            filteredItems: filteredItems,
            searchQuery: currentState.searchQuery,
          ),
        );
      },
      error: (error) async {
        // Extract error message from NetworkException
        final errorMessage = error.message ?? 'An unexpected error occurred';
        final errorType = _determineErrorType(errorMessage);

        emit(
          BranchStockSummaryError(error: errorMessage, errorType: errorType),
        );
      },
    );
  }

  /// Handle search
  void _onSearchStockCategories(
    SearchStockCategories event,
    Emitter<BranchStockSummaryState> emit,
  ) {
    if (state is! BranchStockSummaryLoaded) return;

    final currentState = state as BranchStockSummaryLoaded;

    final allItems = currentState.response.data.stockByCategory
        .map((category) => category.toInventoryItem())
        .toList();

    final filteredItems = _filterItems(allItems, event.query);

    // Empty search results are valid - still emit loaded state
    // The UI should handle displaying "No results found"
    emit(
      currentState.copyWith(
        searchQuery: event.query,
        filteredItems: filteredItems,
      ),
    );
  }

  /// Clear search
  void _onClearStockSearch(
    ClearStockSearch event,
    Emitter<BranchStockSummaryState> emit,
  ) {
    if (state is! BranchStockSummaryLoaded) return;

    final currentState = state as BranchStockSummaryLoaded;

    final allItems = currentState.response.data.stockByCategory
        .map((category) => category.toInventoryItem())
        .toList();

    emit(currentState.copyWith(searchQuery: '', filteredItems: allItems));
  }

  /// Filter items based on search query
  List<InventoryItem> _filterItems(
    List<InventoryItem> items,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) {
      return items;
    }

    final query = searchQuery.toLowerCase();
    return items.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();
  }

  /// Determine error type from error message
  BranchStockSummaryErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return BranchStockSummaryErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return BranchStockSummaryErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return BranchStockSummaryErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return BranchStockSummaryErrorType.validation;
    }

    return BranchStockSummaryErrorType.general;
  }
}
