// bloc/menu_items_bloc/bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/api_menu_blocs/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/api_menu_blocs/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/api_menu_repo.dart';

class MenuItemsBloc extends Bloc<MenuItemsEvent, MenuItemsState> {
  static const Duration _cacheTtl = Duration(minutes: 5);

  final MenuItemsRepositoryInterface _repository;
  DateTime? _lastLoadedAt;
  List<ApiMenuItem> _cachedItems = const [];
  String _latestSearchQuery = '';

  MenuItemsBloc({required MenuItemsRepositoryInterface repository})
    : _repository = repository,
      super(const MenuItemsInitial()) {
    on<LoadMenuItems>(_onLoadMenuItems);
    on<RefreshMenuItems>(_onRefreshMenuItems);
    on<SearchMenuItems>(_onSearchMenuItems);
    on<FilterMenuItemsByCategory>(_onFilterMenuItemsByCategory);
  }

  Future<void> _onLoadMenuItems(
    LoadMenuItems event,
    Emitter<MenuItemsState> emit,
  ) async {
    try {
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

      final response = await _repository.getMenuItems();

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
    if (state is! MenuItemsLoaded) {
      add(const LoadMenuItems(forceRefresh: true));
      return;
    }

    final currentState = state as MenuItemsLoaded;
    emit(MenuItemsRefreshing(currentData: currentState.menuItems));

    final response = await _repository.getMenuItems(
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

  Future<void> _onSearchMenuItems(
    SearchMenuItems event,
    Emitter<MenuItemsState> emit,
  ) async {
    final currentItems = _allItemsForFiltering();
    final query = event.query.trim();
    _latestSearchQuery = query;

    if (query.isEmpty) {
      if (currentItems.isEmpty) {
        emit(const MenuItemsEmpty());
        return;
      }

      emit(
        MenuItemsLoaded(menuItems: currentItems, filteredItems: currentItems),
      );
      return;
    }

    final localMatches = currentItems
        .where((item) => _matchesQuery(item, query))
        .toList();

    if (currentItems.isNotEmpty) {
      emit(
        MenuItemsLoaded(
          menuItems: currentItems,
          filteredItems: localMatches,
          searchQuery: query,
        ),
      );
    }

    final response = await _repository.getMenuItems(search: query);

    await response.when(
      success: (remoteItems) async {
        if (_latestSearchQuery != query) return;

        final mergedItems = _mergeMenuItems(currentItems, remoteItems);
        final filteredItems = _mergeMenuItems(localMatches, remoteItems);

        _cachedItems = _mergeMenuItems(_cachedItems, remoteItems);
        _lastLoadedAt = DateTime.now();

        emit(
          MenuItemsLoaded(
            menuItems: mergedItems,
            filteredItems: filteredItems,
            searchQuery: query,
          ),
        );
      },
      error: (error) async {
        if (_latestSearchQuery == query && currentItems.isEmpty) {
          final errorType = _determineErrorType(error.toString());
          emit(MenuItemsError(error: error.toString(), errorType: errorType));
        }
      },
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

  List<ApiMenuItem> _mergeMenuItems(
    List<ApiMenuItem> baseItems,
    List<ApiMenuItem> incomingItems,
  ) {
    final merged = <String, ApiMenuItem>{};

    for (final item in [...baseItems, ...incomingItems]) {
      final key = item.id.isNotEmpty
          ? item.id
          : '${item.dishName}|${item.category}|${item.price}';
      merged[key] = item;
    }

    return merged.values.toList();
  }

  bool _matchesQuery(ApiMenuItem item, String query) {
    final searchableText = [
      item.dishName,
      item.description,
      item.category,
      item.price,
      ...?item.recipe?.ingredients?.map((ingredient) {
        return [
          ingredient.item?.itemName,
          ingredient.item?.category,
          ingredient.item?.sku,
        ].whereType<String>().join(' ');
      }),
    ].join(' ');

    return _containsQuery(searchableText, query);
  }

  bool _containsQuery(String source, String query) {
    final normalizedSource = _normalizeSearchText(source);
    final queryTokens = _normalizeSearchText(
      query,
    ).split(' ').where((token) => token.isNotEmpty);

    return queryTokens.every(normalizedSource.contains);
  }

  String _normalizeSearchText(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
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
