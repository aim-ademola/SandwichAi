// bloc/menu_items_bloc/event.dart

import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';

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

class UpsertLocalMenuItem extends MenuItemsEvent {
  final ApiMenuItem menuItem;

  const UpsertLocalMenuItem(this.menuItem);

  @override
  List<Object?> get props => [menuItem];
}

class ReplaceLocalMenuItem extends MenuItemsEvent {
  final String localId;
  final ApiMenuItem menuItem;

  const ReplaceLocalMenuItem({required this.localId, required this.menuItem});

  @override
  List<Object?> get props => [localId, menuItem];
}

class RemoveLocalMenuItem extends MenuItemsEvent {
  final String localId;

  const RemoveLocalMenuItem(this.localId);

  @override
  List<Object?> get props => [localId];
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
