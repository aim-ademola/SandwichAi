import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_order_repo.dart';

class PosOrderBloc extends Bloc<PosOrderEvent, PosOrderState> {
  final PosOrderRepositoryInterface _repository;
  String branchId = '';
  String employeeId = '';

  PosOrderBloc({required PosOrderRepositoryInterface repository})
    : _repository = repository,
      super(const PosOrderInitial()) {
    _initializeIds();

    on<CreatePosOrder>(_onCreatePosOrder);
    on<ResetPosOrderState>(_onResetPosOrderState);
  }

  void _initializeIds() async {
    branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    employeeId = await AuthCacheHelper.instance.getEmpID() ?? '';
  }

  Future<void> _onCreatePosOrder(
    CreatePosOrder event,
    Emitter<PosOrderState> emit,
  ) async {
    try {
      emit(const PosOrderCreating());

      // Ensure IDs are loaded
      if (branchId.isEmpty) {
        branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
      }
      if (employeeId.isEmpty) {
        employeeId = await AuthCacheHelper.instance.getEmpID() ?? '';
      }

      // Validate required fields
      if (branchId.isEmpty) {
        emit(
          const PosOrderError(
            error: 'Branch ID not found. Please login again.',
          ),
        );
        return;
      }

      if (employeeId.isEmpty) {
        emit(
          const PosOrderError(
            error: 'Employee ID not found. Please login again.',
          ),
        );
        return;
      }

      if (event.items.isEmpty) {
        emit(const PosOrderError(error: 'Cannot create order with no items.'));
        return;
      }

      final response = await _repository.createPosOrder(
        branchId: branchId,
        orderType: event.orderType,
        tableNumber: event.tableNumber,
        customerName: event.customerName,
        customerPhone: event.customerPhone,
        items: event.items,
        discount: event.discount,
        specialInstructions: event.specialInstructions,
        takenBy: employeeId,
      );

      await response.when(
        success: (order) async {
          emit(PosOrderCreated(order: order));
        },
        error: (error) async {
          emit(PosOrderError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        PosOrderError(error: 'An unexpected error occurred: ${e.toString()}'),
      );
    }
  }

  void _onResetPosOrderState(
    ResetPosOrderState event,
    Emitter<PosOrderState> emit,
  ) {
    emit(const PosOrderInitial());
  }
}
