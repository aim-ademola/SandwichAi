import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/add_menu_repo.dart';

class MenuItemsBloc extends Bloc<MenuItemsEvent, MenuItemsState> {
  final MenuItemsRepositoryInterface _repository;

  MenuItemsBloc({required MenuItemsRepositoryInterface repository})
    : _repository = repository,
      super(const MenuItemsInitial()) {
    on<LoadMenuItems>(_onLoadMenuItems);
    on<RefreshMenuItems>(_onRefreshMenuItems);
    on<SearchMenuItems>(_onSearchMenuItems);
    on<FilterMenuItemsByCategory>(_onFilterMenuItemsByCategory);
    on<CreateMenuItem>(_onCreateMenuItem);
    on<UpdateMenuItem>(_onUpdateMenuItem);
    on<DeleteMenuItem>(_onDeleteMenuItem);
  }

  Future<void> _onLoadMenuItems(
    LoadMenuItems event,
    Emitter<MenuItemsState> emit,
  ) async {
    try {
      emit(const MenuItemsLoading());

      final response = await _repository.getMenuItems();

      await response.when(
        success: (menuItems) async {
          if (menuItems.isEmpty) {
            emit(const MenuItemsEmpty());
            return;
          }

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
      add(const LoadMenuItems());
      return;
    }

    final currentState = state as MenuItemsLoaded;
    emit(MenuItemsRefreshing(currentData: currentState.menuItems));

    final response = await _repository.getMenuItems();

    await response.when(
      success: (menuItems) async {
        if (menuItems.isEmpty) {
          emit(const MenuItemsEmpty());
          return;
        }

        emit(MenuItemsLoaded(menuItems: menuItems, filteredItems: menuItems));
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(MenuItemsError(error: error.toString(), errorType: errorType));
      },
    );
  }

  void _onSearchMenuItems(SearchMenuItems event, Emitter<MenuItemsState> emit) {
    if (state is! MenuItemsLoaded) return;

    final menuItems = (state as MenuItemsLoaded).menuItems;

    if (event.query.isEmpty) {
      emit(
        MenuItemsLoaded(
          menuItems: menuItems,
          filteredItems: menuItems,
          searchQuery: null,
        ),
      );
      return;
    }

    final query = event.query.toLowerCase();
    final filtered = menuItems.where((item) {
      return item.dishName.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();

    emit(
      MenuItemsLoaded(
        menuItems: menuItems,
        filteredItems: filtered,
        searchQuery: event.query,
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

    final filtered = menuItems.where((item) {
      return item.category == event.category;
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

  Future<void> _onCreateMenuItem(
    CreateMenuItem event,
    Emitter<MenuItemsState> emit,
  ) async {
    emit(
      const MenuItemCreationError(
        error: 'Menu items can only be created by the organization.',
        errorType: MenuItemsErrorType.validation,
      ),
    );
  }

  Future<void> _onUpdateMenuItem(
    UpdateMenuItem event,
    Emitter<MenuItemsState> emit,
  ) async {
    try {
      emit(const MenuItemUpdating());

      final response = await _repository.updateMenuItemAvailability(
        menuItemId: event.menuItemId,
        isAvailable: event.isAvailable,
      );

      await response.when(
        success: (menuItem) async {
          emit(MenuItemUpdated(menuItem: menuItem));
          // Reload menu items to get the updated list
          add(const LoadMenuItems());
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            MenuItemUpdateError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const MenuItemUpdateError(
          error: 'Failed to update menu item. Please try again.',
          errorType: MenuItemsErrorType.general,
        ),
      );
    }
  }

  Future<void> _onDeleteMenuItem(
    DeleteMenuItem event,
    Emitter<MenuItemsState> emit,
  ) async {
    emit(
      const MenuItemDeletionError(
        error: 'Menu items can only be removed by the organization.',
        errorType: MenuItemsErrorType.validation,
      ),
    );
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
