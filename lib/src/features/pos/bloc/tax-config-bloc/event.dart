part of 'bloc.dart';

abstract class TaxConfigEvent extends Equatable {
  const TaxConfigEvent();

  @override
  List<Object?> get props => [];
}

class LoadTaxConfigurations extends TaxConfigEvent {
  const LoadTaxConfigurations();
}

class RefreshTaxConfigurations extends TaxConfigEvent {
  const RefreshTaxConfigurations();
}
