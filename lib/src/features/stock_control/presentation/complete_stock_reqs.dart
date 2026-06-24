import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/stock_reuest_model.dart';
import 'package:sandwich_ai/src/features/processing/presentation/stock_req_details.dart';

// Each tab maps to one API status value (null = All).
class _TabDef {
  final String label;
  final String? apiStatus;
  final bool showActions;

  const _TabDef({
    required this.label,
    required this.apiStatus,
    required this.showActions,
  });
}

const List<_TabDef> _tabs = [
  _TabDef(label: 'All', apiStatus: null, showActions: true),
  _TabDef(label: 'Pending', apiStatus: 'PENDING', showActions: true),
  _TabDef(label: 'Approved', apiStatus: 'APPROVED', showActions: true),
  _TabDef(label: 'In Queue', apiStatus: 'IN_QUEUE', showActions: true),
  _TabDef(label: 'Processing', apiStatus: 'PROCESSING', showActions: true),
  _TabDef(label: 'Completed', apiStatus: 'COMPLETED', showActions: false),
  _TabDef(label: 'Rejected', apiStatus: 'REJECTED', showActions: false),
  _TabDef(label: 'Cancelled', apiStatus: 'CANCELLED', showActions: false),
];

class CompleteStockRequestDetailsScreen extends StatefulWidget {
  const CompleteStockRequestDetailsScreen({super.key});

  @override
  State<CompleteStockRequestDetailsScreen> createState() =>
      _CompleteStockRequestDetailsScreenState();
}

