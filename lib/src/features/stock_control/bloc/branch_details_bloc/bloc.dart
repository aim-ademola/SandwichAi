import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_details_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_details_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/branch_details_repo.dart';

class BranchStockDetailsBloc
    extends Bloc<BranchStockDetailsEvent, BranchStockDetailsState> {
  final BranchStockDetailsRepositoryInterface _repository;

  BranchStockDetailsBloc({
    required BranchStockDetailsRepositoryInterface repository,
  }) : _repository = repository,
       super(const BranchStockDetailsInitial()) {
    on<LoadBranchStockDetails>(_onLoadBranchStockDetails);
    on<RefreshBranchStockDetails>(_onRefreshBranchStockDetails);
  }

  /// Load branch stock details
  Future<void> _onLoadBranchStockDetails(
    LoadBranchStockDetails event,
    Emitter<BranchStockDetailsState> emit,
  ) async {
    try {
      emit(const BranchStockDetailsLoading());

      final response = await _repository.getBranchStockDetails(event.stockId);

      await response.when(
        success: (data) async {
          emit(BranchStockDetailsLoaded(details: data));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            BranchStockDetailsError(
              error: error.toString(),
              errorType: errorType,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        const BranchStockDetailsError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: BranchStockDetailsErrorType.general,
        ),
      );
    }
  }

  /// Refresh branch stock details
  Future<void> _onRefreshBranchStockDetails(
    RefreshBranchStockDetails event,
    Emitter<BranchStockDetailsState> emit,
  ) async {
    if (state is! BranchStockDetailsLoaded) {
      add(LoadBranchStockDetails(stockId: event.stockId));
      return;
    }

    final currentState = state as BranchStockDetailsLoaded;
    emit(BranchStockDetailsRefreshing(currentDetails: currentState.details));

    final response = await _repository.getBranchStockDetails(event.stockId);

    await response.when(
      success: (data) async {
        emit(BranchStockDetailsLoaded(details: data));
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(
          BranchStockDetailsError(
            error: error.toString(),
            errorType: errorType,
          ),
        );
      },
    );
  }

  /// Determine error type from error message
  BranchStockDetailsErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return BranchStockDetailsErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return BranchStockDetailsErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return BranchStockDetailsErrorType.server;
    }

    if (lowercaseError.contains('not found') ||
        lowercaseError.contains('404')) {
      return BranchStockDetailsErrorType.notFound;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return BranchStockDetailsErrorType.validation;
    }

    return BranchStockDetailsErrorType.general;
  }
}
