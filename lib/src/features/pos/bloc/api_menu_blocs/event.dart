// bloc/menu_items_bloc/event.dart

import 'package:equatable/equatable.dart';

abstract class MenuItemsEvent extends Equatable {
  const MenuItemsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMenuItems extends MenuItemsEvent {
  final bool forceRefresh;

  const LoadMenuItems({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class RefreshMenuItems extends MenuItemsEvent {
  const RefreshMenuItems();
}

class SearchMenuItems extends MenuItemsEvent {
  final String query;

  const SearchMenuItems({required this.query});

  @override
  List<Object?> get props => [query];
}

class FilterMenuItemsByCategory extends MenuItemsEvent {
  final String category;

  const FilterMenuItemsByCategory({required this.category});

  @override
  List<Object?> get props => [category];
}
