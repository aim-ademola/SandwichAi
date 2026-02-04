// bloc/goods_received_bloc/state.dart

import 'package:sandwich_ai/src/features/procurement/data/model/procurement_good_recieved_model.dart';

enum GoodsReceivedErrorType { network, timeout, server, validation, general }

abstract class GoodsReceivedState {
  const GoodsReceivedState();
}

class GoodsReceivedInitial extends GoodsReceivedState {
  const GoodsReceivedInitial();
}

class GoodsReceivedLoading extends GoodsReceivedState {
  const GoodsReceivedLoading();
}

class GoodsReceivedSubmitting extends GoodsReceivedState {
  const GoodsReceivedSubmitting();
}

class InventoryItemsLoaded extends GoodsReceivedState {
  final List<InventoryItem> items;

  const InventoryItemsLoaded({required this.items});
}

class GoodsReceivedListLoaded extends GoodsReceivedState {
  final List<GoodsReceived> receipts;

  const GoodsReceivedListLoaded({required this.receipts});
}

class GoodsReceivedSuccess extends GoodsReceivedState {
  final GoodsReceived receipt;
  final String message;

  const GoodsReceivedSuccess({required this.receipt, required this.message});
}

class GoodsReceivedError extends GoodsReceivedState {
  final String error;
  final GoodsReceivedErrorType errorType;

  const GoodsReceivedError({
    required this.error,
    this.errorType = GoodsReceivedErrorType.general,
  });
}
