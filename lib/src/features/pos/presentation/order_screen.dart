import 'package:animate_to/animate_to.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/theme/context_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/api_menu_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/api_menu_blocs/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/api_menu_blocs/state.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_cubit.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_state.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/order_session_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/pos_menu_categories.dart';
import 'package:sandwich_ai/src/features/pos/presentation/addtomenu.dart';
import 'package:sandwich_ai/src/features/pos/presentation/cash_approval_waiting.dart';
import 'package:sandwich_ai/src/features/pos/presentation/edit_menu.dart';
import 'package:sandwich_ai/src/features/pos/presentation/online_qr.dart';
import 'package:sandwich_ai/src/features/pos/presentation/order_summary.dart';
import 'package:sandwich_ai/src/features/pos/presentation/payment_method.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_order_dtls_dialoge.dart';
import 'package:sandwich_ai/src/features/pos/presentation/session_manager.dart';
import 'package:sandwich_ai/src/features/pos/presentation/special_req_dialogue.dart';

enum _OrderAction { editNote, park, clearItems, discard }

class OrderScreen extends StatefulWidget {
  final Future<void> Function()? onOpenSessionManager;

  const OrderScreen({super.key, this.onOpenSessionManager});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const String _menuItemOrderStoragePrefix = 'new_order_item_sort_order';

  late TabController _tabController;
  late final OrderSessionCubit _sessionCubit;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _orderNoteController = TextEditingController();
  final _animateToController = AnimateToController();
  Timer? _searchDebounce;

