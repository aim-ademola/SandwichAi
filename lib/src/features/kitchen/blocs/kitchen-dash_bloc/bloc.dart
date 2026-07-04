import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/globals/notifications/local_notification.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen-dash_bloc/event.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen-dash_bloc/state.dart';
import 'package:sandwich_ai/src/features/kitchen/data/model/kitchen_dash_model.dart';
import 'package:sandwich_ai/src/features/kitchen/data/repo/kitchen_dash_repo.dart';

class KitchenDashboardBloc
    extends Bloc<KitchenDashboardEvent, KitchenDashboardState> {
  final KitchenDashboardRepositoryInterface _repository;
  String branchId = '';
  String employeeId = '';
  final Set<String> _notifiedOrders = {};

  KitchenDashboardData? _cachedDashboardData;
  OrderFilter _currentFilter = OrderFilter.all;

  KitchenDashboardBloc({
    required KitchenDashboardRepositoryInterface repository,
  }) : _repository = repository,
       super(const DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboardData>(_onRefreshDashboardData);
    on<FilterOrders>(_onFilterOrders);

    // Status transition handlers — all share the same _onUpdateOrderStatus helper
    on<MarkOrderAsComfirmed>(
      (e, emit) => _onUpdateOrderStatus(
        orderId: e.orderId,
        newStatus: 'CONFIRMED',
        successMessage: 'Order confirmed',
        notificationTitle: 'Order Confirmed',
        notificationBody: 'Order is confirmed for processing',
        notificationPayloadPrefix: 'order_confirmed',
        emit: emit,
      ),
    );
    on<StartOrderPreparation>(
      (e, emit) => _onUpdateOrderStatus(
        orderId: e.orderId,
        newStatus: 'PREPARING',
        successMessage: 'Order preparation started',
        notificationTitle: 'Order In Preparation',
        notificationBody: 'Kitchen has started preparing the order',
        notificationPayloadPrefix: 'order_preparing',
        emit: emit,
      ),
    );
    on<MarkOrderAsReady>(
      (e, emit) => _onUpdateOrderStatus(
        orderId: e.orderId,
        newStatus: 'READY',
        successMessage: 'Order marked as ready',
        notificationTitle: 'Order Ready',
        notificationBody: 'Order is ready for pickup',
        notificationPayloadPrefix: 'order_ready',
        emit: emit,
      ),
    );
    on<MarkOrderAsServed>(
      (e, emit) => _onUpdateOrderStatus(
        orderId: e.orderId,
        newStatus: 'SERVED',
        successMessage: 'Order marked as served',
        notificationTitle: 'Order Served',
        notificationBody: 'Order has been served to the customer',
        notificationPayloadPrefix: 'order_served',
        emit: emit,
      ),
    );
    on<MarkOrderAsCompleted>(
      (e, emit) => _onUpdateOrderStatus(
        orderId: e.orderId,
        newStatus: 'COMPLETED',
        successMessage: 'Order completed',
        notificationTitle: 'Order Completed',
        notificationBody: 'Order has been completed successfully',
        notificationPayloadPrefix: 'order_completed',
        emit: emit,
      ),
    );
    on<CancelOrder>(
      (e, emit) => _onUpdateOrderStatus(
        orderId: e.orderId,
        newStatus: 'CANCELLED',
        rejectReason: e.reason,
        successMessage: 'Order cancelled',
        notificationTitle: 'Order Cancelled',
        notificationBody: 'Order has been cancelled',
        notificationPayloadPrefix: 'order_cancelled',
        emit: emit,
      ),
    );

    _initializeAuthIds();
  }

  //  Auth ─

  Future<void> _initializeAuthIds() async {
    branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    employeeId = await AuthCacheHelper.instance.getEmpID() ?? '';
    AppLogger.log('DEBUG BLOC: Branch: $branchId | Employee: $employeeId');
  }

  Future<bool> _ensureEmployeeId(
    String orderId,
    Emitter<KitchenDashboardState> emit,
  ) async {
    if (employeeId.isNotEmpty) return true;
    employeeId = await AuthCacheHelper.instance.getEmpID() ?? '';
    if (employeeId.isNotEmpty) return true;

    emit(
      OrderActionError(
        orderId: orderId,
        error: 'Employee ID not found. Please log in again.',
      ),
    );
    return false;
  }

  //  Load ─

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<KitchenDashboardState> emit,
  ) async {
    try {
      if (branchId.isEmpty) await _initializeAuthIds();

      emit(const DashboardLoading());

      final response = await _repository.getDashboardData(branchId: branchId);

      await response.when(
        success: (dashboardData) async {
          _cachedDashboardData = dashboardData;
          _notifyNewOrders(dashboardData.recentOrders);

          if (dashboardData.recentOrders.isEmpty) {
            emit(const DashboardEmpty());
            return;
          }

          emit(
            DashboardLoaded(
              dashboardData: dashboardData,
              filteredOrders: _applyFilter(
                dashboardData.recentOrders,
                _currentFilter,
              ),
              currentFilter: _currentFilter,
            ),
          );
        },
        error: (error) async {
          emit(
            DashboardError(
              error: error.toString(),
              errorType: _determineErrorType(error.toString()),
            ),
          );
        },
      );
    } catch (e) {
      AppLogger.log('DEBUG BLOC: Exception in _onLoadDashboardData — $e');
      emit(
        const DashboardError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: DashboardErrorType.general,
        ),
      );
    }
  }

  //  Refresh ─

  Future<void> _onRefreshDashboardData(
    RefreshDashboardData event,
    Emitter<KitchenDashboardState> emit,
  ) async {
    try {
      if (_cachedDashboardData != null) {
        emit(DashboardRefreshing(currentData: _cachedDashboardData!));
      }

      final response = await _repository.getDashboardData(branchId: branchId);

      await response.when(
        success: (dashboardData) async {
          _cachedDashboardData = dashboardData;
          _notifyNewOrders(dashboardData.recentOrders);

          if (dashboardData.recentOrders.isEmpty) {
            emit(const DashboardEmpty());
            return;
          }

          emit(
            DashboardLoaded(
              dashboardData: dashboardData,
              filteredOrders: _applyFilter(
                dashboardData.recentOrders,
                _currentFilter,
              ),
              currentFilter: _currentFilter,
            ),
          );
        },
        error: (error) async {
          emit(
            DashboardError(
              error: error.toString(),
              errorType: _determineErrorType(error.toString()),
            ),
          );
        },
      );
    } catch (e) {
      AppLogger.log('DEBUG BLOC: Exception in _onRefreshDashboardData — $e');
      emit(
        const DashboardError(
          error: 'Failed to refresh. Please try again.',
          errorType: DashboardErrorType.general,
        ),
      );
    }
  }

  //  Filter ──

  void _onFilterOrders(
    FilterOrders event,
    Emitter<KitchenDashboardState> emit,
  ) {
    if (state is! DashboardLoaded) return;
    _currentFilter = event.filter;
    final currentState = state as DashboardLoaded;
    emit(
      currentState.copyWith(
        filteredOrders: _applyFilter(
          currentState.dashboardData.recentOrders,
          event.filter,
        ),
        currentFilter: event.filter,
      ),
    );
  }

  //  Shared status update

  Future<void> _onUpdateOrderStatus({
    required String orderId,
    required String newStatus,
    required String successMessage,
    required String notificationTitle,
    required String notificationBody,
    required String notificationPayloadPrefix,
    required Emitter<KitchenDashboardState> emit,
    String? rejectReason,
  }) async {
    AppLogger.log('DEBUG BLOC: Updating order $orderId → $newStatus');

    if (!await _ensureEmployeeId(orderId, emit)) return;

    try {
      final response = await _repository.updateOrderStatus(
        orderId: orderId,
        status: newStatus,
        updatedBy: employeeId,
        rejectReason: rejectReason,
      );

      if (response.isSuccess) {
        AppLogger.log('DEBUG BLOC: ✅ $orderId → $newStatus');

        NotificationService().showNotification(
          id: orderId.hashCode ^ newStatus.hashCode,
          title: notificationTitle,
          body: notificationBody,
          payload: '$notificationPayloadPrefix|$orderId',
          importance: NotificationImportance.high,
          priority: NotificationPriority.high,
        );

        emit(OrderActionSuccess(orderId: orderId, message: successMessage));
        await Future.delayed(const Duration(milliseconds: 500));
        await _refreshAndEmit(emit);
      } else {
        AppLogger.log('DEBUG BLOC: ❌ $orderId → $newStatus: ${response.error}');
        emit(
          OrderActionError(
            orderId: orderId,
            error:
                response.error?.toString() ?? 'Failed to update order status',
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        await _emitCachedOrRefresh(emit);
      }
    } catch (e) {
      AppLogger.log('DEBUG BLOC: Exception updating $orderId → $newStatus: $e');
      emit(
        OrderActionError(
          orderId: orderId,
          error: 'Failed to update order: ${e.toString()}',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      await _emitCachedOrRefresh(emit);
    }
  }

  //  Helpers ─

  /// Fetches fresh data from the API and emits a loaded state.
  Future<void> _refreshAndEmit(Emitter<KitchenDashboardState> emit) async {
    final refreshResponse = await _repository.getDashboardData(
      branchId: branchId,
    );

    if (refreshResponse.isSuccess) {
      final dashboardData = refreshResponse.data!;
      _cachedDashboardData = dashboardData;
      emit(
        DashboardLoaded(
          dashboardData: dashboardData,
          filteredOrders: _applyFilter(
            dashboardData.recentOrders,
            _currentFilter,
          ),
          currentFilter: _currentFilter,
        ),
      );
    } else {
      await _emitCachedOrRefresh(emit);
    }
  }

  /// Falls back to cached data when a refresh isn't possible.
  Future<void> _emitCachedOrRefresh(Emitter<KitchenDashboardState> emit) async {
    if (_cachedDashboardData != null) {
      emit(
        DashboardLoaded(
          dashboardData: _cachedDashboardData!,
          filteredOrders: _applyFilter(
            _cachedDashboardData!.recentOrders,
            _currentFilter,
          ),
          currentFilter: _currentFilter,
        ),
      );
    }
  }

  /// Fires a notification for each order not yet seen.
  void _notifyNewOrders(List<KitchenOrder> orders) {
    for (final order in orders) {
      if (_notifiedOrders.contains(order.id)) continue;

      _notifiedOrders.add(order.id);
      NotificationService().showNotification(
        id: order.id.hashCode,
        title: '🧾 New Order Received',
        body: 'Order ${order.orderId} from ${order.customerName} is waiting',
        payload: 'order|${order.id}',
      );
    }
  }

  List<KitchenOrder> _applyFilter(List<KitchenOrder> orders, OrderFilter _) {
    return orders;
  }

  DashboardErrorType _determineErrorType(String error) {
    final e = error.toLowerCase();
    if (e.contains('network') ||
        e.contains('connection') ||
        e.contains('internet')) {
      return DashboardErrorType.network;
    }
    if (e.contains('timeout')) return DashboardErrorType.timeout;
    if (e.contains('not found') || e.contains('404')) {
      return DashboardErrorType.notFound;
    }
    if (e.contains('server') || e.contains('500') || e.contains('503')) {
      return DashboardErrorType.server;
    }
    if (e.contains('format') || e.contains('validation')) {
      return DashboardErrorType.validation;
    }
    return DashboardErrorType.general;
  }
}
