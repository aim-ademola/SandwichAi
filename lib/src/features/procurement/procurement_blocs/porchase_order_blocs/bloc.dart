import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/auth/data/models/login_model.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/purchase_order_repo.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/porchase_order_blocs/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/porchase_order_blocs/state.dart';

import '../../../../core/config/prod_print.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepositoryInterface _repository;
  String branchId = '';
  String empId = '';
  String orgId = '';

  OrderBloc({required OrderRepositoryInterface repository})
    : _repository = repository,
      super(const OrderInitial()) {
    on<CreateOrder>(_onCreateOrder);
    on<ResetOrderState>(_onResetOrderState);
    _getBranchId();
  }

  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    final user = await AuthCacheHelper.instance.getUserData();

    branchId = id;
    empId = user?.id ?? '';
  }

  Future<void> _onCreateOrder(
    CreateOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      emit(const OrderCreating());

      String buyerId = '';
      String buyerBranchId = '';
      String orgID = '';

      // If not loaded yet, try to get them again
      if (buyerId.isEmpty || buyerBranchId.isEmpty) {
        buyerId = await AuthCacheHelper.instance.userID() ?? '';
        buyerBranchId = await AuthCacheHelper.instance.getBranchID() ?? '';
        orgID = await AuthCacheHelper.instance.getOrgId() ?? '';
        final UserModel? userid = await AuthCacheHelper.instance.getUserData();
      }

      AppLogger.log(
        'Creating order with branchId: $buyerBranchId, empId: $buyerId',
      );

      if (buyerId.isEmpty || buyerBranchId.isEmpty) {
        emit(
          const OrderError(
            error: 'User session expired. Please log in again.',
            errorType: OrderErrorType.validation,
          ),
        );
        return;
      }

      final response = await _repository.createOrder(
        supplierId: event.supplierId,
        buyerId: buyerId,
        buyerBranchId: buyerBranchId,
        priority: event.priority,
        orgId: orgID,
        expectedDeliveryDate: event.expectedDeliveryDate,
        paymentTerm: event.paymentTerm,
        deliveryAddress: event.deliveryAddress,
        deliveryCity: event.deliveryCity,
        deliveryState: event.deliveryState,
        deliveryInstructions: event.deliveryInstructions,
        buyerNotes: event.buyerNotes,
        items: event.items,
      );

      await response.when(
        success: (data) async {
          // Validate that we actually got success data
          if (data.isEmpty) {
            emit(
              const OrderError(
                error: 'Failed to create order. Please try again.',
                errorType: OrderErrorType.general,
              ),
            );
            return;
          }

          // Check if response contains error indicators
          if (data['statusCode'] != null && data['statusCode'] >= 400) {
            final errorMessage = data['message'] ?? 'Failed to create order';
            emit(
              OrderError(
                error: errorMessage,
                errorType: _determineErrorType(errorMessage),
              ),
            );
            return;
          }

          emit(
            OrderCreated(
              orderData: data,
              orderNumber: data['orderNumber'] ?? data['id'] ?? 'N/A',
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(OrderError(error: error.toString(), errorType: errorType));
        },
      );
    } catch (e) {
      AppLogger.log('Order creation error: $e');
      emit(
        OrderError(
          error: 'An unexpected error occurred: ${e.toString()}',
          errorType: OrderErrorType.general,
        ),
      );
    }
  }

  void _onResetOrderState(ResetOrderState event, Emitter<OrderState> emit) {
    emit(const OrderInitial());
  }

  OrderErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return OrderErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return OrderErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return OrderErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation') ||
        lowercaseError.contains('required') ||
        lowercaseError.contains('invalid') ||
        lowercaseError.contains('branch')) {
      return OrderErrorType.validation;
    }

    return OrderErrorType.general;
  }
}
