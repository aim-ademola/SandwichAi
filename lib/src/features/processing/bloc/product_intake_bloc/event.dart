import 'package:sandwich_ai/src/features/processing/data/model/product_intake_model.dart';

abstract class ProductIntakeEvent {}

class CreateProductIntake extends ProductIntakeEvent {
  final CreateProductIntakeRequest request;

  CreateProductIntake({required this.request});
}

class LoadProductIntakes extends ProductIntakeEvent {}

class RefreshProductIntakes extends ProductIntakeEvent {}

class SearchProductIntakes extends ProductIntakeEvent {
  final String query;

  SearchProductIntakes({required this.query});
}

class ClearProductIntakeSearch extends ProductIntakeEvent {}

class ResetProductIntakeState extends ProductIntakeEvent {}
