// bloc/tax_config_bloc/bloc.dart

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/pos/data/model/tax_config_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/tax-config_repo.dart';

part 'event.dart';
part 'state.dart';

class TaxConfigBloc extends Bloc<TaxConfigEvent, TaxConfigState> {
  final TaxConfigRepositoryInterface _repository;

  TaxConfigBloc({required TaxConfigRepositoryInterface repository})
    : _repository = repository,
      super(const TaxConfigInitial()) {
    on<LoadTaxConfigurations>(_onLoadTaxConfigurations);
    on<RefreshTaxConfigurations>(_onRefreshTaxConfigurations);
    add(LoadTaxConfigurations());
  }

  Future<void> _onLoadTaxConfigurations(
    LoadTaxConfigurations event,
    Emitter<TaxConfigState> emit,
  ) async {
    emit(const TaxConfigLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefreshTaxConfigurations(
    RefreshTaxConfigurations event,
    Emitter<TaxConfigState> emit,
  ) async {
    // Keep showing existing data while refreshing (no loading flash).
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<TaxConfigState> emit) async {
    final response = await _repository.getActiveTaxConfigurations();

    await response.when(
      success: (taxes) async {
        if (taxes.isEmpty) {
          emit(const TaxConfigEmpty());
          return;
        }

        final salesTaxes = taxes.where((t) => t.isApplicableToSales).toList();

        emit(TaxConfigLoaded(taxes: taxes, salesTaxes: salesTaxes));
      },
      error: (error) async {
        emit(TaxConfigError(error: error.toString()));
      },
    );
  }
}
