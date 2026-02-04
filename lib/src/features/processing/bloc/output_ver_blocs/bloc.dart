// bloc/output_verification_bloc/bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/processing/bloc/output_ver_blocs/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/output_ver_blocs/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/output_verfification_model.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/output_ver_repo.dart';

class OutputVerificationBloc
    extends Bloc<OutputVerificationEvent, OutputVerificationState> {
  final OutputVerificationRepositoryInterface _repository;
  String branchId = '';

  OutputVerificationBloc({
    required OutputVerificationRepositoryInterface repository,
  }) : _repository = repository,
       super(const OutputVerificationInitial()) {
    _getBranchId();
    on<LoadMenuItems>(_onLoadMenuItems);
    on<LoadRecipe>(_onLoadRecipe);
    on<CreateOutputVerification>(_onCreateOutputVerification);
    on<LoadOutputVerifications>(_onLoadOutputVerifications);
    on<RefreshOutputVerifications>(_onRefreshOutputVerifications);
    on<SelectMenuItem>(_onSelectMenuItem);
    on<ResetForm>(_onResetForm);
  }

  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  Future<void> _onLoadMenuItems(
    LoadMenuItems event,
    Emitter<OutputVerificationState> emit,
  ) async {
    try {
      emit(const OutputVerificationLoading());

      final response = await _repository.getMenuItems(branchId: branchId);

      await response.when(
        success: (menuItems) async {
          if (menuItems.isEmpty) {
            emit(const OutputVerificationEmpty());
            return;
          }

          emit(MenuItemsLoaded(menuItems: menuItems));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            OutputVerificationError(
              error: error.toString(),
              errorType: errorType,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        const OutputVerificationError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: OutputVerificationErrorType.general,
        ),
      );
    }
  }

  Future<void> _onLoadRecipe(
    LoadRecipe event,
    Emitter<OutputVerificationState> emit,
  ) async {
    try {
      if (state is! MenuItemsLoaded) return;

      final currentState = state as MenuItemsLoaded;

      // Emit loading state WITH the current menu items and selected item
      emit(
        RecipeLoading(
          menuItems: currentState.menuItems,
          selectedMenuItem: currentState.selectedMenuItem,
        ),
      );

      final response = await _repository.getRecipe(
        menuItemId: event.menuItemId,
      );

      await response.when(
        success: (recipe) async {
          // Emit success with all data preserved
          emit(
            MenuItemsLoaded(
              menuItems: currentState.menuItems,
              selectedMenuItem: currentState.selectedMenuItem,
              recipe: recipe,
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          // Emit error but keep menu items and selected item
          emit(
            RecipeLoadError(
              error: error.toString(),
              errorType: errorType,
              menuItems: currentState.menuItems,
              selectedMenuItem: currentState.selectedMenuItem,
            ),
          );
        },
      );
    } catch (e) {
      if (state is MenuItemsLoaded) {
        final currentState = state as MenuItemsLoaded;
        emit(
          RecipeLoadError(
            error: 'Failed to load recipe. Please try again.',
            errorType: OutputVerificationErrorType.general,
            menuItems: currentState.menuItems,
            selectedMenuItem: currentState.selectedMenuItem,
          ),
        );
      } else {
        emit(
          const OutputVerificationError(
            error: 'Failed to load recipe. Please try again.',
            errorType: OutputVerificationErrorType.general,
          ),
        );
      }
    }
  }

  Future<void> _onCreateOutputVerification(
    CreateOutputVerification event,
    Emitter<OutputVerificationState> emit,
  ) async {
    try {
      emit(const OutputVerificationCreating());

      final response = await _repository.createOutputVerification(
        request: event.request,
      );

      await response.when(
        success: (verification) async {
          emit(OutputVerificationCreated(verification: verification));
          // Auto-reload menu items after creation
          add(const LoadMenuItems());
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            OutputVerificationError(
              error: error.toString(),
              errorType: errorType,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        const OutputVerificationError(
          error: 'Failed to create output verification. Please try again.',
          errorType: OutputVerificationErrorType.general,
        ),
      );
    }
  }

  Future<void> _onLoadOutputVerifications(
    LoadOutputVerifications event,
    Emitter<OutputVerificationState> emit,
  ) async {
    try {
      emit(const OutputVerificationLoading());

      final response = await _repository.getOutputVerifications(
        branchId: branchId,
      );

      await response.when(
        success: (verifications) async {
          if (verifications.isEmpty) {
            emit(const OutputVerificationEmpty());
            return;
          }

          emit(OutputVerificationsLoaded(verifications: verifications));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            OutputVerificationError(
              error: error.toString(),
              errorType: errorType,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        const OutputVerificationError(
          error: 'Failed to load verifications. Please try again.',
          errorType: OutputVerificationErrorType.general,
        ),
      );
    }
  }

  Future<void> _onRefreshOutputVerifications(
    RefreshOutputVerifications event,
    Emitter<OutputVerificationState> emit,
  ) async {
    if (state is! OutputVerificationsLoaded) {
      add(const LoadOutputVerifications());
      return;
    }

    final currentState = state as OutputVerificationsLoaded;
    emit(OutputVerificationRefreshing(currentData: currentState.verifications));

    final response = await _repository.getOutputVerifications(
      branchId: branchId,
    );

    await response.when(
      success: (verifications) async {
        if (verifications.isEmpty) {
          emit(const OutputVerificationEmpty());
          return;
        }

        emit(OutputVerificationsLoaded(verifications: verifications));
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(
          OutputVerificationError(
            error: error.toString(),
            errorType: errorType,
          ),
        );
      },
    );
  }

  void _onSelectMenuItem(
    SelectMenuItem event,
    Emitter<OutputVerificationState> emit,
  ) {
    if (state is! MenuItemsLoaded && state is! RecipeLoadError) return;

    List<MenuItem> menuItems = [];

    if (state is MenuItemsLoaded) {
      menuItems = (state as MenuItemsLoaded).menuItems;
    } else if (state is RecipeLoadError) {
      menuItems = (state as RecipeLoadError).menuItems;
    }

    // Immediately update with selected menu item but no recipe
    emit(
      MenuItemsLoaded(
        menuItems: menuItems,
        selectedMenuItem: event.menuItem,
        recipe: null, // Clear previous recipe
      ),
    );

    // Load recipe for selected menu item
    add(LoadRecipe(menuItemId: event.menuItem.id));
  }

  void _onResetForm(ResetForm event, Emitter<OutputVerificationState> emit) {
    if (state is! MenuItemsLoaded) return;

    final currentState = state as MenuItemsLoaded;
    emit(
      MenuItemsLoaded(
        menuItems: currentState.menuItems,
        selectedMenuItem: null,
        recipe: null,
      ),
    );
  }

  OutputVerificationErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return OutputVerificationErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return OutputVerificationErrorType.timeout;
    }

    if (lowercaseError.contains('not found') ||
        lowercaseError.contains('404')) {
      return OutputVerificationErrorType.notFound;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return OutputVerificationErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return OutputVerificationErrorType.validation;
    }

    return OutputVerificationErrorType.general;
  }
}
