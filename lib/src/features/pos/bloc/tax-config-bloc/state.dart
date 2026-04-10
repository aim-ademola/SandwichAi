part of 'bloc.dart';

abstract class TaxConfigState extends Equatable {
  const TaxConfigState();

  @override
  List<Object?> get props => [];
}

class TaxConfigInitial extends TaxConfigState {
  const TaxConfigInitial();
}

class TaxConfigLoading extends TaxConfigState {
  const TaxConfigLoading();
}

class TaxConfigLoaded extends TaxConfigState {
  /// All active tax configurations returned by the API.
  final List<TaxConfiguration> taxes;

  /// Subset of [taxes] that are applicable to sales orders right now.
  final List<TaxConfiguration> salesTaxes;

  const TaxConfigLoaded({required this.taxes, required this.salesTaxes});

  @override
  List<Object?> get props => [taxes, salesTaxes];
}

class TaxConfigEmpty extends TaxConfigState {
  const TaxConfigEmpty();
}

class TaxConfigError extends TaxConfigState {
  final String error;

  const TaxConfigError({required this.error});

  @override
  List<Object?> get props => [error];
}
