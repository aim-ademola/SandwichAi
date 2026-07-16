import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_model.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/order_list_repo.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/order_list-bloc/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/order_list-bloc/state.dart';

class OrdersListBloc extends Bloc<OrdersListEvent, OrdersListState> {
  final PurchaseOrdersRepositoryInterface _repository;

  // Current filter state
  String? _currentStatus;
  String? _currentPriority;
  String? _currentCategory;
  String? _currentSearch;
  int _currentPage = 1;
  OrdersListMode _currentMode = OrdersListMode.all;
  String branchId = '';

  OrdersListBloc({required PurchaseOrdersRepositoryInterface repository})
    : _repository = repository,
      super(const OrdersInitial()) {
    _getBranchId();
    on<LoadOrders>(_onLoadOrders);
    on<LoadPendingApprovalOrders>(_onLoadPendingApprovalOrders);
    on<LoadOverdueDeliveryOrders>(_onLoadOverdueDeliveryOrders);
    on<RefreshOrders>(_onRefreshOrders);
    on<LoadMoreOrders>(_onLoadMoreOrders);
    on<FilterOrders>(_onFilterOrders);
    on<SearchOrders>(_onSearchOrders);
    on<ClearFilters>(_onClearFilters);
  }
  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrdersListState> emit,
  ) async {
    try {
      emit(const OrdersLoading());
      if (branchId.isEmpty) {
        branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
      }

      final response = await _repository.getPurchaseOrders(
        status: event.status,
        deliveryStatus: event.deliveryStatus,
        paymentStatus: event.paymentStatus,
        supplierId: event.supplierId,
        buyerBranchId: branchId,
        priority: event.priority,
        primaryCategory: event.primaryCategory,
        search: event.search,
        orderDateFrom: event.orderDateFrom,
        orderDateTo: event.orderDateTo,
        deliveryDateFrom: event.deliveryDateFrom,
        deliveryDateTo: event.deliveryDateTo,
        minAmount: event.minAmount,
        maxAmount: event.maxAmount,
        page: event.page,
        limit: event.limit,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      );

      await response.when(
        success: (data) async {
          _currentPage = event.page;
          _currentMode = OrdersListMode.all;
          _currentStatus = event.status;
          _currentPriority = event.priority;
          _currentCategory = event.primaryCategory;
          _currentSearch = event.search;

          if (data.orders.isEmpty) {
            emit(const OrdersEmpty(message: 'No orders found'));
          } else {
            emit(
              OrdersLoaded(
                orders: data.orders,
                total: data.total,
                currentPage: data.page,
                totalPages: data.totalPages,
                hasNextPage: data.hasNextPage,
                hasPreviousPage: data.hasPreviousPage,
                activeStatus: event.status,
                activePriority: event.priority,
                activeCategory: event.primaryCategory,
                searchQuery: event.search,
              ),
            );
          }
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(OrdersError(error: error.toString(), errorType: errorType));
        },
      );
    } catch (e) {
      emit(
        OrdersError(
          error: 'An unexpected error occurred: ${e.toString()}',
          errorType: OrdersErrorType.general,
        ),
      );
    }
  }

  Future<void> _onRefreshOrders(
    RefreshOrders event,
    Emitter<OrdersListState> emit,
  ) async {
    if (_currentMode == OrdersListMode.pendingApprovals) {
      add(const LoadPendingApprovalOrders(page: 1));
      return;
    }
    if (_currentMode == OrdersListMode.overdueDeliveries) {
      add(const LoadOverdueDeliveryOrders(page: 1));
      return;
    }

    add(
      LoadOrders(
        status: _currentStatus,
        priority: _currentPriority,
        primaryCategory: _currentCategory,
        search: _currentSearch,
        page: 1,
      ),
    );
  }

  Future<void> _onLoadPendingApprovalOrders(
    LoadPendingApprovalOrders event,
    Emitter<OrdersListState> emit,
  ) async {
    await _loadSpecialOrders(
      emit: emit,
      mode: OrdersListMode.pendingApprovals,
      page: event.page,
      request: () => _repository.getPendingApprovalOrders(
        page: event.page,
        limit: event.limit,
      ),
      emptyMessage: 'No pending approvals found',
    );
  }

  Future<void> _onLoadOverdueDeliveryOrders(
    LoadOverdueDeliveryOrders event,
    Emitter<OrdersListState> emit,
  ) async {
    await _loadSpecialOrders(
      emit: emit,
      mode: OrdersListMode.overdueDeliveries,
      page: event.page,
      request: () => _repository.getOverdueDeliveries(
        page: event.page,
        limit: event.limit,
      ),
      emptyMessage: 'No overdue deliveries found',
    );
  }

  Future<void> _loadSpecialOrders({
    required Emitter<OrdersListState> emit,
    required OrdersListMode mode,
    required int page,
    required Future<dynamic> Function() request,
    required String emptyMessage,
  }) async {
    try {
      emit(const OrdersLoading());
      final response = await request();
      await response.when(
        success: (data) async {
          _currentMode = mode;
          _currentPage = page;
          if (data.orders.isEmpty) {
            emit(OrdersEmpty(message: emptyMessage));
          } else {
            emit(
              OrdersLoaded(
                orders: data.orders,
                total: data.total,
                currentPage: data.page,
                totalPages: data.totalPages,
                hasNextPage: data.hasNextPage,
                hasPreviousPage: data.hasPreviousPage,
              ),
            );
          }
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(OrdersError(error: error.toString(), errorType: errorType));
        },
      );
    } catch (e) {
      emit(
        OrdersError(
          error: 'An unexpected error occurred: ${e.toString()}',
          errorType: OrdersErrorType.general,
        ),
      );
    }
  }

  Future<void> _onLoadMoreOrders(
    LoadMoreOrders event,
    Emitter<OrdersListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OrdersLoaded || !currentState.hasNextPage) {
      return;
    }

    try {
      emit(OrdersLoadingMore(currentState.orders));
      if (_currentMode == OrdersListMode.pendingApprovals) {
        final nextPage = _currentPage + 1;
        final response = await _repository.getPendingApprovalOrders(
          page: nextPage,
        );
        await _appendOrders(response, currentState, nextPage, emit);
        return;
      }
      if (_currentMode == OrdersListMode.overdueDeliveries) {
        final nextPage = _currentPage + 1;
        final response = await _repository.getOverdueDeliveries(page: nextPage);
        await _appendOrders(response, currentState, nextPage, emit);
        return;
      }

      if (branchId.isEmpty) {
        branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
      }

      final nextPage = _currentPage + 1;

      final response = await _repository.getPurchaseOrders(
        status: _currentStatus,
        priority: _currentPriority,
        primaryCategory: _currentCategory,
        search: _currentSearch,
        buyerBranchId: branchId,
        page: nextPage,
      );

      await _appendOrders(response, currentState, nextPage, emit);
    } catch (e) {
      // Revert to previous state on error
      emit(currentState);
    }
  }

  Future<void> _appendOrders(
    dynamic response,
    OrdersLoaded currentState,
    int nextPage,
    Emitter<OrdersListState> emit,
  ) async {
    await response.when(
      success: (data) async {
        _currentPage = nextPage;
        final updatedOrders = List<PurchaseOrder>.from(currentState.orders)
          ..addAll(data.orders);
        emit(
          OrdersLoaded(
            orders: updatedOrders,
            total: data.total,
            currentPage: data.page,
            totalPages: data.totalPages,
            hasNextPage: data.hasNextPage,
            hasPreviousPage: data.hasPreviousPage,
            activeStatus: _currentStatus,
            activePriority: _currentPriority,
            activeCategory: _currentCategory,
            searchQuery: _currentSearch,
          ),
        );
      },
      error: (error) async {
        emit(currentState);
      },
    );
  }

  Future<void> _onFilterOrders(
    FilterOrders event,
    Emitter<OrdersListState> emit,
  ) async {
    add(
      LoadOrders(
        status: event.status,
        priority: event.priority,
        primaryCategory: event.primaryCategory,
        search: _currentSearch,
        page: 1,
      ),
    );
  }

  Future<void> _onSearchOrders(
    SearchOrders event,
    Emitter<OrdersListState> emit,
  ) async {
    add(
      LoadOrders(
        status: _currentStatus,
        priority: _currentPriority,
        primaryCategory: _currentCategory,
        search: event.query,
        page: 1,
      ),
    );
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<OrdersListState> emit,
  ) async {
    _currentStatus = null;
    _currentPriority = null;
    _currentCategory = null;
    _currentSearch = null;

    add(const LoadOrders(page: 1));
  }

  OrdersErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return OrdersErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return OrdersErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return OrdersErrorType.server;
    }

    return OrdersErrorType.general;
  }
}

enum OrdersListMode { all, pendingApprovals, overdueDeliveries }
