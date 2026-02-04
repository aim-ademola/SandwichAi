// bloc/menu_items_bloc/state.dart

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

class MenuItemsRefreshing extends MenuItemsState {
  final List<ApiMenuItem> currentData;

  const MenuItemsRefreshing({required this.currentData});

  @override
  List<Object?> get props => [currentData];
}

class MenuItemsLoaded extends MenuItemsState {
  final List<ApiMenuItem> menuItems;
  final List<ApiMenuItem> filteredItems;
  final String? selectedCategory;
  final String? searchQuery;

  const MenuItemsLoaded({
    required this.menuItems,
    required this.filteredItems,
    this.selectedCategory,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [
    menuItems,
    filteredItems,
    selectedCategory,
    searchQuery,
  ];

  MenuItemsLoaded copyWith({
    List<ApiMenuItem>? menuItems,
    List<ApiMenuItem>? filteredItems,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return MenuItemsLoaded(
      menuItems: menuItems ?? this.menuItems,
      filteredItems: filteredItems ?? this.filteredItems,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<String> get categories {
    final cats = menuItems.map((item) => item.category).toSet().toList();
    cats.sort();
    return cats;
  }
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
