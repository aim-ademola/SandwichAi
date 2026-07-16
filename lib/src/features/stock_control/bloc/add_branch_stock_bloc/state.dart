import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/add_branchstock.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/add_branch_stock.dart';

enum BranchStockErrorType { network, timeout, server, validation, general }

abstract class BranchStockState extends Equatable {
  const BranchStockState();

  @override
  List<Object?> get props => [];
}

class BranchStockInitial extends BranchStockState {
  final String? currentStockError;
  final String? reorderLevelError;
  final String? maxLevelError;
  final String? unitCostError;
  final String? expiryDateError;
  final String? adjustmentQuantityError;

  const BranchStockInitial({
    this.currentStockError,
    this.reorderLevelError,
    this.maxLevelError,
    this.unitCostError,
    this.expiryDateError,
    this.adjustmentQuantityError,
  });

  BranchStockInitial copyWith({
    String? currentStockError,
    String? reorderLevelError,
    String? maxLevelError,
    String? unitCostError,
    String? expiryDateError,
    String? adjustmentQuantityError,
    bool clearCurrentStockError = false,
    bool clearReorderLevelError = false,
    bool clearMaxLevelError = false,
    bool clearUnitCostError = false,
    bool clearExpiryDateError = false,
    bool clearAdjustmentQuantityError = false,
  }) {
    return BranchStockInitial(
      currentStockError: clearCurrentStockError
          ? null
          : (currentStockError ?? this.currentStockError),
      reorderLevelError: clearReorderLevelError
          ? null
          : (reorderLevelError ?? this.reorderLevelError),
      maxLevelError: clearMaxLevelError
          ? null
          : (maxLevelError ?? this.maxLevelError),
      unitCostError: clearUnitCostError
          ? null
          : (unitCostError ?? this.unitCostError),
      expiryDateError: clearExpiryDateError
          ? null
          : (expiryDateError ?? this.expiryDateError),
      adjustmentQuantityError: clearAdjustmentQuantityError
          ? null
          : (adjustmentQuantityError ?? this.adjustmentQuantityError),
    );
  }

  @override
  List<Object?> get props => [
    currentStockError,
    reorderLevelError,
    maxLevelError,
    unitCostError,
    expiryDateError,
    adjustmentQuantityError,
  ];
}

class BranchStockLoading extends BranchStockState {
  const BranchStockLoading();
}

class BranchStockValidation extends BranchStockState {
  final String? currentStockError;
  final String? reorderLevelError;
  final String? maxLevelError;
  final String? unitCostError;
  final String? expiryDateError;
  final String? adjustmentQuantityError;

  const BranchStockValidation({
    this.currentStockError,
    this.reorderLevelError,
    this.maxLevelError,
    this.unitCostError,
    this.expiryDateError,
    this.adjustmentQuantityError,
  });

  bool get hasErrors =>
      currentStockError != null ||
      reorderLevelError != null ||
      maxLevelError != null ||
      unitCostError != null ||
      expiryDateError != null ||
      adjustmentQuantityError != null;

  @override
  List<Object?> get props => [
    currentStockError,
    reorderLevelError,
    maxLevelError,
    unitCostError,
    expiryDateError,
    adjustmentQuantityError,
  ];
}

class BranchStockSuccess extends BranchStockState {
  final BranchStockResponse? response;
  final StockAdjustmentResponse? adjustmentResponse;
  final String message;
  final bool isUpdate;
  final bool isDelete;
  final bool isAdjustment;
  final bool isControlAction;

  const BranchStockSuccess({
    this.response,
    this.adjustmentResponse,
    required this.message,
    this.isUpdate = false,
    this.isDelete = false,
    this.isAdjustment = false,
    this.isControlAction = false,
  });

  @override
  List<Object?> get props => [
    response,
    adjustmentResponse,
    message,
    isUpdate,
    isDelete,
    isAdjustment,
    isControlAction,
  ];
}

class BranchStockError extends BranchStockState {
  final String error;
  final BranchStockErrorType errorType;

  const BranchStockError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}

class BranchStockDeleteConfirmation extends BranchStockState {
  final String stockId;
  final String itemName;

  const BranchStockDeleteConfirmation({
    required this.stockId,
    required this.itemName,
  });

  @override
  List<Object?> get props => [stockId, itemName];
}
