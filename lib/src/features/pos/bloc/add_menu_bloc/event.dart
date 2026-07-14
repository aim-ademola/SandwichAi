// bloc/menu_items_bloc/event.dart

import 'package:equatable/equatable.dart';

abstract class MenuItemsEvent extends Equatable {
  const MenuItemsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMenuItems extends MenuItemsEvent {
  const LoadMenuItems();
}

class RefreshMenuItems extends MenuItemsEvent {
  const RefreshMenuItems();
}

class SearchMenuItems extends MenuItemsEvent {
  final String query;

  const SearchMenuItems(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterMenuItemsByCategory extends MenuItemsEvent {
  final String category;

  const FilterMenuItemsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class CreateMenuItem extends MenuItemsEvent {
  final String dishName;
  final String description;
  final String category;
  final int price;
  final int preparationTime;
  final bool isAvailable;
  final String? imageUrl;

  const CreateMenuItem({
    required this.dishName,
    required this.description,
    required this.category,
    required this.price,
    required this.preparationTime,
    this.isAvailable = true,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
    dishName,
    description,
    category,
    price,
    preparationTime,
    isAvailable,
    imageUrl,
  ];
}

class UpdateMenuItem extends MenuItemsEvent {
  final String menuItemId;
  final bool isAvailable;

  const UpdateMenuItem({
    required this.menuItemId,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [menuItemId, isAvailable];
}

class DeleteMenuItem extends MenuItemsEvent {
  final String menuItemId;

  const DeleteMenuItem({required this.menuItemId});

  @override
  List<Object?> get props => [menuItemId];
}
