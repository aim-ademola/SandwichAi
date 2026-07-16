import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/reorder_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/stock_card_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/add_branch_stock.dart';

enum StockControlReportStatus { initial, loading, loaded, empty, error }

class StockControlReportsState extends Equatable {
  final StockControlReportStatus expiryStatus;
  final StockControlReportStatus lockedStatus;
  final StockControlReportStatus negativeStatus;
  final StockControlReportStatus reorderStatus;
  final StockControlReportStatus movementStatus;
  final StockExpiryReport? expiryReport;
  final StockExpirySummary? expirySummary;
  final BranchStockControlListResponse? lockedStock;
  final BranchStockControlListResponse? negativeStockReport;
  final ReorderReportResponse? reorderReport;
  final StockMovementTrendsResponse? movementTrends;
  final String? expiryError;
  final String? lockedError;
  final String? negativeError;
  final String? reorderError;
  final String? movementError;

  const StockControlReportsState({
    this.expiryStatus = StockControlReportStatus.initial,
    this.lockedStatus = StockControlReportStatus.initial,
    this.negativeStatus = StockControlReportStatus.initial,
    this.reorderStatus = StockControlReportStatus.initial,
    this.movementStatus = StockControlReportStatus.initial,
    this.expiryReport,
    this.expirySummary,
    this.lockedStock,
    this.negativeStockReport,
    this.reorderReport,
    this.movementTrends,
    this.expiryError,
    this.lockedError,
    this.negativeError,
    this.reorderError,
    this.movementError,
  });

  StockControlReportsState copyWith({
    StockControlReportStatus? expiryStatus,
    StockControlReportStatus? lockedStatus,
    StockControlReportStatus? negativeStatus,
    StockControlReportStatus? reorderStatus,
    StockControlReportStatus? movementStatus,
    StockExpiryReport? expiryReport,
    StockExpirySummary? expirySummary,
    BranchStockControlListResponse? lockedStock,
    BranchStockControlListResponse? negativeStockReport,
    ReorderReportResponse? reorderReport,
    StockMovementTrendsResponse? movementTrends,
    String? expiryError,
    String? lockedError,
    String? negativeError,
    String? reorderError,
    String? movementError,
    bool clearExpiryError = false,
    bool clearLockedError = false,
    bool clearNegativeError = false,
    bool clearReorderError = false,
    bool clearMovementError = false,
  }) {
    return StockControlReportsState(
      expiryStatus: expiryStatus ?? this.expiryStatus,
      lockedStatus: lockedStatus ?? this.lockedStatus,
      negativeStatus: negativeStatus ?? this.negativeStatus,
      reorderStatus: reorderStatus ?? this.reorderStatus,
      movementStatus: movementStatus ?? this.movementStatus,
      expiryReport: expiryReport ?? this.expiryReport,
      expirySummary: expirySummary ?? this.expirySummary,
      lockedStock: lockedStock ?? this.lockedStock,
      negativeStockReport: negativeStockReport ?? this.negativeStockReport,
      reorderReport: reorderReport ?? this.reorderReport,
      movementTrends: movementTrends ?? this.movementTrends,
      expiryError: clearExpiryError ? null : (expiryError ?? this.expiryError),
      lockedError: clearLockedError ? null : (lockedError ?? this.lockedError),
      negativeError: clearNegativeError
          ? null
          : (negativeError ?? this.negativeError),
      reorderError: clearReorderError
          ? null
          : (reorderError ?? this.reorderError),
      movementError: clearMovementError
          ? null
          : (movementError ?? this.movementError),
    );
  }

  @override
  List<Object?> get props => [
    expiryStatus,
    lockedStatus,
    negativeStatus,
    reorderStatus,
    movementStatus,
    expiryReport,
    expirySummary,
    lockedStock,
    negativeStockReport,
    reorderReport,
    movementTrends,
    expiryError,
    lockedError,
    negativeError,
    reorderError,
    movementError,
  ];
}
