import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_good_recieved_model.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_good_received_repo.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/goods_received_advanced_cubit/goods_received_advanced_state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/reorder_repo.dart';

class GoodsReceivedAdvancedCubit extends Cubit<GoodsReceivedAdvancedState> {
  final GoodsReceivedRepositoryInterface _goodsReceivedRepository;
  final ReorderRepositoryInterface _reorderRepository;

  GoodsReceivedAdvancedCubit({
    required GoodsReceivedRepositoryInterface goodsReceivedRepository,
    required ReorderRepositoryInterface reorderRepository,
  }) : _goodsReceivedRepository = goodsReceivedRepository,
       _reorderRepository = reorderRepository,
       super(const GoodsReceivedAdvancedState());

  Future<void> loadOverview({String? branchId}) async {
    await Future.wait([
      loadQcStats(),
      loadReorderSuggestions(branchId: branchId),
    ]);
  }

  Future<void> loadQcStats() async {
    emit(
      state.copyWith(
        statsStatus: GoodsReceivedAdvancedStatus.loading,
        clearStatsError: true,
      ),
    );
    final response = await _goodsReceivedRepository.getGoodsReceivedQcStats();
    response.when(
      success: (data) => emit(
        state.copyWith(
          statsStatus: GoodsReceivedAdvancedStatus.loaded,
          qcStats: data,
        ),
      ),
      error: (error) => emit(
        state.copyWith(
          statsStatus: GoodsReceivedAdvancedStatus.error,
          statsError: error.toString(),
        ),
      ),
    );
  }

  Future<void> loadReorderSuggestions({String? branchId}) async {
    emit(
      state.copyWith(
        reorderStatus: GoodsReceivedAdvancedStatus.loading,
        clearReorderError: true,
      ),
    );
    final response = await _reorderRepository.getReorderSuggestions(
      branchId: branchId,
    );
    response.when(
      success: (data) => emit(
        state.copyWith(
          reorderStatus: data.suggestions.isEmpty
              ? GoodsReceivedAdvancedStatus.empty
              : GoodsReceivedAdvancedStatus.loaded,
          reorderSuggestions: data,
        ),
      ),
      error: (error) => emit(
        state.copyWith(
          reorderStatus: GoodsReceivedAdvancedStatus.error,
          reorderError: error.toString(),
        ),
      ),
    );
  }

  Future<void> loadDetail(String id) async {
    emit(
      state.copyWith(
        detailStatus: GoodsReceivedAdvancedStatus.loading,
        clearDetailError: true,
      ),
    );
    final response = await _goodsReceivedRepository.getGoodsReceivedById(id);
    response.when(
      success: (data) => emit(
        state.copyWith(
          detailStatus: GoodsReceivedAdvancedStatus.loaded,
          detail: data,
        ),
      ),
      error: (error) => emit(
        state.copyWith(
          detailStatus: GoodsReceivedAdvancedStatus.error,
          detailError: error.toString(),
        ),
      ),
    );
  }

  Future<bool> updateQc({
    required String id,
    required UpdateGoodsReceivedQcRequest request,
  }) async {
    final response = await _goodsReceivedRepository.updateGoodsReceivedQc(
      id: id,
      request: request,
    );
    if (response.isSuccess) {
      await loadDetail(id);
    }
    return response.isSuccess;
  }

  Future<void> loadPoPrefill(String poId) async {
    emit(
      state.copyWith(
        prefillStatus: GoodsReceivedAdvancedStatus.loading,
        clearPrefillError: true,
      ),
    );
    final prefillResponse = await _goodsReceivedRepository
        .getGoodsReceivedPrefill(poId);
    final statusResponse = await _goodsReceivedRepository
        .getPurchaseOrderDeliveryStatus(poId);
    final receiptsResponse = await _goodsReceivedRepository
        .getGoodsReceivedByPurchaseOrder(poId);

    if (prefillResponse.isSuccess && prefillResponse.data != null) {
      emit(
        state.copyWith(
          prefillStatus: GoodsReceivedAdvancedStatus.loaded,
          poReceiptsStatus:
              receiptsResponse.data == null || receiptsResponse.data!.isEmpty
              ? GoodsReceivedAdvancedStatus.empty
              : GoodsReceivedAdvancedStatus.loaded,
          prefill: prefillResponse.data,
          deliveryStatus: statusResponse.data,
          poReceipts: receiptsResponse.data ?? const [],
          poReceiptsError: receiptsResponse.error?.toString(),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        prefillStatus: GoodsReceivedAdvancedStatus.error,
        poReceiptsStatus: receiptsResponse.isSuccess
            ? GoodsReceivedAdvancedStatus.empty
            : GoodsReceivedAdvancedStatus.error,
        poReceipts: receiptsResponse.data ?? const [],
        poReceiptsError: receiptsResponse.error?.toString(),
        prefillError:
            prefillResponse.error?.toString() ??
            statusResponse.error?.toString() ??
            'Failed to load purchase order prefill.',
      ),
    );
  }

  Future<bool> markPurchaseOrderComplete(String poId) async {
    final response = await _goodsReceivedRepository.markPurchaseOrderComplete(
      poId,
    );
    if (response.isSuccess) {
      await loadPoPrefill(poId);
    }
    return response.isSuccess;
  }

  Future<void> loadGoodsReceivedByPurchaseOrder(String poId) async {
    emit(
      state.copyWith(
        poReceiptsStatus: GoodsReceivedAdvancedStatus.loading,
        clearPoReceiptsError: true,
      ),
    );
    final response = await _goodsReceivedRepository
        .getGoodsReceivedByPurchaseOrder(poId);
    response.when(
      success: (data) => emit(
        state.copyWith(
          poReceiptsStatus: data.isEmpty
              ? GoodsReceivedAdvancedStatus.empty
              : GoodsReceivedAdvancedStatus.loaded,
          poReceipts: data,
        ),
      ),
      error: (error) => emit(
        state.copyWith(
          poReceiptsStatus: GoodsReceivedAdvancedStatus.error,
          poReceiptsError: error.toString(),
        ),
      ),
    );
  }
}
