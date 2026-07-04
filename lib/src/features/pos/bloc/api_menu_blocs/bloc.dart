// bloc/menu_items_bloc/bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/pos/bloc/api_menu_blocs/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/api_menu_blocs/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/api_menu_repo.dart';

class MenuItemsBloc extends Bloc<MenuItemsEvent, MenuItemsState> {
  static const Duration _cacheTtl = Duration(minutes: 5);

  final MenuItemsRepositoryInterface _repository;
  String branchId = '';
  DateTime? _lastLoadedAt;
  List<ApiMenuItem> _cachedItems = const [];

  MenuItemsBloc({required MenuItemsRepositoryInterface repository})
    : _repository = repository,
      super(const MenuItemsInitial()) {
    _getBranchId();
    on<LoadMenuItems>(_onLoadMenuItems);
    on<RefreshMenuItems>(_onRefreshMenuItems);
    on<SearchMenuItems>(_onSearchMenuItems);
    on<FilterMenuItemsByCategory>(_onFilterMenuItemsByCategory);
  }

  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  Future<void> _ensureBranchId() async {
    if (branchId.isNotEmpty) return;
    branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
  }

  Future<void> _onLoadMenuItems(
    LoadMenuItems event,
    Emitter<MenuItemsState> emit,
  ) async {
    try {
      await _ensureBranchId();
      final cacheIsFresh =
          _lastLoadedAt != null &&
          DateTime.now().difference(_lastLoadedAt!) < _cacheTtl;

      if (!event.forceRefresh && _cachedItems.isNotEmpty && cacheIsFresh) {
        emit(
          MenuItemsLoaded(menuItems: _cachedItems, filteredItems: _cachedItems),
        );
        return;
      }

      if (!event.forceRefresh && state is MenuItemsLoaded && cacheIsFresh) {
        return;
      }

      emit(const MenuItemsLoading());

      final response = await _repository.getMenuItems(branchId: branchId);

      await response.when(
        success: (menuItems) async {
          if (menuItems.isEmpty) {
            emit(const MenuItemsEmpty());
            return;
          }

          _cachedItems = menuItems;
          _lastLoadedAt = DateTime.now();
          emit(MenuItemsLoaded(menuItems: menuItems, filteredItems: menuItems));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(MenuItemsError(error: error.toString(), errorType: errorType));
        },
      );
    } catch (e) {
      emit(
        const MenuItemsError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: MenuItemsErrorType.general,
        ),
      );
    }
  }

  Future<void> _onRefreshMenuItems(
    RefreshMenuItems event,
    Emitter<MenuItemsState> emit,
  ) async {
    await _ensureBranchId();
    if (state is! MenuItemsLoaded) {
      add(const LoadMenuItems(forceRefresh: true));
      return;
    }

    final currentState = state as MenuItemsLoaded;
    emit(MenuItemsRefreshing(currentData: currentState.menuItems));

    final response = await _repository.getMenuItems(
      branchId: branchId,
      search: currentState.searchQuery,
    );

    await response.when(
      success: (menuItems) async {
        if (menuItems.isEmpty) {
          emit(const MenuItemsEmpty());
          return;
        }

        _cachedItems = menuItems;
        _lastLoadedAt = DateTime.now();
        emit(
          MenuItemsLoaded(
            menuItems: menuItems,
            filteredItems: menuItems,
            searchQuery: currentState.searchQuery,
          ),
        );
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(MenuItemsError(error: error.toString(), errorType: errorType));
      },
    );
  }

  void _onSearchMenuItems(SearchMenuItems event, Emitter<MenuItemsState> emit) {
    final currentItems = _allItemsForFiltering();
    final query = event.query.trim();
    if (currentItems.isEmpty) {
      emit(const MenuItemsEmpty());
      return;
    }

    final filteredItems = query.isEmpty
        ? currentItems
        : currentItems.where((item) => _matchesQuery(item, query)).toList();

    emit(
      MenuItemsLoaded(
        menuItems: currentItems,
        filteredItems: filteredItems,
        searchQuery: query.isEmpty ? null : query,
      ),
    );
  }

  void _onFilterMenuItemsByCategory(
    FilterMenuItemsByCategory event,
    Emitter<MenuItemsState> emit,
  ) {
    if (state is! MenuItemsLoaded) return;

    final currentState = state as MenuItemsLoaded;
    final menuItems = currentState.menuItems;
    final searchQuery = currentState.searchQuery;

    final filtered = menuItems.where((item) {
      final categoryMatches = item.category == event.category;
      final searchMatches =
          searchQuery == null || _matchesQuery(item, searchQuery);
      return categoryMatches && searchMatches;
    }).toList();

    emit(
      MenuItemsLoaded(
        menuItems: menuItems,
        filteredItems: filtered,
        selectedCategory: event.category,
        searchQuery: currentState.searchQuery,
      ),
    );
  }

  List<ApiMenuItem> _allItemsForFiltering() {
    if (state is MenuItemsLoaded) {
      return (state as MenuItemsLoaded).menuItems;
    }
    if (state is MenuItemsRefreshing) {
      return (state as MenuItemsRefreshing).currentData;
    }
    return _cachedItems;
  }

  bool _matchesQuery(ApiMenuItem item, String query) {
    final normalizedQuery = query.toLowerCase();
    return [
      item.dishName,
      item.description,
      item.category,
      item.price,
    ].join(' ').toLowerCase().contains(normalizedQuery);
  }

  MenuItemsErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return MenuItemsErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return MenuItemsErrorType.timeout;
    }

    if (lowercaseError.contains('not found') ||
        lowercaseError.contains('404')) {
      return MenuItemsErrorType.notFound;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return MenuItemsErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return MenuItemsErrorType.validation;
    }

    return MenuItemsErrorType.general;
  }
}
