import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/add_branchstock.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/add_branch_stock.dart';

abstract class BranchStockEvent extends Equatable {
  const BranchStockEvent();

  @override
  List<Object?> get props => [];
}

class CreateBranchStock extends BranchStockEvent {
  final BranchStockRequest request;

  const CreateBranchStock({required this.request});

  @override
  List<Object?> get props => [request];
}

class UpdateBranchStock extends BranchStockEvent {
  final String stockId;
  final BranchStockRequest request;

  const UpdateBranchStock({required this.stockId, required this.request});

  @override
  List<Object?> get props => [stockId, request];
}

class DeleteBranchStock extends BranchStockEvent {
  final String stockId;
  final String itemName;

  const DeleteBranchStock({required this.stockId, required this.itemName});

  @override
  List<Object?> get props => [stockId, itemName];
}

class AdjustBranchStock extends BranchStockEvent {
  final String stockId;
  final StockAdjustmentRequest request;

  const AdjustBranchStock({required this.stockId, required this.request});

  @override
  List<Object?> get props => [stockId, request];
}

class AllowNegativeBranchStock extends BranchStockEvent {
  final String stockId;
  final bool allow;

  const AllowNegativeBranchStock({required this.stockId, this.allow = true});

  @override
  List<Object?> get props => [stockId, allow];
}

class LockBranchStock extends BranchStockEvent {
  final String stockId;
  final String reason;

  const LockBranchStock({required this.stockId, required this.reason});

  @override
  List<Object?> get props => [stockId, reason];
}

class UnlockBranchStock extends BranchStockEvent {
  final String stockId;

  const UnlockBranchStock({required this.stockId});

  @override
  List<Object?> get props => [stockId];
}

class ValidateCurrentStock extends BranchStockEvent {
  final String value;

  const ValidateCurrentStock({required this.value});

  @override
  List<Object?> get props => [value];
}

class ValidateReorderLevel extends BranchStockEvent {
  final String value;

  const ValidateReorderLevel({required this.value});

  @override
  List<Object?> get props => [value];
}

class ValidateMaxLevel extends BranchStockEvent {
  final String value;

  const ValidateMaxLevel({required this.value});

  @override
  List<Object?> get props => [value];
}

class ValidateUnitCost extends BranchStockEvent {
  final String value;

  const ValidateUnitCost({required this.value});

  @override
  List<Object?> get props => [value];
}

class ValidateExpiryDate extends BranchStockEvent {
  final String value;

  const ValidateExpiryDate({required this.value});

  @override
  List<Object?> get props => [value];
}

class ValidateAdjustmentQuantity extends BranchStockEvent {
  final String value;

  const ValidateAdjustmentQuantity({required this.value});

  @override
  List<Object?> get props => [value];
}

class ResetBranchStockState extends BranchStockEvent {
  const ResetBranchStockState();
}
