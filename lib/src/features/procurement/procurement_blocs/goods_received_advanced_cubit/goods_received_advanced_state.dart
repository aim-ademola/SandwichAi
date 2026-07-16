import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_good_recieved_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/reorder_model.dart';

enum GoodsReceivedAdvancedStatus { initial, loading, loaded, empty, error }

class GoodsReceivedAdvancedState extends Equatable {
  final GoodsReceivedAdvancedStatus statsStatus;
  final GoodsReceivedAdvancedStatus reorderStatus;
  final GoodsReceivedAdvancedStatus detailStatus;
  final GoodsReceivedAdvancedStatus prefillStatus;
  final GoodsReceivedQcStats? qcStats;
  final ReorderSuggestionsResponse? reorderSuggestions;
  final GoodsReceived? detail;
  final GoodsReceivedPrefillResponse? prefill;
  final PurchaseOrderDeliveryStatusResponse? deliveryStatus;
  final String? statsError;
  final String? reorderError;
  final String? detailError;
  final String? prefillError;

  const GoodsReceivedAdvancedState({
    this.statsStatus = GoodsReceivedAdvancedStatus.initial,
    this.reorderStatus = GoodsReceivedAdvancedStatus.initial,
    this.detailStatus = GoodsReceivedAdvancedStatus.initial,
    this.prefillStatus = GoodsReceivedAdvancedStatus.initial,
    this.qcStats,
    this.reorderSuggestions,
    this.detail,
    this.prefill,
    this.deliveryStatus,
    this.statsError,
    this.reorderError,
    this.detailError,
    this.prefillError,
  });

  GoodsReceivedAdvancedState copyWith({
    GoodsReceivedAdvancedStatus? statsStatus,
    GoodsReceivedAdvancedStatus? reorderStatus,
    GoodsReceivedAdvancedStatus? detailStatus,
    GoodsReceivedAdvancedStatus? prefillStatus,
    GoodsReceivedQcStats? qcStats,
    ReorderSuggestionsResponse? reorderSuggestions,
    GoodsReceived? detail,
    GoodsReceivedPrefillResponse? prefill,
    PurchaseOrderDeliveryStatusResponse? deliveryStatus,
    String? statsError,
    String? reorderError,
    String? detailError,
    String? prefillError,
    bool clearStatsError = false,
    bool clearReorderError = false,
    bool clearDetailError = false,
    bool clearPrefillError = false,
  }) {
    return GoodsReceivedAdvancedState(
      statsStatus: statsStatus ?? this.statsStatus,
      reorderStatus: reorderStatus ?? this.reorderStatus,
      detailStatus: detailStatus ?? this.detailStatus,
      prefillStatus: prefillStatus ?? this.prefillStatus,
      qcStats: qcStats ?? this.qcStats,
      reorderSuggestions: reorderSuggestions ?? this.reorderSuggestions,
      detail: detail ?? this.detail,
      prefill: prefill ?? this.prefill,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      statsError: clearStatsError ? null : (statsError ?? this.statsError),
      reorderError: clearReorderError
          ? null
          : (reorderError ?? this.reorderError),
      detailError: clearDetailError ? null : (detailError ?? this.detailError),
      prefillError: clearPrefillError
          ? null
          : (prefillError ?? this.prefillError),
    );
  }

  @override
  List<Object?> get props => [
    statsStatus,
    reorderStatus,
    detailStatus,
    prefillStatus,
    qcStats,
    reorderSuggestions,
    detail,
    prefill,
    deliveryStatus,
    statsError,
    reorderError,
    detailError,
    prefillError,
  ];
}
