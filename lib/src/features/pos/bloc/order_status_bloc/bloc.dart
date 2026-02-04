// bloc/kitchen_orders_bloc/bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/pos/bloc/order_status_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/order_status_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/oder_status_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/order_statua_repo.dart';

class KitchenOrdersBloc extends Bloc<KitchenOrdersEvent, KitchenOrdersState> {
  final KitchenOrdersRepositoryInterface _repository;
  String branchId = '';

  KitchenOrdersBloc({required KitchenOrdersRepositoryInterface repository})
    : _repository = repository,
      super(const KitchenOrdersInitial()) {
    on<LoadKitchenOrders>(_onLoadKitchenOrders);
    on<RefreshKitchenOrders>(_onRefreshKitchenOrders);
    on<FilterKitchenOrdersByStatus>(_onFilterKitchenOrdersByStatus);
    on<SearchKitchenOrders>(_onSearchKitchenOrders);
    on<FilterKitchenOrdersByDateRange>(_onFilterKitchenOrdersByDateRange);
  }

  Future<String> _getBranchId() async {
    if (branchId.isEmpty) {
      final id = await AuthCacheHelper.instance.getBranchID() ?? '';
      branchId = id;
    }
    return branchId;
  }

  Future<void> _onLoadKitchenOrders(
    LoadKitchenOrders event,
    Emitter<KitchenOrdersState> emit,
  ) async {
    try {
      emit(const KitchenOrdersLoading());

      // Wait for branchId to be fetched
      final fetchedBranchId = await _getBranchId();

      if (fetchedBranchId.isEmpty) {
        emit(
          const KitchenOrdersError(
            error: 'Branch ID not found. Please login again.',
            errorType: KitchenOrdersErrorType.validation,
          ),
        );
        return;
      }

      final response = await _repository.getKitchenOrders(
        branchId: fetchedBranchId,
      );

      await response.when(
        success: (orders) async {
          if (orders.isEmpty) {
            emit(const KitchenOrdersEmpty());
            return;
          }

          // Filter out completed and cancelled orders for active orders view
          final activeOrders = orders.where((order) {
            return order.status != OrderStatus.completed &&
                order.status != OrderStatus.cancelled;
          }).toList();

          // If no active orders but there are orders, show empty state
          // but store all orders so filters can work
          emit(
            KitchenOrdersLoaded(
              orders: orders,
              filteredOrders: activeOrders.isEmpty ? orders : activeOrders,
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            KitchenOrdersError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const KitchenOrdersError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: KitchenOrdersErrorType.general,
        ),
      );
    }
  }

  Future<void> _onRefreshKitchenOrders(
    RefreshKitchenOrders event,
    Emitter<KitchenOrdersState> emit,
  ) async {
    if (state is! KitchenOrdersLoaded) {
      add(const LoadKitchenOrders());
      return;
    }

    final currentState = state as KitchenOrdersLoaded;
    emit(KitchenOrdersRefreshing(currentData: currentState.orders));

    // Wait for branchId to be fetched
    final fetchedBranchId = await _getBranchId();

    if (fetchedBranchId.isEmpty) {
      emit(
        const KitchenOrdersError(
          error: 'Branch ID not found. Please login again.',
          errorType: KitchenOrdersErrorType.validation,
        ),
      );
      return;
    }

    final response = await _repository.getKitchenOrders(
      branchId: fetchedBranchId,
      status: currentState.selectedStatus,
      startDate: currentState.startDate,
      endDate: currentState.endDate,
    );

    await response.when(
      success: (orders) async {
        if (orders.isEmpty) {
          emit(const KitchenOrdersEmpty());
          return;
        }

        final activeOrders = orders.where((order) {
          return order.status != OrderStatus.completed &&
              order.status != OrderStatus.cancelled;
        }).toList();

        emit(
          KitchenOrdersLoaded(
            orders: orders,
            filteredOrders: activeOrders.isEmpty ? orders : activeOrders,
            selectedStatus: currentState.selectedStatus,
            searchQuery: currentState.searchQuery,
            startDate: currentState.startDate,
            endDate: currentState.endDate,
          ),
        );
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(KitchenOrdersError(error: error.toString(), errorType: errorType));
      },
    );
  }

  void _onFilterKitchenOrdersByStatus(
    FilterKitchenOrdersByStatus event,
    Emitter<KitchenOrdersState> emit,
  ) {
    if (state is! KitchenOrdersLoaded) return;

    final currentState = state as KitchenOrdersLoaded;
    final orders = currentState.orders;

    if (event.status == null || event.status!.isEmpty) {
      // Show active orders (excluding completed and cancelled)
      final activeOrders = orders.where((order) {
        return order.status != OrderStatus.completed &&
            order.status != OrderStatus.cancelled;
      }).toList();

      emit(
        KitchenOrdersLoaded(
          orders: orders,
          filteredOrders: activeOrders.isEmpty ? orders : activeOrders,
          searchQuery: currentState.searchQuery,
        ),
      );
      return;
    }

    final filtered = orders.where((order) {
      return order.status.value == event.status;
    }).toList();

    emit(
      KitchenOrdersLoaded(
        orders: orders,
        filteredOrders: filtered,
        selectedStatus: event.status,
        searchQuery: currentState.searchQuery,
      ),
    );
  }

  void _onSearchKitchenOrders(
    SearchKitchenOrders event,
    Emitter<KitchenOrdersState> emit,
  ) {
    if (state is! KitchenOrdersLoaded) return;

    final currentState = state as KitchenOrdersLoaded;
    final orders = currentState.orders;

    if (event.query.isEmpty) {
      // Show active orders (excluding completed and cancelled)
      final activeOrders = orders.where((order) {
        return order.status != OrderStatus.completed &&
            order.status != OrderStatus.cancelled;
      }).toList();

      emit(
        KitchenOrdersLoaded(
          orders: orders,
          filteredOrders: activeOrders.isEmpty ? orders : activeOrders,
          selectedStatus: currentState.selectedStatus,
          searchQuery: null,
        ),
      );
      return;
    }

    final query = event.query.toLowerCase();
    final filtered = orders.where((order) {
      return order.orderId.toLowerCase().contains(query) ||
          order.customerName!.toLowerCase().contains(query) ||
          order.customerPhone!.contains(query) ||
          (order.tableNumber?.toLowerCase().contains(query) ?? false);
    }).toList();

    emit(
      KitchenOrdersLoaded(
        orders: orders,
        filteredOrders: filtered,
        selectedStatus: currentState.selectedStatus,
        searchQuery: event.query,
      ),
    );
  }

  Future<void> _onFilterKitchenOrdersByDateRange(
    FilterKitchenOrdersByDateRange event,
    Emitter<KitchenOrdersState> emit,
  ) async {
    if (state is! KitchenOrdersLoaded) return;

    final currentState = state as KitchenOrdersLoaded;
    emit(KitchenOrdersRefreshing(currentData: currentState.orders));

    // Wait for branchId to be fetched
    final fetchedBranchId = await _getBranchId();

    if (fetchedBranchId.isEmpty) {
      emit(
        const KitchenOrdersError(
          error: 'Branch ID not found. Please login again.',
          errorType: KitchenOrdersErrorType.validation,
        ),
      );
      return;
    }

    final response = await _repository.getKitchenOrders(
      branchId: fetchedBranchId,
      startDate: event.startDate,
      endDate: event.endDate,
      status: currentState.selectedStatus,
    );

    await response.when(
      success: (orders) async {
        if (orders.isEmpty) {
          emit(const KitchenOrdersEmpty());
          return;
        }

        final activeOrders = orders.where((order) {
          return order.status != OrderStatus.completed &&
              order.status != OrderStatus.cancelled;
        }).toList();

        emit(
          KitchenOrdersLoaded(
            orders: orders,
            filteredOrders: activeOrders.isEmpty ? orders : activeOrders,
            selectedStatus: currentState.selectedStatus,
            searchQuery: currentState.searchQuery,
            startDate: event.startDate,
            endDate: event.endDate,
          ),
        );
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(KitchenOrdersError(error: error.toString(), errorType: errorType));
      },
    );
  }

  KitchenOrdersErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return KitchenOrdersErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return KitchenOrdersErrorType.timeout;
    }

    if (lowercaseError.contains('not found') ||
        lowercaseError.contains('404')) {
      return KitchenOrdersErrorType.notFound;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return KitchenOrdersErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return KitchenOrdersErrorType.validation;
    }

    return KitchenOrdersErrorType.general;
  }
}