  final Map<String, int> _orderItems = {};
  final Map<String, String> _itemSpecialRequests = {};
  final Map<String, List<String>> _localMenuItemOrder = {};
  String? _lastKnownSessionId;
  String? _menuItemOrderStorageKey;
  bool _showUnavailableItems = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionCubit = context.read<OrderSessionCubit>();
    _tabController = TabController(length: 1, vsync: this);
    context.read<MenuItemsBloc>().add(const LoadMenuItems());
    _ensureActiveSession();
    unawaited(_loadLocalMenuItemOrder());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _syncToCubit();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sessionState = context.read<OrderSessionCubit>().state;
    final currentId = sessionState.activeSessionId;
    if (currentId != _lastKnownSessionId) {
      _restoreFromSession(sessionState.activeSession);
    }
  }

  void _ensureActiveSession() {
    final cubit = _sessionCubit;
    if (!cubit.state.hasActiveSession) {
      cubit.createSession();
    }
    _restoreFromSession(cubit.state.activeSession);
    _syncToCubit();
  }

  void _restoreFromSession(OrderSession? session) {
    if (session == null) return;

    setState(() {
      _orderItems
        ..clear()
        ..addAll(session.orderItems);
      _itemSpecialRequests
        ..clear()
        ..addAll(session.specialRequests);
      _orderNoteController.text = session.orderNote ?? '';
      _lastKnownSessionId = session.sessionId;
    });

    // If the cashier minimized mid-flow, navigate back to the right screen.
    if (session.isMinimized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resumeMinimizedSession(session);
      });
    }
  }

  /// Navigate back to whichever screen the cashier minimized from.
  void _resumeMinimizedSession(OrderSession session) {
    final cubit = _sessionCubit;
    final payment = session.paymentState;
    final details = session.orderDetails;

    // Clear the minimizedScreen flag immediately so it won't re-trigger
    // if the widget rebuilds before navigation completes.
    cubit.clearMinimizedScreen(session.sessionId);

    switch (session.minimizedScreen) {
      case MinimizedScreen.orderSummary:
        if (details == null) return;
        // Need menu items to reconstruct the orderedItemsMap.
        // We push OrderSummaryScreen directly â€” it only needs the data maps.
        final menuState = context.read<MenuItemsBloc>().state;
        final allItems = menuState is MenuItemsLoaded
            ? menuState.menuItems
            : (menuState is MenuItemsRefreshing
                  ? menuState.currentData
                  : <ApiMenuItem>[]);

        final orderedItemsMap = <ApiMenuItem, int>{};
        session.orderItems.forEach((itemId, qty) {
          final item = allItems.where((i) => i.id == itemId).firstOrNull;
          if (item != null) orderedItemsMap[item] = qty;
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<PosOrderBloc>(),
              child: OrderSummaryScreen(
                orderItems: orderedItemsMap,
                specialRequests: Map.from(session.specialRequests),
                orderType: details.orderType,
                tableNumber: details.tableNumber,
                customerName: details.customerName,
                customerPhone: details.customerPhone,
                discount: details.discount,
                specialInstructions: details.specialInstructions,
                sessionId: session.sessionId,
              ),
            ),
          ),
        );
        break;

      case MinimizedScreen.paymentMethod:
        if (details == null) return;
        final menuState = context.read<MenuItemsBloc>().state;
        final allItems = menuState is MenuItemsLoaded
            ? menuState.menuItems
            : (menuState is MenuItemsRefreshing
                  ? menuState.currentData
                  : <ApiMenuItem>[]);

        final orderedItemsMap = <ApiMenuItem, int>{};
        session.orderItems.forEach((itemId, qty) {
          final item = allItems.where((i) => i.id == itemId).firstOrNull;
          if (item != null) orderedItemsMap[item] = qty;
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<PosOrderBloc>()),
                BlocProvider.value(value: cubit),
              ],
              child: PaymentMethodScreen(
                orderItems: orderedItemsMap,
                specialRequests: Map.from(session.specialRequests),
                orderType: details.orderType,
                tableNumber: details.tableNumber,
                customerName: details.customerName,
                customerPhone: details.customerPhone,
                discount: details.discount,
                specialInstructions: details.specialInstructions,
                totalAmount: session.computeTotal(allItems),
                sessionId: session.sessionId,
              ),
            ),
          ),
        );
        break;

      case MinimizedScreen.cashWaiting:
        if (payment.cashTransaction == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: CashApprovalWaitingScreen(
                transaction: payment.cashTransaction,
                branchId: '',
                orderType: session.orderDetails?.orderType ?? '',
                tableNumber: session.orderDetails?.tableNumber,
                sessionId: session.sessionId,
              ),
            ),
          ),
        );
        break;

      case MinimizedScreen.onlineQr:
        if (payment.onlinePaymentInitData == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: OnlinePaymentQrScreen(
                initData: payment.onlinePaymentInitData,
                orderType: session.orderDetails?.orderType ?? '',
                tableNumber: session.orderDetails?.tableNumber,
                customerName: session.orderDetails?.customerName ?? 'Guest',
                sessionId: session.sessionId,
              ),
            ),
          ),
        );
        break;

      case null:
        break;
    }
  }

  void _syncToCubit() {
    _sessionCubit.updateActiveSessionItems(
      orderItems: Map.from(_orderItems),
      specialRequests: Map.from(_itemSpecialRequests),
      orderNote: _orderNoteController.text.trim(),
      clearOrderNote: _orderNoteController.text.trim().isEmpty,
    );
  }

  Future<void> _syncToLocalStorage() async {
    _syncToCubit();
    await _sessionCubit.saveSessionsToLocalStorage();
  }

  Future<void> _openSessionManager() async {
    await _syncToLocalStorage();
    if (!mounted) return;

    final openInTab = widget.onOpenSessionManager;
    if (openInTab != null) {
      await openInTab();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _sessionCubit,
          child: const SessionManagerScreen(),
        ),
      ),
    );

    if (mounted) {
      final sessionState = context.read<OrderSessionCubit>().state;
      if (sessionState.activeSessionId != _lastKnownSessionId) {
        _restoreFromSession(sessionState.activeSession);
      }
    }
  }

  // â”€â”€ Item management â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _addItem(String itemId) {
    _orderItems[itemId] = (_orderItems[itemId] ?? 0) + 1;
    _syncToCubit();
    setState(() {});
  }

  void _removeItem(String itemId) {
    if (_orderItems[itemId] != null && _orderItems[itemId]! > 0) {
      _orderItems[itemId] = _orderItems[itemId]! - 1;
      if (_orderItems[itemId] == 0) {
        _orderItems.remove(itemId);
        _itemSpecialRequests.remove(itemId);
      }
    }
    _syncToCubit();
    setState(() {});
  }

  void _clearAllItems() {
    _orderItems.clear();
    _itemSpecialRequests.clear();
    _syncToCubit();
    setState(() {});
  }

  void _clearVisibleOrder() {
    _orderItems.clear();
    _itemSpecialRequests.clear();
    _orderNoteController.clear();
    setState(() {});
  }

  Future<void> _addSpecialRequest(ApiMenuItem item) async {
    final existingRequest = _itemSpecialRequests[item.id];
    final request = await context.showSpecialRequestDialog(
      item: item,
      existingRequest: existingRequest,
    );
    if (request != null) {
      if (request.isEmpty) {
        _itemSpecialRequests.remove(item.id);
      } else {
        _itemSpecialRequests[item.id] = request;
      }
      _syncToCubit();
      setState(() {});
    }
  }

  Future<void> _editOrderNote() async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.modeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _OrderNoteSheet(initialNote: _orderNoteController.text),
    );

    if (result == null) return;
    if (!mounted) return;
    _orderNoteController.text = result;
    context.read<OrderSessionCubit>().updateActiveSessionNote(result);
    setState(() {});
  }

  void _parkOrder() {
    final hasWork =
        _orderItems.isNotEmpty || _orderNoteController.text.trim().isNotEmpty;
    if (!hasWork) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Add items or notes before holding an order.'),
          backgroundColor: context.modeWarning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _syncToCubit();
    context.read<OrderSessionCubit>().parkActiveSession();
    _clearVisibleOrder();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Order parked. Started a new order.'),
        backgroundColor: context.modeSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDiscardActiveOrder() {
    final session = context.read<OrderSessionCubit>().state.activeSession;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.modeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Discard Order?',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.modeTextPrimary,
          ),
        ),
        content: Text(
          'Discard "${session?.label ?? 'New Order'}"? This will remove the current items and notes.',
          style: WorkSansAppTextStyles.medium.copyWith(
            color: context.modeTextSecondary,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: WorkSansAppTextStyles.medium.copyWith(
                color: context.modeTextSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (session != null) {
                context.read<OrderSessionCubit>().discardSession(
                  session.sessionId,
                );
              } else {
                context.read<OrderSessionCubit>().createSession();
              }
              _clearVisibleOrder();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.modeError,
              foregroundColor: context.modeTextInverse,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _syncToCubit();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _orderNoteController.dispose();
    _animateToController.dispose();
    super.dispose();
  }

  void _recreateTabController(int length, {bool notify = true}) {
    if (!mounted) return;
    final safeLength = length < 1 ? 1 : length;
    final oldIndex = _tabController.index;
    _tabController.dispose();
    _tabController = TabController(
      length: safeLength,
      vsync: this,
      initialIndex: oldIndex < safeLength ? oldIndex : 0,
    );
    if (notify) setState(() {});
  }

  List<ApiMenuItem> _getOrderedItems(List<ApiMenuItem> allItems) {
    return _sortMenuItems(
      allItems,
      null,
    ).where((item) => _orderItems.containsKey(item.id)).toList();
  }

  String _menuItemOrderKey(String? category) {
    final normalized = category?.trim();
    return normalized == null || normalized.isEmpty ? '__all__' : normalized;
  }

  List<ApiMenuItem> _sortMenuItems(List<ApiMenuItem> items, String? category) {
    final savedOrder =
        _localMenuItemOrder[_menuItemOrderKey(category)] ??
        (category == null
            ? null
            : _localMenuItemOrder[_menuItemOrderKey(null)]);
    if (savedOrder == null || savedOrder.isEmpty) return List.of(items);

    final originalIndex = <String, int>{
      for (var i = 0; i < items.length; i++) items[i].id: i,
    };

    return List<ApiMenuItem>.from(items)..sort((a, b) {
      final aIndex = savedOrder.indexOf(a.id);
      final bIndex = savedOrder.indexOf(b.id);
      if (aIndex == -1 && bIndex == -1) {
        return (originalIndex[a.id] ?? 0).compareTo(originalIndex[b.id] ?? 0);
      }
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });
  }

  Future<void> _loadLocalMenuItemOrder() async {
    final userId = await AuthCacheHelper.instance.userID();
    final storageKey =
        '$_menuItemOrderStoragePrefix:${userId?.isNotEmpty == true ? userId : 'guest'}';
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(storageKey);
    if (!mounted) return;

    setState(() {
      _menuItemOrderStorageKey = storageKey;
      _localMenuItemOrder.clear();
      if (encoded == null || encoded.isEmpty) return;

      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return;
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is List) {
          _localMenuItemOrder[entry.key.toString()] = value
              .map((item) => item.toString())
              .toList();
        }
      }
    });
  }

  List<String> _mergeMenuItemOrder(
    List<String>? existingOrder,
    List<String> sortedVisibleIds,
  ) {
    final visibleIdSet = sortedVisibleIds.toSet();
    return [
      ...sortedVisibleIds,
      ...?existingOrder?.where((id) => !visibleIdSet.contains(id)),
    ];
  }

  Future<void> _saveLocalMenuItemOrder() async {
    final storageKey = _menuItemOrderStorageKey;
    if (storageKey == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(_localMenuItemOrder));
  }

  List<String> _orderedCategoriesFor(List<ApiMenuItem> menuItems) {
    final availableCategories = menuItems.map((item) => item.category).toSet();
    final customCategories =
        availableCategories
            .where((category) => !PosMenuCategories.names.contains(category))
            .where((category) => category.trim().isNotEmpty)
            .toList()
          ..sort();
    return [...PosMenuCategories.names, ...customCategories];
  }

  double _calculateTotal(List<ApiMenuItem> allItems) {
    double total = 0;
    _orderItems.forEach((itemId, quantity) {
      final item = allItems.where((i) => i.id == itemId).firstOrNull;
      if (item == null) return;
      total += (double.tryParse(item.price) ?? 0) * quantity;
    });
    return total;
  }

  Future<void> _proceedToCheckout(List<ApiMenuItem> allItems) async {
    _syncToCubit();

    final totalAmount = _calculateTotal(allItems);
    final orderDetails = await context.showPosOrderDetailsDialog(
      orderItems: _orderItems,
      totalAmount: totalAmount,
    );

    if (orderDetails != null) {
      if (!mounted) return;
      context.read<OrderSessionCubit>().confirmActiveSessionDetails(
        orderDetails,
      );

      final orderedItemsMap = <ApiMenuItem, int>{};
      _orderItems.forEach((itemId, quantity) {
        final item = allItems.where((i) => i.id == itemId).firstOrNull;
        if (item != null) {
          orderedItemsMap[item] = quantity;
        }
      });

      final sessionId = context.read<OrderSessionCubit>().state.activeSessionId;
      final orderNote = _orderNoteController.text.trim();
      final specialInstructions = orderNote.isNotEmpty
          ? orderNote
          : orderDetails.specialInstructions;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: context.read<PosOrderBloc>(),
            child: OrderSummaryScreen(
              orderItems: orderedItemsMap,
              specialRequests: Map<String, String>.from(_itemSpecialRequests),
              orderType: orderDetails.orderType,
              tableNumber: orderDetails.tableNumber,
              customerName: orderDetails.customerName,
              customerPhone: orderDetails.customerPhone,
              discount: orderDetails.discount,
              specialInstructions: specialInstructions,
              sessionId: sessionId,
            ),
          ),
        ),
      );
    }
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderSessionCubit, OrderSessionState>(
      listenWhen: (prev, curr) => prev.activeSessionId != curr.activeSessionId,
      listener: (context, state) {
        _restoreFromSession(state.activeSession);
      },
      child: DefaultTextStyle.merge(
        style: WorkSansAppTextStyles.medium,
        child: Scaffold(
          backgroundColor: context.modeBackground,
          appBar: _buildAppBar(),
          body: BlocConsumer<MenuItemsBloc, MenuItemsState>(
            listenWhen: (previous, current) {
              if (previous is MenuItemsLoaded && current is MenuItemsLoaded) {
                final prevLen = previous.menuItems
                    .map((e) => e.category)
                    .toSet()
                    .length;
                final currLen = current.menuItems
                    .map((e) => e.category)
                    .toSet()
                    .length;
                return prevLen != currLen;
              }
              return current is MenuItemsLoaded;
            },
            listener: (context, state) {
              if (state is MenuItemsLoaded) {
                final categories = _orderedCategoriesFor(state.menuItems);
                if (_tabController.length != categories.length) {
                  _recreateTabController(categories.length);
                }
              }
              if (state is MenuItemsError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: context.modeError,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is MenuItemsLoading) {
                return Center(
                  child: CircularProgressIndicator(color: context.modePrimary),
                );
              }
              if (state is MenuItemsEmpty || state is MenuItemsError) {
                return _buildErrorOrEmpty(state);
              }
              if (state is MenuItemsLoaded || state is MenuItemsRefreshing) {
                return _buildLoadedBody(state);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: context.modeBackground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 86,
      title: BlocBuilder<OrderSessionCubit, OrderSessionState>(
        builder: (context, sessionState) {
          final label = sessionState.activeSession?.label ?? 'Customer 1';
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(width: 4),
              AppIcon(
                Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: context.modeTextPrimary,
              ),
            ],
          );
        },
      ),
      centerTitle: true,
      leading: BlocBuilder<OrderSessionCubit, OrderSessionState>(
        builder: (context, sessionState) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: _buildHeaderIconButton(
                  icon: Icons.layers_outlined,
                  onTap: _openSessionManager,
                  tooltip: 'Sessions',
                ),
              ),
              if (sessionState.sessions.length > 1)
                Positioned(
                  top: 14,
                  right: 4,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: context.modePrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${sessionState.sessions.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: context.modeTextInverse,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      leadingWidth: 78,
      actions: [
        _buildHeaderIconButton(
          icon: Icons.refresh_rounded,
          onTap: () =>
              context.read<MenuItemsBloc>().add(const RefreshMenuItems()),
          tooltip: 'Refresh menu',
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isPrimary = false,
  }) {
    final bgColor = isPrimary
        ? context.modePrimary.withValues(alpha: 0.1)
        : context.modeSurface;
    final iconColor = isPrimary ? context.modePrimary : context.modeTextPrimary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.modeBorder.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: context.isDarkMode ? 0.2 : 0.04,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AppIcon(icon, size: 24, color: iconColor),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOrEmpty(MenuItemsState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(
            Icons.restaurant_menu,
            size: 80,
            color: context.modeTextMuted,
          ),
          const SizedBox(height: 16),
          Text(
            state is MenuItemsError ? state.error : 'No menu items available',
            textAlign: TextAlign.center,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 16,
              color: state is MenuItemsError
                  ? context.modeError
                  : context.modeTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                context.read<MenuItemsBloc>().add(const LoadMenuItems()),
            icon: const AppIcon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.modePrimary,
              foregroundColor: context.modeTextInverse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNoteBar() {
    final note = _orderNoteController.text.trim();
    return Material(
      color: context.modeSurface,
      child: InkWell(
        onTap: _editOrderNote,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: context.modeDivider),
              bottom: BorderSide(color: context.modeDivider),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.modePrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppIcon(
                  Icons.sticky_note_2_outlined,
                  size: 18,
                  color: context.modePrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.isEmpty ? 'Add Order Note' : 'Order Note',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: context.modeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note.isEmpty ? 'Tap to add kitchen/service notes' : note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: context.modeTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              AppIcon(Icons.edit_note_rounded, color: context.modeTextMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedBody(MenuItemsState state) {
    final menuItems = state is MenuItemsLoaded
        ? state.menuItems
        : (state as MenuItemsRefreshing).currentData;
    final filteredItems = state is MenuItemsLoaded
        ? state.filteredItems
        : menuItems;
    final categories = _orderedCategoriesFor(menuItems);
    if (_tabController.length != (categories.isEmpty ? 1 : categories.length)) {
      _recreateTabController(categories.length, notify: false);
    }
    final orderedItems = _getOrderedItems(menuItems);
    final hasOrders = orderedItems.isNotEmpty;
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            children: [
              _buildSearchCard(),
              if (categories.isNotEmpty && !isSearching) ...[
                const SizedBox(height: 6),
                _buildCategoryTabs(categories),
              ],
            ],
          ),
        ),
        if (state is MenuItemsRefreshing)
          LinearProgressIndicator(color: context.modePrimary),
        if (hasOrders || _orderNoteController.text.trim().isNotEmpty)
          _buildOrderNoteBar(),
        Expanded(
          child: categories.isEmpty
              ? Center(
                  child: Text(
                    'No menu items available',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 16,
                      color: context.modeTextSecondary,
                    ),
                  ),
                )
              : isSearching
              ? _buildMenuList(filteredItems, null)
              : TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _tabController,
                  children: categories
                      .map((cat) => _buildMenuList(filteredItems, cat))
                      .toList(),
                ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: hasOrders ? 75 : 0,
          child: ClipRect(
            child: IgnorePointer(
              ignoring: !hasOrders,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: context.modePrimary,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: context.isDarkMode ? 0.28 : 0.1,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Container(
                      height: 55,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimateTo(
                            controller: _animateToController,
                            child: Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: ListView.builder(
                                  reverse: true,
                                  scrollDirection: Axis.horizontal,
                                  clipBehavior: Clip.none,
                                  itemCount: orderedItems.length,
                                  itemBuilder: (context, index) {
                                    final item = orderedItems[index];
                                    final quantity = _orderItems[item.id] ?? 0;
                                    return _buildOrderItemPreview(
                                      item,
                                      quantity,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: double.infinity,
                            color: context.modeTextInverse.withValues(
                              alpha: 0.32,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _proceedToCheckout(menuItems),
                            child: Row(
                              children: [
                                Text(
                                  'View Order',
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.modeTextInverse,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                AppIcon(
                                  Icons.receipt_long_outlined,
                                  color: context.modeTextInverse,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: _showOrderActions,
                            child: AppIcon(
                              Icons.more_vert,
                              color: context.modeTextInverse,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showMenuItemOptions(ApiMenuItem item) {
    final isInOrder = _orderItems.containsKey(item.id);
    final isGlobalItem = item.isGlobal;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.modeBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.dishName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                if (isInOrder) ...[
                  _BottomSheetAction(
                    icon: Icons.edit_note,
                    label: _itemSpecialRequests.containsKey(item.id)
                        ? 'Edit Special Request'
                        : 'Add Special Request',
                    iconColor: context.modePrimary,
                    textColor: context.modeTextPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      _addSpecialRequest(item);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                if (isGlobalItem)
                  _BottomSheetAction(
                    icon: Icons.public,
                    label: 'Global item - cannot edit from branch',
                    iconColor: context.modeTextMuted,
                    textColor: context.modeTextMuted,
                    onTap: () => Navigator.pop(context),
                  )
                else
                  _BottomSheetAction(
                    icon: Icons.edit_outlined,
                    label: 'Edit Menu Item',
                    iconColor: context.modePrimary,
                    textColor: context.modeTextPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      context.showEditMenuItemDialog(item);
                    },
                  ),
                const SizedBox(height: 12),
                Divider(height: 1, color: context.modeDivider),
                const SizedBox(height: 4),
                _BottomSheetAction(
                  icon: Icons.close,
                  label: 'Cancel',
                  iconColor: context.modeTextMuted,
                  textColor: context.modeTextMuted,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showOrderActions() async {
    final action = await showModalBottomSheet<_OrderAction>(
      context: context,
      backgroundColor: context.modeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: AppIcon(
                  Icons.sticky_note_2_outlined,
                  color: sheetContext.modePrimary,
                ),
                title: Text(
                  _orderNoteController.text.trim().isEmpty
                      ? 'Add Order Note'
                      : 'Edit Order Note',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: sheetContext.modeTextPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, _OrderAction.editNote),
              ),
              Divider(height: 0, color: sheetContext.modeDivider),
              ListTile(
                leading: AppIcon(
                  Icons.pause_circle_outline,
                  color: sheetContext.modeWarning,
                ),
                title: Text(
                  'Hold Order',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: sheetContext.modeTextPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, _OrderAction.park),
              ),
              Divider(height: 0, color: sheetContext.modeDivider),
              ListTile(
                leading: AppIcon(
                  Icons.delete_sweep,
                  color: sheetContext.modePrimary,
                ),
                title: Text(
                  'Clear Items',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: sheetContext.modeError,
                  ),
                ),
                onTap: () =>
                    Navigator.pop(sheetContext, _OrderAction.clearItems),
              ),
              Divider(height: 0, color: sheetContext.modeDivider),
              ListTile(
                leading: AppIcon(
                  Icons.delete_forever_outlined,
                  color: sheetContext.modeError,
                ),
                title: Text(
                  'Discard Order',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: sheetContext.modeError,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, _OrderAction.discard),
              ),
              Divider(height: 0, color: sheetContext.modeDivider),
              ListTile(
                leading: AppIcon(
                  Icons.close,
                  color: sheetContext.modeTextSecondary,
                ),
                title: Text(
                  'Cancel',
                  style: TextStyle(color: sheetContext.modeTextPrimary),
                ),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _OrderAction.editNote:
        await _editOrderNote();
        break;
      case _OrderAction.park:
        _parkOrder();
        break;
      case _OrderAction.clearItems:
        _clearAllItems();
        break;
      case _OrderAction.discard:
        _confirmDiscardActiveOrder();
        break;
    }
  }

  Widget _buildSearchCard() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.22 : 0.05,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        cursorColor: context.modePrimary,
        style: WorkSansAppTextStyles.medium.copyWith(
          color: context.modeTextPrimary,
        ),
        controller: _searchController,
        onChanged: (value) {
          setState(() {});
          _searchDebounce?.cancel();
          _searchDebounce = Timer(const Duration(milliseconds: 450), () {
            if (!mounted) return;
            context.read<MenuItemsBloc>().add(SearchMenuItems(query: value));
          });
        },
        decoration: InputDecoration(
          hintText: 'Search menu items...',
          hintStyle: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: context.modeTextMuted,
          ),
          prefixIcon: AppIconSlot(
            Icons.search_rounded,
            color: context.modeTextPrimary,
            size: 22,
          ),
          prefixIconConstraints: AppIconSlot.constraints(),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: AppIconSlot(
                    Icons.close_rounded,
                    color: context.modeTextMuted,
                    width: 24,
                  ),
                  onPressed: () {
                    _searchDebounce?.cancel();
                    _searchController.clear();
                    setState(() {});
                    context.read<MenuItemsBloc>().add(
                      const SearchMenuItems(query: ''),
                    );
                  },
                )
              : IconButton(
                  tooltip: _showUnavailableItems
                      ? 'Available items only'
                      : 'Show unavailable items',
                  icon: AppIconSlot(
                    Icons.tune_rounded,
                    color: context.modeTextPrimary,
                    size: 20,
                    width: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _showUnavailableItems = !_showUnavailableItems;
                    });
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(List<String> categories) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.2 : 0.04,
            ),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        padding: EdgeInsets.zero,
        onTap: (index) {
          setState(() {});
          context.read<MenuItemsBloc>().add(
            FilterMenuItemsByCategory(category: categories[index]),
          );
        },
        labelColor: context.modePrimary,
        unselectedLabelColor: context.modeTextMuted,
        indicatorColor: context.modePrimary,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          final isSelected = _tabController.index == index;
          final tabColor = isSelected
              ? context.modePrimary
              : context.modeTextMuted;
          return Tab(
            height: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PosMenuCategoryIcon(category: cat, color: tabColor, size: 20),
                const SizedBox(height: 4),
                Text(
                  cat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: tabColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuList(List<ApiMenuItem> items, String? category) {
    final categoryItems = _sortMenuItems(
      items
          .where((item) => category == null || item.category == category)
          .where((item) => _showUnavailableItems || item.isAvailable)
          .toList(),
      category,
    );
    if (categoryItems.isEmpty) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
          child: Text(
            category == null
                ? 'No menu items found'
                : _showUnavailableItems
                ? 'No items in this category'
                : 'No available items in this category',
            textAlign: TextAlign.center,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 16,
              color: context.modeTextSecondary,
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      category ?? 'Search Results',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.modeTextPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.modePrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${categoryItems.length} item${categoryItems.length == 1 ? '' : 's'}',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.modePrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => context.showAddMenuItemDialog(),
                icon: const AppIcon(Icons.add_rounded, size: 20),
                label: const Text('Add Item'),
                style: TextButton.styleFrom(
                  foregroundColor: context.modePrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) {
              return Material(
                color: Colors.transparent,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1, end: 1.02).animate(animation),
                  child: child,
                ),
              );
            },
            onReorder: (oldIndex, newIndex) => _handleMenuItemReorder(
              categoryItems,
              category,
              oldIndex,
              newIndex,
            ),
            itemCount: categoryItems.length,
            itemBuilder: (context, index) {
              final item = categoryItems[index];
              final quantity = _orderItems[item.id] ?? 0;
              return _buildMenuItem(
                item,
                quantity,
                quantity > 0,
                reorderIndex: index,
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleMenuItemReorder(
    List<ApiMenuItem> items,
    String? category,
    int oldIndex,
    int newIndex,
  ) {
    if (items.length < 2) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex < 0 ||
        oldIndex >= items.length ||
        newIndex < 0 ||
        newIndex >= items.length) {
      return;
    }

    final draftItems = List<ApiMenuItem>.from(items);
    final movedItem = draftItems.removeAt(oldIndex);
    draftItems.insert(newIndex, movedItem);

    setState(() {
      final sortedVisibleIds = draftItems.map((item) => item.id).toList();
      final categoryKey = _menuItemOrderKey(category);
      final globalKey = _menuItemOrderKey(null);

      _localMenuItemOrder[categoryKey] = _mergeMenuItemOrder(
        _localMenuItemOrder[categoryKey],
        sortedVisibleIds,
      );
      _localMenuItemOrder[globalKey] = _mergeMenuItemOrder(
        _localMenuItemOrder[globalKey],
        sortedVisibleIds,
      );
    });
    unawaited(_saveLocalMenuItemOrder());
  }

  Widget _buildAvailabilityBadge(bool isAvailable) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 86),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? context.modeSuccess.withValues(alpha: 0.12)
            : context.modeError.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isAvailable ? context.modeSuccess : context.modeError,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              isAvailable ? 'Available' : 'Unavailable',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isAvailable ? context.modeSuccess : context.modeError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.modeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(Icons.public_rounded, size: 12, color: context.modeTextMuted),
          const SizedBox(width: 5),
          Text(
            'Global',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: context.modeTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemImage(ApiMenuItem item, bool isAvailable) {
    final imageUrl = item.imageUrl.trim();
    if (imageUrl.isEmpty) {
      return Center(
        child: AppIcon(
          Icons.restaurant_menu_rounded,
          size: 30,
          color: isAvailable ? context.modePrimary : context.modeTextMuted,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: context.modePrimary.withValues(alpha: 0.08),
          alignment: Alignment.center,
          child: AppIcon(
            Icons.restaurant_menu_rounded,
            size: 30,
            color: isAvailable ? context.modePrimary : context.modeTextMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderPreviewImage(ApiMenuItem item) {
    final imageUrl = item.imageUrl.trim();
    if (imageUrl.isEmpty) {
      return Container(
        color: context.modeSurfaceAlt,
        child: Center(
          child: AppIcon(
            Icons.restaurant,
            size: 24,
            color: context.modeTextMuted,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: context.modeSurfaceAlt,
        child: Center(
          child: AppIcon(
            Icons.restaurant,
            size: 24,
            color: context.modeTextMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    ApiMenuItem item,
    int quantity,
    bool isAdded, {
    required int reorderIndex,
  }) {
    final hasSpecialRequest = _itemSpecialRequests.containsKey(item.id);
    final isAvailable = item.isAvailable;
    return Container(
      key: ValueKey('menu-item-${item.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.22 : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: () => _showMenuItemOptions(item),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: context.modePrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimateFrom(
                    key: _animateToController.tag(item),
                    child: _buildMenuItemImage(item, isAvailable),
                  ),
                  if (!isAvailable)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Center(
                        child: AppIcon(
                          Icons.block_rounded,
                          color: Colors.white.withValues(alpha: 0.92),
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onLongPress: () => _showMenuItemOptions(item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.dishName,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isAvailable
                                ? context.modeTextPrimary
                                : context.modeTextMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasSpecialRequest && isAdded)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.modePrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: AppIcon(
                              Icons.edit_note,
                              size: 14,
                              color: context.modePrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '₦${item.price}',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isAvailable
                              ? context.modeTextSecondary
                              : context.modeTextMuted,
                        ),
                      ),
                      _buildAvailabilityBadge(isAvailable),
                      if (item.isGlobal) _buildGlobalBadge(),
                    ],
                  ),
                  if (hasSpecialRequest && isAdded) ...[
                    const SizedBox(height: 4),
                    Text(
                      _itemSpecialRequests[item.id]!,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: context.modePrimary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Center(
              child: AppIcon(
                Icons.more_vert_rounded,
                color: context.modeTextPrimary,
                size: 20,
              ),
            ),
            onPressed: () => _showMenuItemOptions(item),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          ReorderableDragStartListener(
            index: reorderIndex,
            child: Tooltip(
              message: 'Drag to sort',
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: AppIcon(
                    Icons.drag_handle_rounded,
                    color: context.modeTextMuted,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (!isAvailable && !isAdded)
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.modeSurfaceAlt,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: context.modeBorder),
              ),
              child: Center(
                child: AppIcon(
                  Icons.block,
                  size: 18,
                  color: context.modeTextMuted,
                ),
              ),
            )
          else if (!isAdded)
            InkWell(
              onTap: () {
                _animateToController.animateTag(item);
                _addItem(item.id);
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.modeSurface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: context.modePrimary.withValues(alpha: 0.18),
                  ),
                ),
                child: Center(
                  child: AppIcon(
                    Icons.add_rounded,
                    size: 23,
                    color: context.modePrimary,
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: context.modeSurface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: context.modeBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _removeItem(item.id),
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      child: Center(
                        child: AppIcon(
                          Icons.remove_rounded,
                          size: 18,
                          color: context.modePrimary,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    child: Text(
                      '$quantity',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.modeTextPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: isAvailable
                        ? () {
                            _addItem(item.id);
                            _animateToController.animateTag(item);
                          }
                        : null,
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      child: Center(
                        child: AppIcon(
                          Icons.add,
                          size: 18,
                          color: isAvailable
                              ? context.modeTextPrimary
                              : context.modeTextMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItemPreview(ApiMenuItem item, int quantity) {
    return Container(
      width: 53,
      height: 53,
      margin: const EdgeInsets.only(right: 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: context.modeBorder, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: _buildOrderPreviewImage(item),
            ),
          ),
          Positioned(
            top: -6,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.modeSurface,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              child: Center(
                child: Text(
                  '$quantity',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.modePrimary,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderNoteSheet extends StatefulWidget {
  final String initialNote;

  const _OrderNoteSheet({required this.initialNote});

  @override
  State<_OrderNoteSheet> createState() => _OrderNoteSheetState();
}

class _OrderNoteSheetState extends State<_OrderNoteSheet> {
  late String _draftNote;

  @override
  void initState() {
    super.initState();
    _draftNote = widget.initialNote;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Notes',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.initialNote,
              maxLines: 4,
              autofocus: true,
              cursorColor: context.modePrimary,
              onChanged: (value) => setState(() => _draftNote = value),
              style: WorkSansAppTextStyles.medium.copyWith(
                color: context.modeTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Add kitchen or service notes...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  color: context.modeTextMuted,
                ),
                filled: true,
                fillColor: context.modeSurfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.modeBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.modePrimary),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (_draftNote.trim().isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(''),
                    child: Text(
                      'Clear',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        color: context.modeError,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(
                    'Cancel',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      color: context.modeTextSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_draftNote.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.modePrimary,
                    foregroundColor: context.modeTextInverse,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  const _BottomSheetAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: context.modeBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AppIcon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
