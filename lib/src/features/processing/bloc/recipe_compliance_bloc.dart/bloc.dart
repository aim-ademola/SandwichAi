import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_compliance_bloc.dart/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_compliance_bloc.dart/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/recipe_compliance_models.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/recipe_compliance_repo.dart';

class RecipeComplianceBloc
    extends Bloc<RecipeComplianceEvent, RecipeComplianceState> {
  final RecipeComplianceRepositoryInterface _repository;
  String branchId = '';

  RecipeComplianceBloc({
    required RecipeComplianceRepositoryInterface repository,
  }) : _repository = repository,
       super(const RecipeComplianceInitial()) {
    _getBranchId();
    on<LoadMenuItems>(_onLoadMenuItems);
    on<SearchMenuItems>(_onSearchMenuItems);
    on<ClearMenuSearch>(_onClearMenuSearch);
    on<SubmitRecipeCompliance>(_onSubmitRecipeCompliance);
    on<ResetRecipeCompliance>(_onResetRecipeCompliance);
  }

  /// Get branch ID from cache
  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  /// Load menu items
  Future<void> _onLoadMenuItems(
    LoadMenuItems event,
    Emitter<RecipeComplianceState> emit,
  ) async {
    try {
      emit(const MenuItemsLoading());

      final response = await _repository.getMenuItems(branchId);

      await response.when(
        success: (data) async {
          if (!data.isValid) {
            emit(
              const RecipeComplianceError(
                error: 'No menu items found for this branch',
                errorType: RecipeComplianceErrorType.validation,
              ),
            );
            return;
          }

          // Filter only available items
          final availableItems = data.menuItems
              .where((item) => item.isAvailable)
              .toList();

          if (availableItems.isEmpty) {
            emit(
              const RecipeComplianceError(
                error: 'No available menu items found',
                errorType: RecipeComplianceErrorType.validation,
              ),
            );
            return;
          }

          emit(
            MenuItemsLoaded(
              menuItems: availableItems,
              filteredItems: availableItems,
              searchQuery: '',
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            RecipeComplianceError(
              error: error.toString(),
              errorType: errorType,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        const RecipeComplianceError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: RecipeComplianceErrorType.general,
        ),
      );
    }
  }

  /// Search menu items
  void _onSearchMenuItems(
    SearchMenuItems event,
    Emitter<RecipeComplianceState> emit,
  ) {
    if (state is! MenuItemsLoaded) return;

    final currentState = state as MenuItemsLoaded;
    final filteredItems = _filterMenuItems(currentState.menuItems, event.query);

    emit(
      currentState.copyWith(
        filteredItems: filteredItems,
        searchQuery: event.query,
      ),
    );
  }

  /// Clear search
  void _onClearMenuSearch(
    ClearMenuSearch event,
    Emitter<RecipeComplianceState> emit,
  ) {
    if (state is! MenuItemsLoaded) return;

    final currentState = state as MenuItemsLoaded;
    emit(
      currentState.copyWith(
        filteredItems: currentState.menuItems,
        searchQuery: '',
      ),
    );
  }

  /// Submit recipe compliance
  Future<void> _onSubmitRecipeCompliance(
    SubmitRecipeCompliance event,
    Emitter<RecipeComplianceState> emit,
  ) async {
    try {
      emit(const RecipeComplianceSubmitting());

      final response = await _repository.submitRecipeCompliance(event.request);

      await response.when(
        success: (data) async {
          if (!data.isValid) {
            emit(
              const RecipeComplianceError(
                error: 'Invalid response received from server',
                errorType: RecipeComplianceErrorType.validation,
              ),
            );
            return;
          }

          emit(RecipeComplianceSuccess(response: data));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            RecipeComplianceError(
              error: error.toString(),
              errorType: errorType,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        const RecipeComplianceError(
          error: 'Failed to submit recipe compliance. Please try again.',
          errorType: RecipeComplianceErrorType.general,
        ),
      );
    }
  }

  /// Reset to initial state
  void _onResetRecipeCompliance(
    ResetRecipeCompliance event,
    Emitter<RecipeComplianceState> emit,
  ) {
    emit(const RecipeComplianceInitial());
  }

  /// Filter menu items by search query
  List<MenuItem> _filterMenuItems(List<MenuItem> items, String query) {
    if (query.isEmpty) return items;

    final lowercaseQuery = query.toLowerCase();
    return items.where((item) {
      return item.dishName.toLowerCase().contains(lowercaseQuery) ||
          item.category.toLowerCase().contains(lowercaseQuery) ||
          item.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Determine error type from error message
  RecipeComplianceErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return RecipeComplianceErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return RecipeComplianceErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return RecipeComplianceErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return RecipeComplianceErrorType.validation;
    }

    return RecipeComplianceErrorType.general;
  }
}
