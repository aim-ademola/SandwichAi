import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/processing/data/model/recipe_compliance_models.dart';

abstract class RecipeComplianceState extends Equatable {
  const RecipeComplianceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class RecipeComplianceInitial extends RecipeComplianceState {
  const RecipeComplianceInitial();
}

/// Loading menu items
class MenuItemsLoading extends RecipeComplianceState {
  const MenuItemsLoading();
}

/// Menu items loaded successfully
class MenuItemsLoaded extends RecipeComplianceState {
  final List<MenuItem> menuItems;
  final List<MenuItem> filteredItems;
  final String searchQuery;

  const MenuItemsLoaded({
    required this.menuItems,
    required this.filteredItems,
    this.searchQuery = '',
  });

  MenuItemsLoaded copyWith({
    List<MenuItem>? menuItems,
    List<MenuItem>? filteredItems,
    String? searchQuery,
  }) {
    return MenuItemsLoaded(
      menuItems: menuItems ?? this.menuItems,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [menuItems, filteredItems, searchQuery];
}

/// Submitting recipe compliance
class RecipeComplianceSubmitting extends RecipeComplianceState {
  const RecipeComplianceSubmitting();
}

/// Recipe compliance submitted successfully
class RecipeComplianceSuccess extends RecipeComplianceState {
  final RecipeComplianceResponse response;

  const RecipeComplianceSuccess({required this.response});

  @override
  List<Object?> get props => [response];
}

/// Error state
class RecipeComplianceError extends RecipeComplianceState {
  final String error;
  final RecipeComplianceErrorType errorType;

  const RecipeComplianceError({
    required this.error,
    this.errorType = RecipeComplianceErrorType.general,
  });

  @override
  List<Object?> get props => [error, errorType];
}

/// Error types for better error handling
enum RecipeComplianceErrorType { network, timeout, server, validation, general }
