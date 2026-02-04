// bloc/product_intake_bloc/state.dart

import 'package:sandwich_ai/src/features/processing/data/model/product_intake_model.dart';

abstract class ProductIntakeState {
  const ProductIntakeState();
}

class ProductIntakeInitial extends ProductIntakeState {
  const ProductIntakeInitial();
}

class ProductIntakeCreating extends ProductIntakeState {
  const ProductIntakeCreating();
}

class ProductIntakeCreated extends ProductIntakeState {
  final ProductIntake intake;

  const ProductIntakeCreated({required this.intake});
}

class ProductIntakeLoading extends ProductIntakeState {
  const ProductIntakeLoading();
}

class ProductIntakeRefreshing extends ProductIntakeState {
  final List<ProductIntake> currentData;

  const ProductIntakeRefreshing({required this.currentData});
}

class ProductIntakeLoaded extends ProductIntakeState {
  final List<ProductIntake> intakes;
  final List<ProductIntake> filteredIntakes;
  final String searchQuery;

  const ProductIntakeLoaded({
    required this.intakes,
    required this.filteredIntakes,
    required this.searchQuery,
  });

  ProductIntakeLoaded copyWith({
    List<ProductIntake>? intakes,
    List<ProductIntake>? filteredIntakes,
    String? searchQuery,
  }) {
    return ProductIntakeLoaded(
      intakes: intakes ?? this.intakes,
      filteredIntakes: filteredIntakes ?? this.filteredIntakes,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ProductIntakeError extends ProductIntakeState {
  final String error;
  final ProductIntakeErrorType errorType;

  const ProductIntakeError({
    required this.error,
    this.errorType = ProductIntakeErrorType.general,
  });
}

enum ProductIntakeErrorType { network, timeout, server, validation, general }
