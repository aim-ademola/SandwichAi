import 'package:animate_to/animate_to.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
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
import 'package:sandwich_ai/src/features/pos/presentation/addtomenu.dart';
import 'package:sandwich_ai/src/features/pos/presentation/cash_approval_waiting.dart';
import 'package:sandwich_ai/src/features/pos/presentation/delete_menu.dart';
import 'package:sandwich_ai/src/features/pos/presentation/edit_menu.dart';
import 'package:sandwich_ai/src/features/pos/presentation/online_qr.dart';
import 'package:sandwich_ai/src/features/pos/presentation/order_summary.dart';
import 'package:sandwich_ai/src/features/pos/presentation/payment_method.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_order_dtls_dialoge.dart';
import 'package:sandwich_ai/src/features/pos/presentation/session_manager.dart';
import 'package:sandwich_ai/src/features/pos/presentation/special_req_dialogue.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final _animateToController = AnimateToController();
  Timer? _searchDebounce;

  final Map<String, int> _orderItems = {};
  final Map<String, String> _itemSpecialRequests = {};
  String? _lastKnownSessionId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    context.read<MenuItemsBloc>().add(const LoadMenuItems());
    _ensureActiveSession();
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
    final cubit = context.read<OrderSessionCubit>();
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
    final cubit = context.read<OrderSessionCubit>();
    final payment = session.paymentState;
    final details = session.orderDetails;

    // Clear the minimizedScreen flag immediately so it won't re-trigger
    // if the widget rebuilds before navigation completes.
    cubit.clearMinimizedScreen(session.sessionId);

    switch (session.minimizedScreen) {
      case MinimizedScreen.orderSummary:
        if (details == null) return;
        // Need menu items to reconstruct the orderedItemsMap.
        // We push OrderSummaryScreen directly — it only needs the data maps.
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
    context.read<OrderSessionCubit>().updateActiveSessionItems(
      orderItems: Map.from(_orderItems),
      specialRequests: Map.from(_itemSpecialRequests),
    );
  }

  Future<void> _openSessionManager() async {
    _syncToCubit();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<OrderSessionCubit>(),
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

  // ── Item management ───────────────────────────────────────────────────────

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

  @override
  void dispose() {
    _tabController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _animateToController.dispose();
    super.dispose();
  }

  void _recreateTabController(int length) {
    if (!mounted) return;
    final oldIndex = _tabController.index;
    _tabController.dispose();
    _tabController = TabController(
      length: length,
      vsync: this,
      initialIndex: oldIndex < length ? oldIndex : 0,
    );
    setState(() {});
  }

  List<ApiMenuItem> _getOrderedItems(List<ApiMenuItem> allItems) {
    return allItems.where((item) => _orderItems.containsKey(item.id)).toList();
  }

  double _calculateTotal(List<ApiMenuItem> allItems) {
    double total = 0;
    _orderItems.forEach((itemId, quantity) {
      final item = allItems.firstWhere((i) => i.id == itemId);
      total += double.parse(item.price) * quantity;
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
      context.read<OrderSessionCubit>().confirmActiveSessionDetails(
        orderDetails,
      );

      final orderedItemsMap = <ApiMenuItem, int>{};
      _orderItems.forEach((itemId, quantity) {
        final item = allItems.firstWhere((i) => i.id == itemId);
        orderedItemsMap[item] = quantity;
      });

      final sessionId = context.read<OrderSessionCubit>().state.activeSessionId;

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
              specialInstructions: orderDetails.specialInstructions,
              sessionId: sessionId,
            ),
          ),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
                final categories =
                    state.menuItems.map((e) => e.category).toSet().toList()
                      ..sort();
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
      backgroundColor: context.modeSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: BlocBuilder<OrderSessionCubit, OrderSessionState>(
        builder: (context, sessionState) {
          final label = sessionState.activeSession?.label ?? 'New Order';
          return Column(
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
              if (sessionState.sessions.length > 1)
                Text(
                  '${sessionState.sessions.length} sessions open',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 11,
                    color: context.modeTextMuted,
                  ),
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
              IconButton(
                icon: Icon(
                  Icons.layers_outlined,
                  color: context.modeTextPrimary,
                ),
                onPressed: _openSessionManager,
                tooltip: 'Sessions',
              ),
              if (sessionState.sessions.length > 1)
                Positioned(
                  top: 8,
                  right: 8,
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
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: context.modeTextPrimary),
          onPressed: () =>
              context.read<MenuItemsBloc>().add(const RefreshMenuItems()),
        ),
        IconButton(
          icon: Icon(Icons.add, color: context.modeTextPrimary),
          onPressed: context.showAddMenuItemDialog,
        ),
      ],
    );
  }

  Widget _buildErrorOrEmpty(MenuItemsState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: context.modeTextMuted),
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
            icon: const Icon(Icons.refresh),
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

  Widget _buildLoadedBody(MenuItemsState state) {
    final menuItems = state is MenuItemsLoaded
        ? state.menuItems
        : (state as MenuItemsRefreshing).currentData;
    final filteredItems = state is MenuItemsLoaded
        ? state.filteredItems
        : menuItems;
    final categories = menuItems.map((item) => item.category).toSet().toList()
      ..sort();
    final orderedItems = _getOrderedItems(menuItems);
    final hasOrders = orderedItems.isNotEmpty;

    return Column(
      children: [
        Container(
          color: context.modeSurface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                context.read<MenuItemsBloc>().add(
                  SearchMenuItems(query: value),
                );
              });
            },
            decoration: InputDecoration(
              hintText: 'Search menu',
              hintStyle: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextMuted,
              ),
              prefixIcon: Icon(Icons.search, color: context.modeTextMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: context.modeTextMuted),
                      onPressed: () {
                        _searchDebounce?.cancel();
                        _searchController.clear();
                        setState(() {});
                        context.read<MenuItemsBloc>().add(
                          const SearchMenuItems(query: ''),
                        );
                      },
                    )
                  : null,
              filled: true,
              fillColor: context.modeSurfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.modeBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.modeBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.modePrimary),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (categories.isNotEmpty)
          Container(
            color: context.modeSurface,
            child: TabBar(
              controller: _tabController,
              onTap: (index) => context.read<MenuItemsBloc>().add(
                FilterMenuItemsByCategory(category: categories[index]),
              ),
              labelColor: context.modePrimary,
              unselectedLabelColor: context.modeTextMuted,
              indicatorColor: context.modePrimary,
              indicatorWeight: 3,
              isScrollable: categories.length > 4,
              tabs: categories.map((cat) => Tab(text: cat)).toList(),
            ),
          ),
        if (state is MenuItemsRefreshing)
          LinearProgressIndicator(color: context.modePrimary),
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
                                SvgPicture.asset('assets/svg/view_order.svg'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: _showOrderActions,
                            child: Icon(
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
                const SizedBox(height: 8),
                _BottomSheetAction(
                  icon: Icons.delete_outline,
                  label: 'Delete Menu Item',
                  iconColor: context.modeError,
                  textColor: context.modeError,
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    context.showDeleteMenuItemDialog(item);
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

  void _showOrderActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.modeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: SvgPicture.asset(
                  'assets/svg/delete.svg',
                  // ignore: deprecated_member_use
                  color: context.modePrimary,
                ),
                title: Text(
                  'Clear Order items',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.modeError,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _clearAllItems();
                },
              ),
              Divider(height: 0, color: context.modeDivider),
              ListTile(
                leading: Icon(Icons.close, color: context.modeTextSecondary),
                title: Text(
                  'Cancel',
                  style: TextStyle(color: context.modeTextPrimary),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList(List<ApiMenuItem> items, String category) {
    final categoryItems = items
        .where((item) => item.category == category)
        .toList();
    if (categoryItems.isEmpty) {
      return Center(
        child: Text(
          'No items in this category',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 16,
            color: context.modeTextSecondary,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categoryItems.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              category,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
          );
        }
        final item = categoryItems[index - 1];
        final quantity = _orderItems[item.id] ?? 0;
        return _buildMenuItem(item, quantity, quantity > 0);
      },
    );
  }

  Widget _buildMenuItem(ApiMenuItem item, int quantity, bool isAdded) {
    final hasSpecialRequest = _itemSpecialRequests.containsKey(item.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: () => _showMenuItemOptions(item),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: context.isDarkMode ? 0.24 : 0.08,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: KeyedSubtree(
                  key: ValueKey(item.id),
                  child: AnimateFrom(
                    key: _animateToController.tag(item),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: context.modeSurfaceAlt,
                        child: Icon(
                          Icons.restaurant,
                          size: 40,
                          color: context.modeTextMuted,
                        ),
                      ),
                    ),
                  ),
                ),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.modeTextPrimary,
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
                          child: Icon(
                            Icons.edit_note,
                            size: 14,
                            color: context.modePrimary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${item.price}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.modeTextSecondary,
                    ),
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
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.more_vert, color: context.modeTextMuted, size: 20),
            onPressed: () => _showMenuItemOptions(item),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          if (!isAdded)
            InkWell(
              onTap: () {
                _animateToController.animateTag(item);
                _addItem(item.id);
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: context.modeSurface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: context.modeBorder),
                ),
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: context.modeTextPrimary,
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
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/svg/delete.svg',
                        color: context.modePrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
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
                    onTap: () {
                      _addItem(item.id);
                      _animateToController.animateTag(item);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.add,
                        size: 18,
                        color: context.modeTextPrimary,
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
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: context.modeSurfaceAlt,
                  child: Icon(
                    Icons.restaurant,
                    size: 24,
                    color: context.modeTextMuted,
                  ),
                ),
              ),
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

class _BottomSheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final bool isDestructive;
  final VoidCallback onTap;

  const _BottomSheetAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    this.isDestructive = false,
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
          border: Border.all(
            color: isDestructive
                ? context.modeError.withValues(alpha: 0.2)
                : context.modeBorder,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
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
