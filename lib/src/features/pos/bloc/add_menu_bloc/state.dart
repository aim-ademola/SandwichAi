import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';

enum MenuItemsErrorType {
  network,
  timeout,
  notFound,
  server,
  validation,
  general,
}

abstract class MenuItemsState extends Equatable {
  const MenuItemsState();

  @override
  List<Object?> get props => [];
}

class MenuItemsInitial extends MenuItemsState {
  const MenuItemsInitial();
}

class MenuItemsLoading extends MenuItemsState {
  const MenuItemsLoading();
}

class MenuItemsLoaded extends MenuItemsState {
  final List<ApiMenuItem> menuItems;
  final List<ApiMenuItem> filteredItems;
  final String? searchQuery;
  final String? selectedCategory;

  const MenuItemsLoaded({
    required this.menuItems,
    required this.filteredItems,
    this.searchQuery,
    this.selectedCategory,
  });

  @override
  List<Object?> get props => [
    menuItems,
    filteredItems,
    searchQuery,
    selectedCategory,
  ];

  MenuItemsLoaded copyWith({
    List<ApiMenuItem>? menuItems,
    List<ApiMenuItem>? filteredItems,
    String? searchQuery,
    String? selectedCategory,
  }) {
    return MenuItemsLoaded(
      menuItems: menuItems ?? this.menuItems,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class MenuItemsRefreshing extends MenuItemsState {
  final List<ApiMenuItem> currentData;

  const MenuItemsRefreshing({required this.currentData});

  @override
  List<Object?> get props => [currentData];
}

class MenuItemsEmpty extends MenuItemsState {
  const MenuItemsEmpty();
}

class MenuItemsError extends MenuItemsState {
  final String error;
  final MenuItemsErrorType errorType;

  const MenuItemsError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}

class MenuItemCreating extends MenuItemsState {
  const MenuItemCreating();
}

class MenuItemCreated extends MenuItemsState {
  final ApiMenuItem menuItem;

  const MenuItemCreated({required this.menuItem});

  @override
  List<Object?> get props => [menuItem];
}

class MenuItemCreationError extends MenuItemsState {
  final String error;
  final MenuItemsErrorType errorType;

  const MenuItemCreationError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}

class MenuItemUpdating extends MenuItemsState {
  const MenuItemUpdating();
}

class MenuItemUpdated extends MenuItemsState {
  final ApiMenuItem menuItem;

  const MenuItemUpdated({required this.menuItem});

  @override
  List<Object?> get props => [menuItem];
}

class MenuItemUpdateError extends MenuItemsState {
  final String error;
  final MenuItemsErrorType errorType;

  const MenuItemUpdateError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}

// Delete MenuItem States
class MenuItemDeleting extends MenuItemsState {
  const MenuItemDeleting();
}

class MenuItemDeleted extends MenuItemsState {
  final String message;

  const MenuItemDeleted({required this.message});

  @override
  List<Object?> get props => [message];
}

class MenuItemDeletionError extends MenuItemsState {
  final String error;
  final MenuItemsErrorType errorType;

  const MenuItemDeletionError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}
