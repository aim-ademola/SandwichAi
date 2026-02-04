import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/stock_reuest_model.dart';
import 'package:sandwich_ai/src/features/processing/presentation/stock_req_details.dart';

class CompleteStockRequestDetailsScreen extends StatefulWidget {
  final String branchId;

  const CompleteStockRequestDetailsScreen({super.key, required this.branchId});

  @override
  State<CompleteStockRequestDetailsScreen> createState() =>
      _CompleteStockRequestDetailsScreenState();
}

class _CompleteStockRequestDetailsScreenState
    extends State<CompleteStockRequestDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentFilter;
  String? _completingRequestId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    context.read<StockRequestBloc>().add(
      LoadStockRequests(branchId: widget.branchId),
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
        FilterRequestsByStatus(status: _currentFilter),
      );
    }
  }

  Future<void> _onRefresh() async {
    context.read<StockRequestBloc>().add(
      RefreshStockRequests(branchId: widget.branchId, status: _currentFilter),
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

  void _handleTransferItems(StockRequest request) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Complete Transfer',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to complete the transfer for ${request.requestId}?\n\nThis will mark all items as transferred and complete the request.',
          style: WorkSansAppTextStyles.medium.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: kprimaryTextColor2)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _completingRequestId = request.id;
              });
              context.read<StockRequestBloc>().add(
                CompleteStockRequest(requestId: request.id),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text('Complete Transfer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F6F6),
          appBar: _buildAppBar(screenWidth),
          body: BlocConsumer<StockRequestBloc, StockRequestState>(
            listener: (context, state) {
              if (state is StockRequestError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: const Color(0xFFE53935),
                  ),
                );
                setState(() {
                  _completingRequestId = null;
                });
              } else if (state is StockRequestCompleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: kGreen,
                  ),
                );
                setState(() {
                  _completingRequestId = null;
                });
              }
            },
            builder: (context, state) {
              if (state is StockRequestLoading) {
                return _buildLoadingState();
              }

              if (state is StockRequestEmpty) {
                return _buildEmptyState(screenWidth);
              }

              if (state is StockRequestListLoaded ||
                  state is StockRequestRefreshing ||
                  state is StockRequestCompleted) {
                List<StockRequest> actualRequests;

                if (state is StockRequestListLoaded) {
                  actualRequests = state.requests;
                } else if (state is StockRequestRefreshing) {
                  actualRequests = (state).currentRequests;
                } else {
                  actualRequests =
                      (state as StockRequestCompleted).currentRequests;
                }

                final List<StockRequest> pending =
                    state is StockRequestListLoaded
                    ? state.pendingRequests
                    : actualRequests
                          .where(
                            (r) =>
                                r.status == 'PENDING' || r.status == 'APPROVED',
                          )
                          .toList();

                final List<StockRequest> completed =
                    state is StockRequestListLoaded
                    ? state.completedRequests
                    : actualRequests
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
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRequestsList(
                            actualRequests,
                            screenWidth,
                            state is StockRequestRefreshing,
                            showTransferButton: true,
                          ),
                          _buildRequestsList(
                            pending,
                            screenWidth,
                            state is StockRequestRefreshing,
                            showTransferButton: true,
                          ),
                          _buildRequestsList(
                            completed,
                            screenWidth,
                            state is StockRequestRefreshing,
                            showTransferButton: false,
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

  Widget _buildTabBar(double screenWidth) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
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
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Pending'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

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
                color: kPrimary.withOpacity(0.1),
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
            SizedBox(height: 8),
            Text(
              'Create your first stock request to get started',
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

  Widget _buildRequestsList(
    List<StockRequest> requests,
    double screenWidth,
    bool isRefreshing, {
    bool showTransferButton = false,
  }) {
    if (requests.isEmpty) {
      return _buildEmptyState(screenWidth);
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: kPrimary,
      child: ListView.builder(
        padding: EdgeInsets.all(_getHorizontalPadding(screenWidth)),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(
            requests[index],
            screenWidth,
            showTransferButton: showTransferButton,
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
    StockRequest request,
    double screenWidth, {
    bool showTransferButton = false,
  }) {
    final isCompleting = _completingRequestId == request.id;

    return Container(
      margin: EdgeInsets.only(bottom: _getFieldSpacing(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                      color: _getStatusColor(request.status).withOpacity(0.1),
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
              if (showTransferButton &&
                  (request.status == 'PENDING' ||
                      request.status == 'APPROVED')) ...[
                SizedBox(height: _getFieldSpacing(screenWidth)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    iconAlignment: IconAlignment.end,
                    onPressed: isCompleting
                        ? null
                        : () => _handleTransferItems(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: kPrimary.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    icon: isCompleting
                        ? SizedBox(
                            width: _getIconSize(screenWidth) - 2,
                            height: _getIconSize(screenWidth) - 2,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.send_outlined,
                            size: _getIconSize(screenWidth) - 2,
                          ),
                    label: Text(
                      isCompleting ? 'Completing...' : 'Complete Transfer',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getInputFontSize(screenWidth),
                        fontWeight: FontWeight.w600,
                        color: kWhite,
                      ),
                    ),
                  ),
                ),
              ],
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
      builder: (context, setState) {
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
                                color: kprimaryTextColor2.withOpacity(0.6),
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

  Widget _buildStatusBadge(String status, double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
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
        color: kPrimary.withOpacity(0.08),
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFFA726);
      case 'APPROVED':
        return const Color(0xFF42A5F5);
      case 'COMPLETED':
        return const Color(0xFF66BB6A);
      case 'REJECTED':
        return const Color(0xFFEF5350);
      default:
        return kprimaryTextColor2;
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
