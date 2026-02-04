import 'package:sandwich_ai/src/features/procurement/data/model/procurement_good_recieved_model.dart';

abstract class GoodsReceivedEvent {
  const GoodsReceivedEvent();
}

class LoadInventoryItems extends GoodsReceivedEvent {
  final String organizationId;

  const LoadInventoryItems({required this.organizationId});
}

class CreateGoodsReceived extends GoodsReceivedEvent {
  final CreateGoodsReceivedRequest request;

  const CreateGoodsReceived({required this.request});
}

class LoadGoodsReceived extends GoodsReceivedEvent {
  final String branchId;

  const LoadGoodsReceived({required this.branchId});
}

class ResetGoodsReceived extends GoodsReceivedEvent {
  const ResetGoodsReceived();
}
