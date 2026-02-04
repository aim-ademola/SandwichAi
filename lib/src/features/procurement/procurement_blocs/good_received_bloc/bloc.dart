import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_good_received_repo.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/good_received_bloc/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/good_received_bloc/state.dart';

class GoodsReceivedBloc extends Bloc<GoodsReceivedEvent, GoodsReceivedState> {
  final GoodsReceivedRepositoryInterface _repository;
  String branchId = '';

  GoodsReceivedBloc({required GoodsReceivedRepositoryInterface repository})
    : _repository = repository,
      super(const GoodsReceivedInitial()) {
    _getBranchId();
    on<LoadInventoryItems>(_onLoadInventoryItems);
    on<CreateGoodsReceived>(_onCreateGoodsReceived);
    on<LoadGoodsReceived>(_onLoadGoodsReceived);
    on<ResetGoodsReceived>(_onResetGoodsReceived);
  }
  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getOrgId() ?? '';
    branchId = id;
  }

  Future<void> _onLoadInventoryItems(
    LoadInventoryItems event,
    Emitter<GoodsReceivedState> emit,
  ) async {
    try {
      emit(const GoodsReceivedLoading());

      final response = await _repository.getInventoryItems(
        organizationId: branchId,
      );

      await response.when(
        success: (data) async {
          emit(InventoryItemsLoaded(items: data));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            GoodsReceivedError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const GoodsReceivedError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: GoodsReceivedErrorType.general,
        ),
      );
    }
  }

  Future<void> _onCreateGoodsReceived(
    CreateGoodsReceived event,
    Emitter<GoodsReceivedState> emit,
  ) async {
    try {
      emit(const GoodsReceivedSubmitting());

      final response = await _repository.createGoodsReceived(
        request: event.request,
      );

      await response.when(
        success: (data) async {
          emit(
            GoodsReceivedSuccess(
              receipt: data,
              message: 'Goods received logged successfully!',
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            GoodsReceivedError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const GoodsReceivedError(
          error: 'Failed to log goods received. Please try again.',
          errorType: GoodsReceivedErrorType.general,
        ),
      );
    }
  }

  Future<void> _onLoadGoodsReceived(
    LoadGoodsReceived event,
    Emitter<GoodsReceivedState> emit,
  ) async {
    try {
      emit(const GoodsReceivedLoading());

      final response = await _repository.getGoodsReceived(
        branchId: event.branchId,
      );

      await response.when(
        success: (data) async {
          emit(GoodsReceivedListLoaded(receipts: data));
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            GoodsReceivedError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const GoodsReceivedError(
          error: 'Failed to load goods received. Please try again.',
          errorType: GoodsReceivedErrorType.general,
        ),
      );
    }
  }

  void _onResetGoodsReceived(
    ResetGoodsReceived event,
    Emitter<GoodsReceivedState> emit,
  ) {
    emit(const GoodsReceivedInitial());
  }

  GoodsReceivedErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return GoodsReceivedErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return GoodsReceivedErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return GoodsReceivedErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return GoodsReceivedErrorType.validation;
    }

    return GoodsReceivedErrorType.general;
  }
}
