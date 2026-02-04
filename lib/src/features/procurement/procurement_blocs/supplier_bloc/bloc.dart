import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/supplier_repo.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/state.dart';

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final SupplierRepositoryInterface _repository;

  SupplierBloc({required SupplierRepositoryInterface repository})
    : _repository = repository,
      super(const SupplierInitial()) {
    on<LoadSuppliers>(_onLoadSuppliers);
    on<RefreshSuppliers>(_onRefreshSuppliers);
    on<FilterSuppliers>(_onFilterSuppliers);
    on<SearchSuppliers>(_onSearchSuppliers);
    on<LoadSupplierProducts>(_onLoadSupplierProducts);
  }

  Future<void> _onLoadSuppliers(
    LoadSuppliers event,
    Emitter<SupplierState> emit,
  ) async {
    try {
      emit(const SupplierLoading());

      final response = await _repository.getSuppliers(
        status: event.status,
        supplierType: event.supplierType,
        search: event.search,
      );

      await response.when(
        success: (data) async {
          if (data.isEmpty) {
            emit(const SupplierEmpty());
            return;
          }

          emit(
            SupplierListLoaded(
              suppliers: data,
              currentFilter: event.status,
              currentSearch: event.search,
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(SupplierError(error: error.toString(), errorType: errorType));
        },
      );
    } catch (e) {
      emit(
        const SupplierError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: SupplierErrorType.general,
        ),
      );
    }
  }

  Future<void> _onRefreshSuppliers(
    RefreshSuppliers event,
    Emitter<SupplierState> emit,
  ) async {
    if (state is! SupplierListLoaded) {
      add(
        LoadSuppliers(
          status: event.status,
          supplierType: event.supplierType,
          search: event.search,
        ),
      );
      return;
    }

    final currentState = state as SupplierListLoaded;
    emit(SupplierRefreshing(currentSuppliers: currentState.suppliers));

    final response = await _repository.getSuppliers(
      status: event.status,
      supplierType: event.supplierType,
      search: event.search,
    );

    await response.when(
      success: (data) async {
        if (data.isEmpty) {
          emit(const SupplierEmpty());
          return;
        }

        emit(
          SupplierListLoaded(
            suppliers: data,
            currentFilter: event.status,
            currentSearch: event.search,
          ),
        );
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(SupplierError(error: error.toString(), errorType: errorType));
      },
    );
  }

  void _onFilterSuppliers(FilterSuppliers event, Emitter<SupplierState> emit) {
    add(LoadSuppliers(status: event.status, supplierType: event.supplierType));
  }

  void _onSearchSuppliers(SearchSuppliers event, Emitter<SupplierState> emit) {
    add(LoadSuppliers(search: event.query));
  }

  Future<void> _onLoadSupplierProducts(
    LoadSupplierProducts event,
    Emitter<SupplierState> emit,
  ) async {
    try {
      emit(const SupplierLoading());

      final response = await _repository.getSupplierProducts(
        supplierId: event.supplierId,
        category: event.category,
        status: event.status,
      );

      await response.when(
        success: (data) async {
          if (data.isEmpty) {
            emit(const SupplierEmpty());
            return;
          }

          emit(
            SupplierProductsLoaded(
              products: data,
              supplierId: event.supplierId,
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(SupplierError(error: error.toString(), errorType: errorType));
        },
      );
    } catch (e) {
      emit(
        const SupplierError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: SupplierErrorType.general,
        ),
      );
    }
  }

  SupplierErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return SupplierErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return SupplierErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return SupplierErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return SupplierErrorType.validation;
    }

    return SupplierErrorType.general;
  }
}
