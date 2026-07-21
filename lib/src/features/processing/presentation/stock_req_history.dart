import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
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
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';

class StockRequestsScreen extends StatefulWidget {
  final String branchId;
  final String? department;

  const StockRequestsScreen({
    super.key,
    required this.branchId,
    this.department,
  });

  @override
  State<StockRequestsScreen> createState() => _StockRequestsScreenState();
}

class _StockRequestsScreenState extends State<StockRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    context.read<StockRequestBloc>().add(
      LoadStockRequests(
        branchId: widget.branchId,
        department: widget.department,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        if (_tabController.index == 0) {
          _currentFilter = null;
        } else if (_tabController.index == 1) {
          _currentFilter = 'PENDING';
        } else {
          _currentFilter = 'COMPLETED';
        }
      });

      context.read<StockRequestBloc>().add(
        FilterRequestsByStatus(
          status: _currentFilter,
          department: widget.department,
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    context.read<StockRequestBloc>().add(
      RefreshStockRequests(
        branchId: widget.branchId,
        status: _currentFilter,
        department: widget.department,
      ),
    );
  }

  void _navigateToCreateRequest() {
    Navigator.pushNamed(
      context,
      '/create-stock-request',
      arguments: widget.branchId,
    ).then((result) {
      if (result == true) {
        _onRefresh();
      }
    });
  }

  void _navigateToDetails(StockRequest request) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => StockRequestDetailsScreen(request: request),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        return Scaffold(
          backgroundColor: context.modeBackground,
          body: BlocConsumer<StockRequestBloc, StockRequestState>(
            listener: (context, state) {
              if (state is StockRequestError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.error,
                      style: TextStyle(color: context.modeTextInverse),
                    ),
                    backgroundColor: context.modeError,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is StockRequestLoading) {
                return _buildLoadingState();
              }

              if (state is StockRequestEmpty) {
                return _buildEmptyState(screenWidth);
              }
              if (state is StockRequestEmpty) {
                return Column(
                  children: [
                    _buildTabBar(screenWidth),
                    Expanded(
                      child: _buildTabEmptyState(
                        screenWidth,
                        'No stock requests yet',
                      ),
                    ),
                  ],
                );
              }
              if (state is StockRequestListLoaded ||
                  state is StockRequestRefreshing) {
                final requests = state is StockRequestListLoaded
                    ? state.requests
                    : (state as StockRequestRefreshing).currentRequests;

                final pending = state is StockRequestListLoaded
                    ? state.pendingRequests
                    : requests
                          .where(
                            (r) =>
                                r.status == 'PENDING' || r.status == 'APPROVED',
                          )
                          .toList();

                final completed = state is StockRequestListLoaded
                    ? state.completedRequests
                    : requests
                          .where(
                            (r) =>
                                r.status == 'COMPLETED' ||
                                r.status == 'REJECTED',
                          )
                          .toList();

                return Column(
                  children: [
                    _buildTabBar(screenWidth),
                    Expanded(
                      child: // REPLACE the three _buildRequestsList calls inside TabBarView:
                      TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRequestsList(
                            requests,
                            screenWidth,
                            state is StockRequestRefreshing,
                            emptyMessage: 'No stock requests yet',
                          ),
                          _buildRequestsList(
                            pending,
                            screenWidth,
                            state is StockRequestRefreshing,
                            emptyMessage: 'No pending stock requests',
                          ),
                          _buildRequestsList(
                            completed,
                            screenWidth,
                            state is StockRequestRefreshing,
                            emptyMessage: 'No completed stock requests',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return _buildEmptyState(screenWidth);
            },
          ),
        );
      },
    );
  }

  Widget _buildTabBar(double screenWidth) {
    return Container(
      color: context.modeSurface,
      child: TabBar(
        controller: _tabController,
        labelColor: context.modePrimary,
        unselectedLabelColor: context.modeTextSecondary,
        indicatorColor: context.modePrimary,
        indicatorWeight: 3,
        labelStyle: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getTabFontSize(screenWidth),
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getTabFontSize(screenWidth),
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Pending'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return shimmerCatalogCard(constraints.maxWidth);
      },
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
                color: context.modePrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                Icons.inbox_outlined,
                size: _getEmptyIconSize(screenWidth) * 0.5,
                color: context.modePrimary,
              ),
            ),
            SizedBox(height: _getSectionSpacing(screenWidth)),
            Text(
              'No stock requests',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getSectionTitleFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first stock request to get started',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                color: context.modeTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(
    List<StockRequest> requests,
    double screenWidth,
    bool isRefreshing, {
    String emptyMessage = 'No stock requests found',
  }) {
    if (requests.isEmpty) {
      return _buildTabEmptyState(screenWidth, emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: context.modePrimary,
      child: ListView.builder(
        padding: EdgeInsets.all(_getHorizontalPadding(screenWidth)),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(requests[index], screenWidth);
        },
      ),
    );
  }

  Widget _buildTabEmptyState(double screenWidth, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_getHorizontalPadding(screenWidth)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.modePrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                Icons.inbox_outlined,
                size: 36,
                color: context.modePrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(StockRequest request, double screenWidth) {
    return Container(
      margin: EdgeInsets.only(bottom: _getFieldSpacing(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.04),
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
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

              // Items Section with Show More/Less
              _buildItemsSection(request, screenWidth),

              if (request.notes.isNotEmpty) ...[
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(
                      Icons.note_outlined,
                      size: _getIconSize(screenWidth) - 2,
                      color: context.modeTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.notes,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: _getCaptionFontSize(screenWidth),
                          color: context.modeTextSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: _getFieldSpacing(screenWidth)),
              Divider(height: 1, color: context.modeDivider),
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
                      color: context.modeTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New widget to handle items section with show more/less
  Widget _buildItemsSection(StockRequest request, double screenWidth) {
    final items = request.items;

    if (items.isEmpty) {
      return Row(
        children: [
          AppIcon(
            Icons.inventory_outlined,
            size: _getIconSize(screenWidth) - 2,
            color: context.modeTextSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'No items requested',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getCaptionFontSize(screenWidth),
              color: context.modeTextSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    var showAll = false;
    return StatefulBuilder(
      builder: (context, setState) {
        final displayItems = showAll ? items : items.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(
                  Icons.inventory_outlined,
                  size: _getIconSize(screenWidth) - 2,
                  color: context.modeTextSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Requested Items',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getInputFontSize(screenWidth),
                    fontWeight: FontWeight.w600,
                    color: context.modeTextPrimary,
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
                        color: context.modePrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getCaptionFontSize(screenWidth),
                            color: context.modeTextSecondary,
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
                                color: context.modeTextSecondary.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            TextSpan(
                              text: '$qty ${unit.toLowerCase()}',
                              style: TextStyle(
                                color: context.modePrimary,
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
                onTap: () {
                  setState(() {
                    showAll = !showAll;
                  });
                },
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
                          color: context.modePrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AppIcon(
                        showAll
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: _getIconSize(screenWidth) - 4,
                        color: context.modePrimary,
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
        color: context.modePrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon,
            size: _getIconSize(screenWidth) - 6,
            color: context.modePrimary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getCaptionFontSize(screenWidth),
              fontWeight: FontWeight.w500,
              color: context.modePrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildFAB(double screenWidth) {
    return FloatingActionButton.extended(
      onPressed: _navigateToCreateRequest,
      backgroundColor: context.modePrimary,
      icon: AppIcon(
        Icons.add,
        size: _getIconSize(screenWidth),
        color: context.modeTextInverse,
      ),
      label: Text(
        'New Request',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getInputFontSize(screenWidth),
          fontWeight: FontWeight.w600,
          color: context.modeTextInverse,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return context.modeWarning;
      case 'APPROVED':
        return context.modeInfo;
      case 'COMPLETED':
        return context.modeSuccess;
      case 'REJECTED':
        return context.modeError;
      default:
        return context.modeTextSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'COMPLETED':
        return 'Completed';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
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

  // Responsive sizing functions
  double _getHorizontalPadding(double width) => width < 360
      ? 16
      : width < 600
      ? 20
      : 24;
  double _getCardPadding(double width) => width < 360
      ? 14
      : width < 600
      ? 16
      : 18;
  double _getSectionSpacing(double width) => width < 360
      ? 20
      : width < 600
      ? 24
      : 28;
  double _getFieldSpacing(double width) => width < 360
      ? 10
      : width < 600
      ? 12
      : 14;
  // ignore: unused_element
  double _getAppBarTitleFontSize(double width) => width < 360
      ? 17
      : width < 600
      ? 18
      : 19;
  double _getTabFontSize(double width) => width < 360
      ? 13
      : width < 600
      ? 14
      : 15;
  double _getSectionTitleFontSize(double width) => width < 360
      ? 16
      : width < 600
      ? 17
      : 18;
  double _getInputFontSize(double width) => width < 360
      ? 14
      : width < 600
      ? 15
      : 16;
  double _getCaptionFontSize(double width) => width < 360
      ? 11
      : width < 600
      ? 12
      : 13;
  double _getIconSize(double width) => width < 360
      ? 20
      : width < 600
      ? 22
      : 24;
  double _getBorderRadius(double width) => width < 360
      ? 8
      : width < 600
      ? 10
      : 12;
  double _getEmptyIconSize(double width) => width < 360
      ? 80
      : width < 600
      ? 100
      : 120;
}
