import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_good_recieved_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/reorder_model.dart';

enum GoodsReceivedAdvancedStatus { initial, loading, loaded, empty, error }

class GoodsReceivedAdvancedState extends Equatable {
  final GoodsReceivedAdvancedStatus statsStatus;
  final GoodsReceivedAdvancedStatus reorderStatus;
  final GoodsReceivedAdvancedStatus detailStatus;
  final GoodsReceivedAdvancedStatus prefillStatus;
  final GoodsReceivedAdvancedStatus poReceiptsStatus;
  final GoodsReceivedQcStats? qcStats;
  final ReorderSuggestionsResponse? reorderSuggestions;
  final GoodsReceived? detail;
  final GoodsReceivedPrefillResponse? prefill;
  final List<GoodsReceived> poReceipts;
  final PurchaseOrderDeliveryStatusResponse? deliveryStatus;
  final String? statsError;
  final String? reorderError;
  final String? detailError;
  final String? prefillError;
  final String? poReceiptsError;

  const GoodsReceivedAdvancedState({
    this.statsStatus = GoodsReceivedAdvancedStatus.initial,
    this.reorderStatus = GoodsReceivedAdvancedStatus.initial,
    this.detailStatus = GoodsReceivedAdvancedStatus.initial,
    this.prefillStatus = GoodsReceivedAdvancedStatus.initial,
    this.poReceiptsStatus = GoodsReceivedAdvancedStatus.initial,
    this.qcStats,
    this.reorderSuggestions,
    this.detail,
    this.prefill,
    this.poReceipts = const [],
    this.deliveryStatus,
    this.statsError,
    this.reorderError,
    this.detailError,
    this.prefillError,
    this.poReceiptsError,
  });

  GoodsReceivedAdvancedState copyWith({
    GoodsReceivedAdvancedStatus? statsStatus,
    GoodsReceivedAdvancedStatus? reorderStatus,
    GoodsReceivedAdvancedStatus? detailStatus,
    GoodsReceivedAdvancedStatus? prefillStatus,
    GoodsReceivedAdvancedStatus? poReceiptsStatus,
    GoodsReceivedQcStats? qcStats,
    ReorderSuggestionsResponse? reorderSuggestions,
    GoodsReceived? detail,
    GoodsReceivedPrefillResponse? prefill,
    List<GoodsReceived>? poReceipts,
    PurchaseOrderDeliveryStatusResponse? deliveryStatus,
    String? statsError,
    String? reorderError,
    String? detailError,
    String? prefillError,
    String? poReceiptsError,
    bool clearStatsError = false,
    bool clearReorderError = false,
    bool clearDetailError = false,
    bool clearPrefillError = false,
    bool clearPoReceiptsError = false,
  }) {
    return GoodsReceivedAdvancedState(
      statsStatus: statsStatus ?? this.statsStatus,
      reorderStatus: reorderStatus ?? this.reorderStatus,
      detailStatus: detailStatus ?? this.detailStatus,
      prefillStatus: prefillStatus ?? this.prefillStatus,
      poReceiptsStatus: poReceiptsStatus ?? this.poReceiptsStatus,
      qcStats: qcStats ?? this.qcStats,
      reorderSuggestions: reorderSuggestions ?? this.reorderSuggestions,
      detail: detail ?? this.detail,
      prefill: prefill ?? this.prefill,
      poReceipts: poReceipts ?? this.poReceipts,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      statsError: clearStatsError ? null : (statsError ?? this.statsError),
      reorderError: clearReorderError
          ? null
          : (reorderError ?? this.reorderError),
      detailError: clearDetailError ? null : (detailError ?? this.detailError),
      prefillError: clearPrefillError
          ? null
          : (prefillError ?? this.prefillError),
      poReceiptsError: clearPoReceiptsError
          ? null
          : (poReceiptsError ?? this.poReceiptsError),
    );
  }

  @override
  List<Object?> get props => [
    statsStatus,
    reorderStatus,
    detailStatus,
    prefillStatus,
    poReceiptsStatus,
    qcStats,
    reorderSuggestions,
    detail,
    prefill,
    poReceipts,
    deliveryStatus,
    statsError,
    reorderError,
    detailError,
    prefillError,
    poReceiptsError,
  ];
}