class _CompleteStockRequestDetailsScreenState
    extends State<CompleteStockRequestDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // The API status for the currently selected tab.
  String? get _currentApiStatus => _tabs[_tabController.index].apiStatus;
  bool get _currentShowActions => _tabs[_tabController.index].showActions;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Load all requests on open
    context.read<StockRequestBloc>().add(LoadStockRequests(branchId: ''));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // Re-fetch from API with the selected status filter.
      // Passing null = no filter = all results.
      context.read<StockRequestBloc>().add(
        LoadStockRequests(branchId: '', status: _currentApiStatus),
      );
    }
  }

  Future<void> _onRefresh() async {
    context.read<StockRequestBloc>().add(
      RefreshStockRequests(branchId: '', status: _currentApiStatus),
    );
  }

  void _navigateToDetails(StockRequest request) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => StockRequestDetailsScreen(request: request),
      ),
    );
  }

  void _handleAction(StockRequest request, StockRequestAction action) {
    final config = _dialogConfigFor(action, request.requestId);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          config.title,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          config.body,
          style: WorkSansAppTextStyles.medium.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: kprimaryTextColor2)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<StockRequestBloc>().add(
                PerformStockRequestAction(
                  requestId: request.id,
                  action: action,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: config.confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(config.confirmLabel),
          ),
        ],
      ),
    );
  }

  _ActionDialogConfig _dialogConfigFor(
    StockRequestAction action,
    String requestId,
  ) {
    return switch (action) {
      StockRequestAction.approve => _ActionDialogConfig(
        title: 'Approve Request',
        body:
            'Are you sure you want to approve $requestId?\n\nThis will mark the request as approved.',
        confirmLabel: 'Approve',
        confirmColor: const Color(0xFF42A5F5),
      ),
      StockRequestAction.queue => _ActionDialogConfig(
        title: 'Send to Queue',
        body:
            'Are you sure you want to queue $requestId?\n\nThis will move the request to the processing queue.',
        confirmLabel: 'Send to Queue',
        confirmColor: const Color(0xFFAB47BC),
      ),
      StockRequestAction.process => _ActionDialogConfig(
        title: 'Start Processing',
        body:
            'Are you sure you want to start processing $requestId?\n\nThis will move the request to PROCESSING status.',
        confirmLabel: 'Start Processing',
        confirmColor: const Color(0xFF26A69A),
      ),
      StockRequestAction.complete => _ActionDialogConfig(
        title: 'Complete Transfer',
        body:
            'Are you sure you want to complete the transfer for $requestId?\n\nThis will mark all items as transferred and complete the request.',
        confirmLabel: 'Complete Transfer',
        confirmColor: kPrimary,
      ),
      StockRequestAction.reject => _ActionDialogConfig(
        title: 'Reject Request',
        body:
            'Are you sure you want to reject $requestId?\n\nThis action cannot be undone.',
        confirmLabel: 'Reject',
        confirmColor: const Color(0xFFEF5350),
      ),
      StockRequestAction.cancel => _ActionDialogConfig(
        title: 'Cancel Request',
        body:
            'Are you sure you want to cancel $requestId?\n\nThis action cannot be undone.',
        confirmLabel: 'Cancel Request',
        confirmColor: const Color(0xFFEF5350),
      ),
    };
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F6F6),
          appBar: _buildAppBar(screenWidth),
          body: Column(
            children: [
              _buildTabBar(screenWidth),
              Expanded(
                child: BlocConsumer<StockRequestBloc, StockRequestState>(
                  listener: (context, state) {
                    if (state is StockRequestError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error),
                          backgroundColor: const Color(0xFFE53935),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (state is StockRequestActionSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: kGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      // Reload current tab after a successful action
                      context.read<StockRequestBloc>().add(
                        LoadStockRequests(
                          branchId: '',
                          status: _currentApiStatus,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    // Loading spinner
                    if (state is StockRequestLoading) {
                      return _buildLoadingState();
                    }

                    // Empty
                    if (state is StockRequestEmpty) {
                      return _buildEmptyState(screenWidth);
                    }

                    // Any state that carries a request list
                    if (state is StockRequestListLoaded ||
                        state is StockRequestRefreshing ||
                        state is StockRequestActionInProgress) {
                      final requests = _extractRequests(state);
                      final isRefreshing = state is StockRequestRefreshing;

                      if (requests.isEmpty) {
                        return _buildEmptyState(screenWidth);
                      }

                      // All tabs share the same list — the API already
                      // filtered it by status when the tab was tapped.
                      // We just render the list with the correct showActions
                      // flag for the current tab.
                      return _buildRequestsList(
                        requests,
                        screenWidth,
                        isRefreshing,
                        state,
                        showActions: _currentShowActions,
                      );
                    }

                    return _buildEmptyState(screenWidth);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── State helpers ────────────────────────────────────────────────────────

  List<StockRequest> _extractRequests(StockRequestState state) {
    if (state is StockRequestListLoaded) return state.requests;
    if (state is StockRequestRefreshing) return state.currentRequests;
    if (state is StockRequestActionInProgress) return state.currentRequests;
    if (state is StockRequestActionSuccess) return state.currentRequests;
    return [];
  }

  bool _isActionInProgress(
    StockRequestState state,
    String requestId,
    StockRequestAction action,
  ) =>
      state is StockRequestActionInProgress &&
      state.requestId == requestId &&
      state.action == action;

  bool _isAnyActionInProgress(StockRequestState state, String requestId) =>
      state is StockRequestActionInProgress && state.requestId == requestId;

  // ─── App Bar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(double screenWidth) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: kprimaryTextColor1,
          size: _getIconSize(screenWidth),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Stock Requests',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getAppBarTitleFontSize(screenWidth),
          fontWeight: FontWeight.w600,
          color: kprimaryTextColor1,
        ),
      ),
      centerTitle: true,
    );
  }

  // ─── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar(double screenWidth) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: kPrimary,
        unselectedLabelColor: kprimaryTextColor2,
        indicatorColor: kPrimary,
        indicatorWeight: 3,
        labelStyle: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getTabFontSize(screenWidth),
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getTabFontSize(screenWidth),
          fontWeight: FontWeight.w500,
        ),
        tabs: _tabs.map((t) => Tab(child: _buildTabLabel(t))).toList(),
      ),
    );
  }

  Widget _buildTabLabel(_TabDef tab) {
    if (tab.apiStatus == null) return Text(tab.label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getStatusColor(tab.apiStatus!),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(tab.label),
      ],
    );
  }

  // ─── Loading / Empty ──────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_getHorizontalPadding(screenWidth)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: _getEmptyIconSize(screenWidth),
              height: _getEmptyIconSize(screenWidth),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: _getEmptyIconSize(screenWidth) * 0.5,
                color: kPrimary,
              ),
            ),
            SizedBox(height: _getSectionSpacing(screenWidth)),
            Text(
              'No stock requests',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getSectionTitleFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No requests found for this status',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                color: kprimaryTextColor2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── List ─────────────────────────────────────────────────────────────────

  Widget _buildRequestsList(
    List<StockRequest> requests,
    double screenWidth,
    bool isRefreshing,
    StockRequestState state, {
    bool showActions = true,
  }) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: kPrimary,
      child: ListView.builder(
        padding: EdgeInsets.all(_getHorizontalPadding(screenWidth)),
        itemCount: requests.length,
        itemBuilder: (context, index) => _buildRequestCard(
          requests[index],
          screenWidth,
          state,
          showActions: showActions,
        ),
      ),
    );
  }

  // ─── Card ─────────────────────────────────────────────────────────────────

  Widget _buildRequestCard(
    StockRequest request,
    double screenWidth,
    StockRequestState state, {
    bool showActions = true,
  }) {
    final anyInProgress = _isAnyActionInProgress(state, request.id);

    return Container(
      margin: EdgeInsets.only(bottom: _getFieldSpacing(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetails(request),
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        child: Padding(
          padding: EdgeInsets.all(_getCardPadding(screenWidth)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        request.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      request.requestId,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getCaptionFontSize(screenWidth),
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(request.status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(request.status, screenWidth),
                ],
              ),
              SizedBox(height: _getFieldSpacing(screenWidth)),
              _buildItemsSection(request, screenWidth),
              if (request.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: _getIconSize(screenWidth) - 2,
                      color: kprimaryTextColor2,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.notes,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: _getCaptionFontSize(screenWidth),
                          color: kprimaryTextColor2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: _getFieldSpacing(screenWidth)),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: _getFieldSpacing(screenWidth)),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.inventory_2_outlined,
                    label: '${request.totalItemsCount} Items',
                    screenWidth: screenWidth,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.shopping_cart_outlined,
                    label: '${request.totalQuantityRequested} Units',
                    screenWidth: screenWidth,
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(request.createdAt),
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getCaptionFontSize(screenWidth),
                      color: kprimaryTextColor2,
                    ),
                  ),
                ],
              ),
              if (showActions) ...[
                SizedBox(height: _getFieldSpacing(screenWidth)),
                _buildActionButtons(request, screenWidth, state, anyInProgress),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Action Buttons ───────────────────────────────────────────────────────

  Widget _buildActionButtons(
    StockRequest request,
    double screenWidth,
    StockRequestState state,
    bool anyInProgress,
  ) {
    final List<_ActionButtonConfig> actions = switch (request.status
        .toUpperCase()) {
      'PENDING' => [
        _ActionButtonConfig(
          action: StockRequestAction.approve,
          label: 'Approve',
          icon: Icons.check_circle_outline,
          color: const Color(0xFF42A5F5),
          flex: 1,
        ),
        _ActionButtonConfig(
          action: StockRequestAction.reject,
          label: 'Reject',
          icon: Icons.cancel_outlined,
          color: const Color(0xFFEF5350),
          flex: 1,
        ),
      ],
      'APPROVED' => [
        _ActionButtonConfig(
          action: StockRequestAction.queue,
          label: 'Send to Queue',
          icon: Icons.queue_outlined,
          color: const Color(0xFFAB47BC),
          flex: 2,
        ),
        _ActionButtonConfig(
          action: StockRequestAction.cancel,
          label: 'Cancel',
          icon: Icons.cancel_outlined,
          color: const Color(0xFFEF5350),
          flex: 1,
        ),
      ],
      'IN_QUEUE' => [
        _ActionButtonConfig(
          action: StockRequestAction.process,
          label: 'Start Processing',
          icon: Icons.settings_outlined,
          color: const Color(0xFF26A69A),
          flex: 2,
        ),
        _ActionButtonConfig(
          action: StockRequestAction.cancel,
          label: 'Cancel',
          icon: Icons.cancel_outlined,
          color: const Color(0xFFEF5350),
          flex: 1,
        ),
      ],
      'PROCESSING' => [
        _ActionButtonConfig(
          action: StockRequestAction.complete,
          label: 'Complete Transfer',
          icon: Icons.send_outlined,
          color: kPrimary,
          flex: 2,
        ),
        _ActionButtonConfig(
          action: StockRequestAction.cancel,
          label: 'Cancel',
          icon: Icons.cancel_outlined,
          color: const Color(0xFFEF5350),
          flex: 1,
        ),
      ],
      _ => [],
    };

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children: actions
          .expand(
            (cfg) => [
              Expanded(
                flex: cfg.flex,
                child: _buildActionButton(
                  request: request,
                  config: cfg,
                  screenWidth: screenWidth,
                  state: state,
                  disabled: anyInProgress,
                ),
              ),
              if (cfg != actions.last) const SizedBox(width: 8),
            ],
          )
          .toList(),
    );
  }

  Widget _buildActionButton({
    required StockRequest request,
    required _ActionButtonConfig config,
    required double screenWidth,
    required StockRequestState state,
    required bool disabled,
  }) {
    final inProgress = _isActionInProgress(state, request.id, config.action);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        iconAlignment: IconAlignment.end,
        onPressed: disabled
            ? null
            : () => _handleAction(request, config.action),
        style: ElevatedButton.styleFrom(
          backgroundColor: config.color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: config.color.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        icon: inProgress
            ? SizedBox(
                width: _getIconSize(screenWidth) - 4,
                height: _getIconSize(screenWidth) - 4,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(config.icon, size: _getIconSize(screenWidth) - 4),
        label: Text(
          inProgress ? '${config.label}...' : config.label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth) - 1,
            fontWeight: FontWeight.w600,
            color: kWhite,
          ),
        ),
      ),
    );
  }

  // ─── Items Section ────────────────────────────────────────────────────────

  Widget _buildItemsSection(StockRequest request, double screenWidth) {
    final items = request.items;

    if (items.isEmpty) {
      return Row(
        children: [
          Icon(
            Icons.inventory_outlined,
            size: _getIconSize(screenWidth) - 2,
            color: kprimaryTextColor2,
          ),
          const SizedBox(width: 8),
          Text(
            'No items requested',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getCaptionFontSize(screenWidth),
              color: kprimaryTextColor2,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return StatefulBuilder(
      builder: (context, setLocalState) {
        bool showAll = false;
        final displayItems = showAll ? items : items.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory_outlined,
                  size: _getIconSize(screenWidth) - 2,
                  color: kprimaryTextColor2,
                ),
                const SizedBox(width: 8),
                Text(
                  'Requested Items',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getInputFontSize(screenWidth),
                    fontWeight: FontWeight.w600,
                    color: kprimaryTextColor1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...displayItems.map((item) {
              final itemName = item.item?.itemName ?? 'Unknown Item';
              final unit = item.item?.unit ?? '';
              final qty = item.qtyRequested;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getCaptionFontSize(screenWidth),
                            color: kprimaryTextColor2,
                          ),
                          children: [
                            TextSpan(
                              text: itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: ' - ',
                              style: TextStyle(
                                color: kprimaryTextColor2.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            TextSpan(
                              text: '$qty ${unit.toLowerCase()}',
                              style: TextStyle(
                                color: kPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (items.length > 3)
              GestureDetector(
                onTap: () => setLocalState(() => showAll = !showAll),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, left: 22),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        showAll
                            ? 'Show less'
                            : 'Show ${items.length - 3} more item${items.length - 3 > 1 ? 's' : ''}',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: _getCaptionFontSize(screenWidth),
                          fontWeight: FontWeight.w600,
                          color: kPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        showAll
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: _getIconSize(screenWidth) - 4,
                        color: kPrimary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ─── Small Widgets ────────────────────────────────────────────────────────

  Widget _buildStatusBadge(String status, double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusText(status),
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getCaptionFontSize(screenWidth),
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required double screenWidth,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize(screenWidth) - 6, color: kPrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getCaptionFontSize(screenWidth),
              fontWeight: FontWeight.w500,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Status helpers ───────────────────────────────────────────────────────

  Color _getStatusColor(String status) {
    return switch (status.toUpperCase()) {
      'PENDING' => const Color(0xFFFFA726),
      'APPROVED' => const Color(0xFF42A5F5),
      'IN_QUEUE' => const Color(0xFFAB47BC),
      'PROCESSING' => const Color(0xFF26A69A),
      'COMPLETED' => const Color(0xFF66BB6A),
      'REJECTED' => const Color(0xFFEF5350),
      'CANCELLED' => const Color(0xFFBDBDBD),
      _ => kprimaryTextColor2,
    };
  }

  String _getStatusText(String status) {
    return switch (status.toUpperCase()) {
      'PENDING' => 'Pending',
      'APPROVED' => 'Approved',
      'IN_QUEUE' => 'In Queue',
      'PROCESSING' => 'Processing',
      'COMPLETED' => 'Completed',
      'REJECTED' => 'Rejected',
      'CANCELLED' => 'Cancelled',
      _ => status,
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  // ─── Responsive sizing ────────────────────────────────────────────────────

  double _getHorizontalPadding(double w) => w < 360
      ? 16
      : w < 600
      ? 20
      : 24;
  double _getCardPadding(double w) => w < 360
      ? 14
      : w < 600
      ? 16
      : 18;
  double _getSectionSpacing(double w) => w < 360
      ? 20
      : w < 600
      ? 24
      : 28;
  double _getFieldSpacing(double w) => w < 360
      ? 10
      : w < 600
      ? 12
      : 14;
  double _getAppBarTitleFontSize(double w) => w < 360
      ? 17
      : w < 600
      ? 18
      : 19;
  double _getTabFontSize(double w) => w < 360
      ? 13
      : w < 600
      ? 14
      : 15;
  double _getSectionTitleFontSize(double w) => w < 360
      ? 16
      : w < 600
      ? 17
      : 18;
  double _getInputFontSize(double w) => w < 360
      ? 14
      : w < 600
      ? 15
      : 16;
  double _getCaptionFontSize(double w) => w < 360
      ? 11
      : w < 600
      ? 12
      : 13;
  double _getIconSize(double w) => w < 360
      ? 20
      : w < 600
      ? 22
      : 24;
  double _getBorderRadius(double w) => w < 360
      ? 8
      : w < 600
      ? 10
      : 12;
  double _getEmptyIconSize(double w) => w < 360
      ? 80
      : w < 600
      ? 100
      : 120;
}

// ─── Private config classes ───────────────────────────────────────────────────

class _ActionDialogConfig {
  final String title;
  final String body;
  final String confirmLabel;
  final Color confirmColor;
  const _ActionDialogConfig({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.confirmColor,
  });
}

class _ActionButtonConfig {
  final StockRequestAction action;
  final String label;
  final IconData icon;
  final Color color;
  final int flex;
  const _ActionButtonConfig({
    required this.action,
    required this.label,
    required this.icon,
    required this.color,
    required this.flex,
  });
}
