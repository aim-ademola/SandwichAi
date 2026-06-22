// bloc/product_intake_bloc/bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/product_intake_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/product_intake_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/product_intake_model.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/product_intake_repo.dart';

class ProductIntakeBloc extends Bloc<ProductIntakeEvent, ProductIntakeState> {
  final ProductIntakeRepositoryInterface _repository;

  ProductIntakeBloc({required ProductIntakeRepositoryInterface repository})
    : _repository = repository,
      super(const ProductIntakeInitial()) {
    on<CreateProductIntake>(_onCreateProductIntake);
    on<LoadProductIntakes>(_onLoadProductIntakes);
    on<RefreshProductIntakes>(_onRefreshProductIntakes);
    on<SearchProductIntakes>(_onSearchProductIntakes);
    on<ClearProductIntakeSearch>(_onClearProductIntakeSearch);
    on<ResetProductIntakeState>(_onResetProductIntakeState);
  }

  Future<void> _onCreateProductIntake(
    CreateProductIntake event,
    Emitter<ProductIntakeState> emit,
  ) async {
    emit(const ProductIntakeCreating());

    final response = await _repository.createProductIntake(event.request);

    response.when(
      success: (intake) => emit(ProductIntakeCreated(intake: intake)),
      error: (error) => emit(
        ProductIntakeError(
          error: error.message,
          errorType: _determineErrorType(error.message),
        ),
      ),
    );
  }

  Future<void> _onLoadProductIntakes(
    LoadProductIntakes event,
    Emitter<ProductIntakeState> emit,
  ) async {
    try {
      emit(const ProductIntakeLoading());

      final response = await _repository.getProductIntakes();

      await response.when(
        success: (intakes) async {
          emit(
            ProductIntakeLoaded(
              intakes: intakes,
              filteredIntakes: intakes,
              searchQuery: '',
            ),
          );
        },
        error: (error) async {
          final errorMessage = error.message;
          final errorType = _determineErrorType(errorMessage);

          emit(ProductIntakeError(error: errorMessage, errorType: errorType));
        },
      );
    } catch (e) {
      emit(
        const ProductIntakeError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: ProductIntakeErrorType.general,
        ),
      );
    }
  }

  Future<void> _onRefreshProductIntakes(
    RefreshProductIntakes event,
    Emitter<ProductIntakeState> emit,
  ) async {
    if (state is! ProductIntakeLoaded) {
      add(LoadProductIntakes());
      return;
    }

    final currentState = state as ProductIntakeLoaded;
    emit(ProductIntakeRefreshing(currentData: currentState.intakes));

    final response = await _repository.getProductIntakes();

    await response.when(
      success: (intakes) async {
        final filteredIntakes = _filterIntakes(
          intakes,
          currentState.searchQuery,
        );

        emit(
          ProductIntakeLoaded(
            intakes: intakes,
            filteredIntakes: filteredIntakes,
            searchQuery: currentState.searchQuery,
          ),
        );
      },
      error: (error) async {
        final errorMessage = error.message;
        final errorType = _determineErrorType(errorMessage);

        emit(ProductIntakeError(error: errorMessage, errorType: errorType));
      },
    );
  }

  void _onSearchProductIntakes(
    SearchProductIntakes event,
    Emitter<ProductIntakeState> emit,
  ) {
    if (state is! ProductIntakeLoaded) return;

    final currentState = state as ProductIntakeLoaded;
    final filteredIntakes = _filterIntakes(currentState.intakes, event.query);

    emit(
      currentState.copyWith(
        searchQuery: event.query,
        filteredIntakes: filteredIntakes,
      ),
    );
  }

  void _onClearProductIntakeSearch(
    ClearProductIntakeSearch event,
    Emitter<ProductIntakeState> emit,
  ) {
    if (state is! ProductIntakeLoaded) return;

    final currentState = state as ProductIntakeLoaded;

    emit(
      currentState.copyWith(
        searchQuery: '',
        filteredIntakes: currentState.intakes,
      ),
    );
  }

  void _onResetProductIntakeState(
    ResetProductIntakeState event,
    Emitter<ProductIntakeState> emit,
  ) {
    emit(const ProductIntakeInitial());
  }

  List<ProductIntake> _filterIntakes(
    List<ProductIntake> intakes,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) {
      return intakes;
    }

    final query = searchQuery.toLowerCase();
    return intakes.where((intake) {
      return intake.productName.toLowerCase().contains(query) ||
          intake.stockBatchId.toLowerCase().contains(query) ||
          intake.issuedBy.toLowerCase().contains(query);
    }).toList();
  }

  ProductIntakeErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return ProductIntakeErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return ProductIntakeErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return ProductIntakeErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return ProductIntakeErrorType.validation;
    }

    return ProductIntakeErrorType.general;
  }
}
