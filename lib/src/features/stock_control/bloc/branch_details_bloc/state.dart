import 'package:sandwich_ai/src/features/stock_control/data/model/branch_details_model.dart';

abstract class BranchStockDetailsState {
  const BranchStockDetailsState();
}

class BranchStockDetailsInitial extends BranchStockDetailsState {
  const BranchStockDetailsInitial();
}

class BranchStockDetailsLoading extends BranchStockDetailsState {
  const BranchStockDetailsLoading();
}

class BranchStockDetailsLoaded extends BranchStockDetailsState {
  final BranchStockDetails details;

  const BranchStockDetailsLoaded({required this.details});
}

class BranchStockDetailsRefreshing extends BranchStockDetailsState {
  final BranchStockDetails currentDetails;

  const BranchStockDetailsRefreshing({required this.currentDetails});
}

class BranchStockDetailsError extends BranchStockDetailsState {
  final String error;
  final BranchStockDetailsErrorType errorType;

  const BranchStockDetailsError({
    required this.error,
    this.errorType = BranchStockDetailsErrorType.general,
  });
}

enum BranchStockDetailsErrorType {
  network,
  timeout,
  server,
  notFound,
  validation,
  general,
}
