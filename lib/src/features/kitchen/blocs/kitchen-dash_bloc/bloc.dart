// bloc/kitchen_dashboard_bloc/bloc.dart

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
  final Set<String> _notifiedPendingOrders = {};

  // Keep track of the last successful dashboard data
  KitchenDashboardData? _cachedDashboardData;
  OrderFilter _currentFilter = OrderFilter.all;

  KitchenDashboardBloc({
    required KitchenDashboardRepositoryInterface repository,
  }) : _repository = repository,
       super(const DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboardData>(_onRefreshDashboardData);
    on<FilterOrders>(_onFilterOrders);
    on<StartOrderPreparation>(_onStartOrderPreparation);
    on<MarkOrderAsReady>(_onMarkOrderAsReady);

    // Initialize auth IDs
    _initializeAuthIds();
  }

  Future<void> _initializeAuthIds() async {
    branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    employeeId = await AuthCacheHelper.instance.getEmpID() ?? '';

    AppLogger.log('DEBUG BLOC: Branch ID: $branchId');
    AppLogger.log('DEBUG BLOC: Employee ID: $employeeId');
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<KitchenDashboardState> emit,
  ) async {
    try {
      // Ensure we have the IDs before making the request
      if (branchId.isEmpty) {
        branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
        employeeId = await AuthCacheHelper.instance.getEmpID() ?? '';
        AppLogger.log(
          'DEBUG BLOC: Initialized IDs - Branch: $branchId, Employee: $employeeId',
        );
      }

      emit(const DashboardLoading());

      AppLogger.log('DEBUG BLOC: Loading dashboard data...');
      final response = await _repository.getDashboardData(branchId: branchId);

      final pendingOrders = response.data?.recentOrders.where(
        (o) => o.status.toUpperCase() == 'PENDING',
      );

      for (final order in pendingOrders!) {
        if (!_notifiedPendingOrders.contains(order.id)) {
          _notifiedPendingOrders.add(order.id);

          NotificationService().showNotification(
            id: order.id.hashCode,
            title: '🧾 New Order Received',
            body:
                'Order ${order.orderId} from ${order.customerName} is waiting',
            payload: 'order|${order.id}',
          );
        }
      }

      await response.when(
        success: (dashboardData) async {
          AppLogger.log('DEBUG BLOC: Dashboard data loaded successfully');
          // Cache the dashboard data
          _cachedDashboardData = dashboardData;

          if (dashboardData.recentOrders.isEmpty) {
            AppLogger.log(
              'DEBUG BLOC: No orders found, emitting DashboardEmpty',
            );
            emit(const DashboardEmpty());
            return;
          }

          AppLogger.log(
            'DEBUG BLOC: Emitting DashboardLoaded with ${dashboardData.recentOrders.length} orders',
          );
          emit(
            DashboardLoaded(
              dashboardData: dashboardData,
              filteredOrders: dashboardData.recentOrders,
            ),
          );
        },
        error: (error) async {
          AppLogger.log('DEBUG BLOC: Error loading dashboard - $error');
          final errorType = _determineErrorType(error.toString());
          emit(DashboardError(error: error.toString(), errorType: errorType));
        },
      );
    } catch (e, stackTrace) {
      AppLogger.log('DEBUG BLOC: Exception in _onLoadDashboardData - $e');
      AppLogger.log('DEBUG BLOC: Stack trace - $stackTrace');
      emit(
        const DashboardError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: DashboardErrorType.general,
        ),
      );
    }
  }

  Future<void> _onRefreshDashboardData(
    RefreshDashboardData event,
    Emitter<KitchenDashboardState> emit,
  ) async {
    try {
      AppLogger.log('DEBUG BLOC: Refreshing dashboard data...');

      // If we have cached data, use it for the refreshing state
      if (_cachedDashboardData != null) {
        emit(DashboardRefreshing(currentData: _cachedDashboardData!));
      }

      final response = await _repository.getDashboardData(branchId: branchId);

      await response.when(
        success: (dashboardData) async {
          AppLogger.log('DEBUG BLOC: Dashboard refresh successful');
          // Cache the new dashboard data
          _cachedDashboardData = dashboardData;

          if (dashboardData.recentOrders.isEmpty) {
            emit(const DashboardEmpty());
            return;
          }

          final filteredOrders = _applyFilter(
            dashboardData.recentOrders,
            _currentFilter,
          );

          emit(
            DashboardLoaded(
              dashboardData: dashboardData,
              filteredOrders: filteredOrders,
              currentFilter: _currentFilter,
            ),
          );
        },
        error: (error) async {
          AppLogger.log('DEBUG BLOC: Error refreshing dashboard - $error');
          final errorType = _determineErrorType(error.toString());
          emit(DashboardError(error: error.toString(), errorType: errorType));
        },
      );
    } catch (e, stackTrace) {
      AppLogger.log('DEBUG BLOC: Exception in _onRefreshDashboardData - $e');
      AppLogger.log('DEBUG BLOC: Stack trace - $stackTrace');
      emit(
        const DashboardError(
          error: 'Failed to refresh. Please try again.',
          errorType: DashboardErrorType.general,
        ),
      );
    }
  }

  void _onFilterOrders(
    FilterOrders event,
    Emitter<KitchenDashboardState> emit,
  ) {
    if (state is! DashboardLoaded) return;

    final currentState = state as DashboardLoaded;
    final allOrders = currentState.dashboardData.recentOrders;

    final filteredOrders = _applyFilter(allOrders, event.filter);

    // Update current filter
    _currentFilter = event.filter;

    emit(
      currentState.copyWith(
        filteredOrders: filteredOrders,
        currentFilter: event.filter,
      ),
    );
  }

  List<KitchenOrder> _applyFilter(
    List<KitchenOrder> orders,
    OrderFilter filter,
  ) {
    switch (filter) {
      case OrderFilter.all:
        return orders;
      case OrderFilter.newOrder:
        return orders
            .where((order) => order.status.toUpperCase() == 'PENDING')
            .toList();
      case OrderFilter.inProgress:
        return orders
            .where((order) => order.status.toUpperCase() == 'PREPARING')
            .toList();
      case OrderFilter.completed:
        return orders
            .where(
              (order) =>
                  order.status.toUpperCase() == 'READY' ||
                  order.status.toUpperCase() == 'COMPLETED',
            )
            .toList();
    }
  }

  Future<void> _onStartOrderPreparation(
    StartOrderPreparation event,
    Emitter<KitchenDashboardState> emit,
  ) async {
    AppLogger.log(
      'DEBUG BLOC: _onStartOrderPreparation called for order ${event.orderId}',
    );

    // Ensure we have employee ID
    if (employeeId.isEmpty) {
      employeeId = await AuthCacheHelper.instance.getEmpID() ?? '';
      AppLogger.log('DEBUG BLOC: Retrieved employee ID: $employeeId');

      if (employeeId.isEmpty) {
        AppLogger.log('DEBUG BLOC: Employee ID is empty, cannot proceed');
        emit(
          OrderActionError(
            orderId: event.orderId,
            error: 'Employee ID not found. Please log in again.',
          ),
        );
        return;
      }
    }

    try {
      AppLogger.log('DEBUG BLOC: Making API call to start preparation...');

      // Make API call to update order status from PENDING to PREPARING
      final response = await _repository.updateOrderStatus(
        orderId: event.orderId,
        status: 'PREPARING',
        updatedBy: employeeId,
      );

      AppLogger.log('DEBUG BLOC: API response received');
      AppLogger.log('DEBUG BLOC: Response is success: ${response.isSuccess}');
      AppLogger.log('DEBUG BLOC: Response is error: ${response.hasError}');

      // Check if response is success
      if (response.isSuccess) {
        AppLogger.log('DEBUG BLOC: ✅ Order preparation started successfully');

        // Show success message
        emit(
          OrderActionSuccess(
            orderId: event.orderId,
            message: 'Order preparation started',
          ),
        );

        // Small delay to show snackbar
        await Future.delayed(const Duration(milliseconds: 500));

        // Refresh data
        AppLogger.log(
          'DEBUG BLOC: Refreshing dashboard after successful update...',
        );
        final refreshResponse = await _repository.getDashboardData(
          branchId: branchId,
        );

        if (refreshResponse.isSuccess) {
          AppLogger.log('DEBUG BLOC: Refresh successful, updating state');
          final dashboardData = refreshResponse.data!;
          _cachedDashboardData = dashboardData;

          final filteredOrders = _applyFilter(
            dashboardData.recentOrders,
            _currentFilter,
          );

          emit(
            DashboardLoaded(
              dashboardData: dashboardData,
              filteredOrders: filteredOrders,
              currentFilter: _currentFilter,
            ),
          );
        } else {
          AppLogger.log('DEBUG BLOC: Refresh failed: ${refreshResponse.error}');
          // If refresh fails but we have cached data, use it
          if (_cachedDashboardData != null) {
            final filteredOrders = _applyFilter(
              _cachedDashboardData!.recentOrders,
              _currentFilter,
            );

            emit(
              DashboardLoaded(
                dashboardData: _cachedDashboardData!,
                filteredOrders: filteredOrders,
                currentFilter: _currentFilter,
              ),
            );
          }
        }
      } else {
        AppLogger.log(
          'DEBUG BLOC: ❌ Order preparation failed: ${response.error}',
        );

        emit(
          OrderActionError(
            orderId: event.orderId,
            error: response.error.toString() ?? 'Failed to start preparation',
          ),
        );

        // Small delay to show error
        await Future.delayed(const Duration(milliseconds: 500));

        // Restore with cached data if available
        if (_cachedDashboardData != null) {
          final filteredOrders = _applyFilter(
            _cachedDashboardData!.recentOrders,
            _currentFilter,
          );

          emit(
            DashboardLoaded(
              dashboardData: _cachedDashboardData!,
              filteredOrders: filteredOrders,
              currentFilter: _currentFilter,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.log('DEBUG BLOC: Exception in _onStartOrderPreparation: $e');
      AppLogger.log('DEBUG BLOC: Stack trace: $stackTrace');

      emit(
        OrderActionError(
          orderId: event.orderId,
          error: 'Failed to start preparation: ${e.toString()}',
        ),
      );

      // Small delay to show error
      await Future.delayed(const Duration(milliseconds: 500));

      // Restore with cached data if available
      if (_cachedDashboardData != null) {
        final filteredOrders = _applyFilter(
          _cachedDashboardData!.recentOrders,
          _currentFilter,
        );

        emit(
          DashboardLoaded(
            dashboardData: _cachedDashboardData!,
            filteredOrders: filteredOrders,
            currentFilter: _currentFilter,
          ),
        );
      }
    }
  }

  Future<void> _onMarkOrderAsReady(
    MarkOrderAsReady event,
    Emitter<KitchenDashboardState> emit,
  ) async {
    AppLogger.log(
      'DEBUG BLOC: _onMarkOrderAsReady called for order ${event.orderId}',
    );

    // Ensure we have employee ID
    if (employeeId.isEmpty) {
      employeeId = await AuthCacheHelper.instance.getEmpID() ?? '';
      AppLogger.log('DEBUG BLOC: Retrieved employee ID: $employeeId');

      if (employeeId.isEmpty) {
        AppLogger.log('DEBUG BLOC: Employee ID is empty, cannot proceed');
        emit(
          OrderActionError(
            orderId: event.orderId,
            error: 'Employee ID not found. Please log in again.',
          ),
        );
        return;
      }
    }

    try {
      AppLogger.log('DEBUG BLOC: Making API call to mark order as ready...');

      // Make API call to update order status from PREPARING to READY
      final response = await _repository.updateOrderStatus(
        orderId: event.orderId,
        status: 'READY',
        updatedBy: employeeId,
      );

      NotificationService().showNotification(
        id: event.orderId.hashCode + 9999,
        title: 'Order Marked Ready',
        body: 'Order ${event.orderId} is ready for pickup',
        payload: 'order_ready|${event.orderId}',
        importance: NotificationImportance.high,
        priority: NotificationPriority.high,
      );

      AppLogger.log('DEBUG BLOC: API response received');
      AppLogger.log('DEBUG BLOC: Response is success: ${response.isSuccess}');
      AppLogger.log('DEBUG BLOC: Response is error: ${response.hasError}');

      // Check if response is success
      if (response.isSuccess) {
        AppLogger.log('DEBUG BLOC: ✅ Order marked as ready successfully');

        // Show success message
        emit(
          OrderActionSuccess(
            orderId: event.orderId,
            message: 'Order marked as ready',
          ),
        );

        // Small delay to show snackbar
        await Future.delayed(const Duration(milliseconds: 500));

        // Refresh data
        AppLogger.log(
          'DEBUG BLOC: Refreshing dashboard after successful update...',
        );
        final refreshResponse = await _repository.getDashboardData(
          branchId: branchId,
        );

        if (refreshResponse.isSuccess) {
          AppLogger.log('DEBUG BLOC: Refresh successful, updating state');
          final dashboardData = refreshResponse.data!;
          _cachedDashboardData = dashboardData;

          final filteredOrders = _applyFilter(
            dashboardData.recentOrders,
            _currentFilter,
          );

          emit(
            DashboardLoaded(
              dashboardData: dashboardData,
              filteredOrders: filteredOrders,
              currentFilter: _currentFilter,
            ),
          );
        } else {
          AppLogger.log('DEBUG BLOC: Refresh failed: ${refreshResponse.error}');
          // If refresh fails but we have cached data, use it
          if (_cachedDashboardData != null) {
            final filteredOrders = _applyFilter(
              _cachedDashboardData!.recentOrders,
              _currentFilter,
            );

            emit(
              DashboardLoaded(
                dashboardData: _cachedDashboardData!,
                filteredOrders: filteredOrders,
                currentFilter: _currentFilter,
              ),
            );
          }
        }
      } else {
        AppLogger.log('DEBUG BLOC: ❌ Mark as ready failed: ${response.error}');

        emit(
          OrderActionError(
            orderId: event.orderId,
            error: response.error.toString() ?? 'Failed to mark as ready',
          ),
        );

        // Small delay to show error
        await Future.delayed(const Duration(milliseconds: 500));

        // Restore with cached data if available
        if (_cachedDashboardData != null) {
          final filteredOrders = _applyFilter(
            _cachedDashboardData!.recentOrders,
            _currentFilter,
          );

          emit(
            DashboardLoaded(
              dashboardData: _cachedDashboardData!,
              filteredOrders: filteredOrders,
              currentFilter: _currentFilter,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.log('DEBUG BLOC: Exception in _onMarkOrderAsReady: $e');
      AppLogger.log('DEBUG BLOC: Stack trace: $stackTrace');

      emit(
        OrderActionError(
          orderId: event.orderId,
          error: 'Failed to mark as ready: ${e.toString()}',
        ),
      );

      // Small delay to show error
      await Future.delayed(const Duration(milliseconds: 500));

      // Restore with cached data if available
      if (_cachedDashboardData != null) {
        final filteredOrders = _applyFilter(
          _cachedDashboardData!.recentOrders,
          _currentFilter,
        );

        emit(
          DashboardLoaded(
            dashboardData: _cachedDashboardData!,
            filteredOrders: filteredOrders,
            currentFilter: _currentFilter,
          ),
        );
      }
    }
  }

  DashboardErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return DashboardErrorType.network;
    }
    if (lowercaseError.contains('timeout')) {
      return DashboardErrorType.timeout;
    }
    if (lowercaseError.contains('not found') ||
        lowercaseError.contains('404')) {
      return DashboardErrorType.notFound;
    }
    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return DashboardErrorType.server;
    }
    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return DashboardErrorType.validation;
    }

    return DashboardErrorType.general;
  }
}
