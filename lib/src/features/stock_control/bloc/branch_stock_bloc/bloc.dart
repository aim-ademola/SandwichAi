import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/branch_stock_repo.dart';

class BranchStockBloc extends Bloc<BranchStockEvent, BranchStockState> {
  final BranchStockRepositoryInterface _repository;

  BranchStockBloc({required BranchStockRepositoryInterface repository})
    : _repository = repository,
      super(const BranchStockInitial()) {
    getBranchid();
    on<LoadBranchStock>(_onLoadBranchStock);
    on<SelectCategory>(_onSelectCategory);
    on<SearchItems>(_onSearchItems);
    on<ToggleViewMode>(_onToggleViewMode);
    on<RefreshBranchStock>(_onRefreshBranchStock);
    on<ClearSearch>(_onClearSearch);
  }

  void getBranchid() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  String branchId = '';

  /// Load branch stock data
  Future<void> _onLoadBranchStock(
    LoadBranchStock event,
    Emitter<BranchStockState> emit,
  ) async {
    try {
      emit(const BranchStockLoading());

      final resolvedBranchId = await _resolveBranchId(event.branchId);
      if (resolvedBranchId.isEmpty) {
        emit(
          const BranchStockError(
            error: 'Branch ID not found. Please login again.',
            errorType: BranchStockErrorType.general,
          ),
        );
        return;
      }

      final response = await _repository.getBranchStock(resolvedBranchId);

      await response.when(
        success: (data) async {
          final categories = ['All', ...data.categories];

          final catalogItems = data.data
              .map((item) => item.toCatalogItem())
              .toList();

          // Empty data is valid - always emit loaded state
          emit(
            BranchStockLoaded(
              response: data,
              categories: categories,
              selectedCategory: 'All',
              searchQuery: '',
              isTableView: false,
              filteredItems: catalogItems,
            ),
          );
        },

        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(BranchStockError(error: error.toString(), errorType: errorType));
        },
      );
    } catch (e) {
      emit(
        const BranchStockError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: BranchStockErrorType.general,
        ),
      );
    }
  }

  /// Handle category selection
  void _onSelectCategory(SelectCategory event, Emitter<BranchStockState> emit) {
    if (state is! BranchStockLoaded) return;

    final currentState = state as BranchStockLoaded;
    final filteredItems = _filterItems(
      currentState.response,
      event.category,
      currentState.searchQuery,
    );

    emit(
      currentState.copyWith(
        selectedCategory: event.category,
        filteredItems: filteredItems,
      ),
    );
  }

  /// Handle search
  void _onSearchItems(SearchItems event, Emitter<BranchStockState> emit) {
    if (state is! BranchStockLoaded) return;

    final currentState = state as BranchStockLoaded;
    final filteredItems = _filterItems(
      currentState.response,
      currentState.selectedCategory,
      event.query,
    );

    emit(
      currentState.copyWith(
        searchQuery: event.query,
        filteredItems: filteredItems,
      ),
    );
  }

  /// Toggle between card and table view
  void _onToggleViewMode(ToggleViewMode event, Emitter<BranchStockState> emit) {
    if (state is! BranchStockLoaded) return;

    final currentState = state as BranchStockLoaded;
    emit(currentState.copyWith(isTableView: !currentState.isTableView));
  }

  /// Refresh branch stock
  Future<void> _onRefreshBranchStock(
    RefreshBranchStock event,
    Emitter<BranchStockState> emit,
  ) async {
    if (state is! BranchStockLoaded) {
      add(LoadBranchStock(branchId: event.branchId ?? branchId));
      return;
    }

    final currentState = state as BranchStockLoaded;
    emit(BranchStockRefreshing(currentData: currentState.response));

    final resolvedBranchId = await _resolveBranchId(event.branchId);
    if (resolvedBranchId.isEmpty) {
      emit(
        const BranchStockError(
          error: 'Branch ID not found. Please login again.',
          errorType: BranchStockErrorType.general,
        ),
      );
      return;
    }

    final response = await _repository.getBranchStock(resolvedBranchId);

    await response.when(
      success: (data) async {
        final categories = ['All', ...data.categories];
        data.data.map((item) => item.toCatalogItem()).toList();

        final filteredItems = _filterItems(
          data,
          currentState.selectedCategory,
          currentState.searchQuery,
        );

        // Always emit loaded state, even if empty
        emit(
          BranchStockLoaded(
            response: data,
            categories: categories,
            selectedCategory: currentState.selectedCategory,
            searchQuery: currentState.searchQuery,
            isTableView: currentState.isTableView,
            filteredItems: filteredItems,
          ),
        );
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(BranchStockError(error: error.toString(), errorType: errorType));
      },
    );
  }

  /// Clear search
  void _onClearSearch(ClearSearch event, Emitter<BranchStockState> emit) {
    if (state is! BranchStockLoaded) return;

    final currentState = state as BranchStockLoaded;
    final filteredItems = _filterItems(
      currentState.response,
      currentState.selectedCategory,
      '',
    );

    emit(currentState.copyWith(searchQuery: '', filteredItems: filteredItems));
  }

  Future<String> _resolveBranchId(String? requestedBranchId) async {
    final requested = requestedBranchId?.trim() ?? '';
    if (requested.isNotEmpty) {
      branchId = requested;
      return requested;
    }

    if (branchId.isNotEmpty) return branchId;

    branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    return branchId;
  }

  /// Filter items based on category and search query
  List<CatalogItem> _filterItems(
    BranchStockResponse response,
    String category,
    String searchQuery,
  ) {
    // Get items by category
    var items = response.getItemsByCategory(category);

    // Convert to CatalogItem
    var catalogItems = items.map((item) => item.toCatalogItem()).toList();

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      catalogItems = catalogItems.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query);
      }).toList();
    }

    return catalogItems;
  }

  /// Determine error type from error message
  BranchStockErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return BranchStockErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return BranchStockErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return BranchStockErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return BranchStockErrorType.validation;
    }

    return BranchStockErrorType.general;
  }
}
