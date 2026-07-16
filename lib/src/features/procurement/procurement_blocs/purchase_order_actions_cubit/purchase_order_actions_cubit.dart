import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_action_model.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/order_list_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/purchase_order_repo.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/purchase_order_actions_cubit/purchase_order_actions_state.dart';

class PurchaseOrderActionsCubit extends Cubit<PurchaseOrderActionsState> {
  final OrderRepositoryInterface _orderRepository;
  final PurchaseOrdersRepositoryInterface _ordersRepository;

  PurchaseOrderActionsCubit({
    required OrderRepositoryInterface orderRepository,
    required PurchaseOrdersRepositoryInterface ordersRepository,
  }) : _orderRepository = orderRepository,
       _ordersRepository = ordersRepository,
       super(const PurchaseOrderActionsState());

  Future<void> loadOrderContext(String orderId) async {
    await Future.wait([loadApprovalStatus(orderId), loadTimeline(orderId)]);
  }

  Future<void> loadApprovalStatus(String orderId) async {
    emit(
      state.copyWith(
        approvalStatusState: PurchaseOrderActionStatus.loading,
        clearApprovalError: true,
      ),
    );
    final response = await _orderRepository.getApprovalStatus(orderId);
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            approvalStatusState: PurchaseOrderActionStatus.loaded,
            approvalStatus: data,
          ),
        );
      },
      error: (error) {
        emit(
          state.copyWith(
            approvalStatusState: PurchaseOrderActionStatus.error,
            approvalError: error.toString(),
          ),
        );
      },
    );
  }

  Future<void> loadTimeline(String orderId) async {
    emit(
      state.copyWith(
        timelineStatus: PurchaseOrderActionStatus.loading,
        clearTimelineError: true,
      ),
    );
    final response = await _ordersRepository.getOrderTimeline(orderId: orderId);
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            timelineStatus: data.events.isEmpty
                ? PurchaseOrderActionStatus.empty
                : PurchaseOrderActionStatus.loaded,
            timeline: data,
          ),
        );
      },
      error: (error) {
        emit(
          state.copyWith(
            timelineStatus: PurchaseOrderActionStatus.error,
            timelineError: error.toString(),
          ),
        );
      },
    );
  }

  Future<bool> submitApproval({
    required String orderId,
    required SubmitPurchaseOrderApprovalRequest request,
  }) {
    return _runAction(
      () => _orderRepository.submitApproval(orderId: orderId, request: request),
      refreshOrderId: orderId,
    );
  }

  Future<bool> dispatchOrder({
    required String orderId,
    required PurchaseOrderDispatchRequest request,
  }) {
    return _runAction(
      () => _orderRepository.dispatchOrder(orderId: orderId, request: request),
      refreshOrderId: orderId,
    );
  }

  Future<bool> updateOrder({
    required String orderId,
    required Map<String, dynamic> data,
  }) {
    return _runAction(
      () => _orderRepository.updateOrder(orderId: orderId, data: data),
      refreshOrderId: orderId,
    );
  }

  Future<bool> deleteOrder(String orderId) {
    return _runAction(() => _orderRepository.deleteOrder(orderId));
  }

  Future<bool> _runAction(
    Future<dynamic> Function() action, {
    String? refreshOrderId,
  }) async {
    emit(
      state.copyWith(
        actionStatus: PurchaseOrderActionStatus.loading,
        clearAction: true,
      ),
    );
    final response = await action();
    return response.when(
      success: (data) async {
        emit(
          state.copyWith(
            actionStatus: PurchaseOrderActionStatus.loaded,
            actionMessage: data.message.isEmpty
                ? 'Purchase order updated.'
                : data.message,
          ),
        );
        if (refreshOrderId != null) {
          await loadOrderContext(refreshOrderId);
        }
        return true;
      },
      error: (error) {
        emit(
          state.copyWith(
            actionStatus: PurchaseOrderActionStatus.error,
            actionError: error.toString(),
          ),
        );
        return false;
      },
    );
  }
}
