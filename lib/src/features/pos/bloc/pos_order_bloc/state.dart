import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/pos/data/model/pos_order_model.dart';

abstract class PosOrderState extends Equatable {
  const PosOrderState();

  @override
  List<Object?> get props => [];
}

class PosOrderInitial extends PosOrderState {
  const PosOrderInitial();
}

class PosOrderCreating extends PosOrderState {
  const PosOrderCreating();
}

class PosOrderCreated extends PosOrderState {
  final PosOrderResponseModel order;

  const PosOrderCreated({required this.order});

  @override
  List<Object?> get props => [order];
}

class PosOrderError extends PosOrderState {
  final String error;

  const PosOrderError({required this.error});

  @override
  List<Object?> get props => [error];
}
