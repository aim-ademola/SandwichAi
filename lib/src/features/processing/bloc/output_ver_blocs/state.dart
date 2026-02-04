import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/processing/data/model/output_verfification_model.dart';

abstract class OutputVerificationState extends Equatable {
  const OutputVerificationState();

  @override
  List<Object?> get props => [];
}

class OutputVerificationInitial extends OutputVerificationState {
  const OutputVerificationInitial();
}

class OutputVerificationLoading extends OutputVerificationState {
  const OutputVerificationLoading();
}

class MenuItemsLoaded extends OutputVerificationState {
  final List<MenuItem> menuItems;
  final MenuItem? selectedMenuItem;
  final Recipe? recipe;

  const MenuItemsLoaded({
    required this.menuItems,
    this.selectedMenuItem,
    this.recipe,
  });

  @override
  List<Object?> get props => [menuItems, selectedMenuItem, recipe];

  MenuItemsLoaded copyWith({
    List<MenuItem>? menuItems,
    MenuItem? selectedMenuItem,
    Recipe? recipe,
  }) {
    return MenuItemsLoaded(
      menuItems: menuItems ?? this.menuItems,
      selectedMenuItem: selectedMenuItem ?? this.selectedMenuItem,
      recipe: recipe ?? this.recipe,
    );
  }
}

class RecipeLoaded extends OutputVerificationState {
  final Recipe recipe;

  const RecipeLoaded({required this.recipe});

  @override
  List<Object?> get props => [recipe];
}

class OutputVerificationCreating extends OutputVerificationState {
  const OutputVerificationCreating();
}

class OutputVerificationCreated extends OutputVerificationState {
  final OutputVerification verification;
  final String message;

  const OutputVerificationCreated({
    required this.verification,
    this.message = 'Output verification created successfully!',
  });

  @override
  List<Object?> get props => [verification, message];
}

class OutputVerificationsLoaded extends OutputVerificationState {
  final List<OutputVerification> verifications;

  const OutputVerificationsLoaded({required this.verifications});

  @override
  List<Object?> get props => [verifications];
}

class OutputVerificationRefreshing extends OutputVerificationState {
  final List<OutputVerification> currentData;

  const OutputVerificationRefreshing({required this.currentData});

  @override
  List<Object?> get props => [currentData];
}

class OutputVerificationEmpty extends OutputVerificationState {
  const OutputVerificationEmpty();
}

class OutputVerificationError extends OutputVerificationState {
  final String error;
  final OutputVerificationErrorType errorType;

  const OutputVerificationError({
    required this.error,
    this.errorType = OutputVerificationErrorType.general,
  });

  @override
  List<Object?> get props => [error, errorType];
}

enum OutputVerificationErrorType {
  network,
  timeout,
  validation,
  server,
  notFound,
  general,
}

class RecipeLoading extends OutputVerificationState {
  final List<MenuItem> menuItems;
  final MenuItem? selectedMenuItem;

  const RecipeLoading({required this.menuItems, this.selectedMenuItem});

  @override
  List<Object?> get props => [menuItems, selectedMenuItem];
}

class RecipeLoadError extends OutputVerificationState {
  final String error;
  final OutputVerificationErrorType errorType;
  final List<MenuItem> menuItems;
  final MenuItem? selectedMenuItem;

  const RecipeLoadError({
    required this.error,
    required this.errorType,
    required this.menuItems,
    this.selectedMenuItem,
  });

  @override
  List<Object?> get props => [error, errorType, menuItems, selectedMenuItem];
}
