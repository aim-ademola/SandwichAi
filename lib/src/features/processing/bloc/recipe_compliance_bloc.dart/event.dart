import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/processing/data/model/recipe_compliance_models.dart';

abstract class RecipeComplianceEvent extends Equatable {
  const RecipeComplianceEvent();

  @override
  List<Object?> get props => [];
}

/// Load menu items for the branch
class LoadMenuItems extends RecipeComplianceEvent {
  const LoadMenuItems();

  @override
  List<Object?> get props => [];
}

/// Search menu items by query
class SearchMenuItems extends RecipeComplianceEvent {
  final String query;

  const SearchMenuItems({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Clear search query
class ClearMenuSearch extends RecipeComplianceEvent {
  const ClearMenuSearch();
}

/// Submit recipe compliance
class SubmitRecipeCompliance extends RecipeComplianceEvent {
  final RecipeComplianceRequest request;

  const SubmitRecipeCompliance({required this.request});

  @override
  List<Object?> get props => [request];
}

/// Reset form/state
class ResetRecipeCompliance extends RecipeComplianceEvent {
  const ResetRecipeCompliance();
}
