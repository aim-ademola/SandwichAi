import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/utils/debouncer.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_order_model.dart'
    as procurement_model;
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_order_repo.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_order_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_order_blocs/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_order_blocs/state.dart';

class ProcurementRequestsScreen extends StatefulWidget {
  const ProcurementRequestsScreen({super.key});

  @override
  State<ProcurementRequestsScreen> createState() =>
      _ProcurementRequestsScreenState();
}

class _ProcurementRequestsScreenState extends State<ProcurementRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final Debouncer _searchDebouncer;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _actioningRequestIds = {};
  String _searchInput = '';
  String _searchQuery = '';

  List<Request> _filteredRequests(List<Request> requests) {
    final selectedFilter = _selectedFilter.toLowerCase();
    final query = _searchQuery.trim().toLowerCase();
    return requests.where((req) {
      final from = req.from.toLowerCase();
      final priority = req.priority.toLowerCase();
      final matchesFilter = selectedFilter == 'all'
          ? true
          : selectedFilter == 'urgent'
          ? priority.contains('urgent') ||
                priority.contains('high') ||
                priority.contains('critical')
          : from.contains(selectedFilter);
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;

      return from.contains(query) ||
          req.title.toLowerCase().contains(query) ||
          (req.description?.toLowerCase().contains(query) ?? false) ||
          (req.supplier?.toLowerCase().contains(query) ?? false) ||
          priority.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 350));
    _tabController = TabController(length: 5, vsync: this);
    AppLogger.log('=== PROCUREMENT REQUESTS SCREEN DATA SOURCE ===');
    AppLogger.log(
      'ProcurementRequestsScreen is wired to GET /procurement/requests?branchId={branchId}.',
    );
    AppLogger.log('==============================================');
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    final branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    if (!mounted) return;
    context.read<ProcurementBloc>().add(
      LoadProcurementOrders(branchId: branchId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
        appBar: _buildAppBar(context),
        body: _buildBody(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.modeSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Procurement Request',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: context.modeTextPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: AppIcon(
            Icons.notifications_outlined,
            color: context.modeTextPrimary,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _getHorizontalPadding(constraints.maxWidth);
        final maxContentWidth = _getMaxContentWidth(constraints.maxWidth);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildSearchBar(constraints.maxWidth),
                ),
                const SizedBox(height: 16),
                _buildFilterTabs(constraints.maxWidth),
                const SizedBox(height: 16),
                Expanded(
                  child: BlocBuilder<ProcurementBloc, ProcurementState>(
                    builder: (context, state) {
                      if (state is ProcurementLoading ||
                          state is ProcurementInitial) {
                        return _buildLoadingState();
                      }

                      if (state is ProcurementError) {
                        return _buildErrorState(
                          constraints.maxWidth,
                          state.error,
                        );
                      }

                      final apiRequests = _requestsFromState(state);
                      final visibleRequests = _filteredRequests(apiRequests);

                      return RefreshIndicator(
                        color: context.modePrimary,
                        onRefresh: _loadRequests,
                        child: visibleRequests.isEmpty
                            ? _buildEmptyState(constraints.maxWidth)
                            : _buildRequestsList(
                                visibleRequests,
                                horizontalPadding,
                                maxContentWidth,
                                constraints.maxWidth,
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(double screenWidth) {
    final fontSize = _getSearchFontSize(screenWidth);

    return TextField(
      cursorColor: context.modePrimary,
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchInput = value;
        });
        _searchDebouncer(() {
          if (!mounted) return;
          setState(() {
            _searchQuery = value.trim();
          });
        });
      },
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: context.modeTextPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: context.modeSurface,
        hintText: 'Search by item or department...',
        hintStyle: WorkSansAppTextStyles.medium.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          color: context.modeTextMuted,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _getSearchPaddingHorizontal(screenWidth),
          vertical: _getSearchPaddingVertical(screenWidth),
        ),
        prefixIcon: AppIconSlot(
          Icons.search,
          color: context.modeTextMuted,
          size: _getSearchIconSize(screenWidth),
        ),
        suffixIcon: _searchInput.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchDebouncer.cancel();
                  setState(() {
                    _searchController.clear();
                    _searchInput = '';
                    _searchQuery = '';
                  });
                },
                icon: AppIcon(
                  Icons.clear,
                  color: context.modeTextMuted,
                  size: _getSearchIconSize(screenWidth),
                ),
                tooltip: 'Clear search',
              ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.modeBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.modePrimary),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.modeBorder),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(double screenWidth) {
    final filters = ['All', 'Urgent', 'Kitchen', 'Procurement', 'Inventory'];
    final fontSize = _getFilterFontSize(screenWidth);

    return SizedBox(
      height: _getFilterHeight(screenWidth),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: _getHorizontalPadding(screenWidth),
        ),
        itemCount: filters.length,
        separatorBuilder: (context, index) =>
            SizedBox(width: _getFilterSpacing(screenWidth)),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _getFilterPaddingHorizontal(screenWidth),
                vertical: _getFilterPaddingVertical(screenWidth),
              ),
              decoration: BoxDecoration(
                color: isSelected ? context.modePrimary : context.modeSurface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? context.modePrimary : context.modeBorder,
                ),
              ),
              child: Text(
                filter,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? context.modeTextInverse
                      : context.modeTextPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(
    List<Request> requests,
    double horizontalPadding,
    double maxContentWidth,
    double screenWidth,
  ) {
    return ListView.separated(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: 24,
      ),
      itemCount: requests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildRequestCard(requests[index], screenWidth);
      },
    );
  }

  List<Request> _requestsFromState(ProcurementState state) {
    if (state is ProcurementLoaded) {
      return state.response.data.map(_requestFromApi).toList();
    }
    if (state is ProcurementRefreshing) {
      return state.currentData.data.map(_requestFromApi).toList();
    }
    return const [];
  }

  Request _requestFromApi(procurement_model.ProcurementRequest request) {
    final items = request.items.map(_lineItemFromApi).toList();
    final description = items.isEmpty
        ? null
        : items
              .take(3)
              .map((item) => '${item.quantity} ${item.unit} ${item.name}')
              .join(', ');
    final extraItems = items.length > 3 ? '...' : '';
    final branchLabel = [
      request.branch.name,
      if (request.branch.branchCode.trim().isNotEmpty)
        request.branch.branchCode,
    ].where((part) => part.trim().isNotEmpty).join(' - ');

    return Request(
      id: request.id,
      status: request.status,
      from: request.departmentLabel,
      timeAgo: _formatTimeAgo(request.createdAt),
      title: request.requestId.trim().isEmpty
          ? 'Procurement Request'
          : 'Request ${request.requestId}',
      description: description == null ? null : '$description$extraItems',
      amount: request.totalAmountDouble > 0 ? request.totalAmountDouble : null,
      priority: _displayPriority(request.priority),
      requestedBy: request.requestedBy.trim().isEmpty
          ? request.departmentLabel
          : request.requestedBy,
      reference: request.requestId,
      neededBy: request.formattedExpectedDelivery,
      destination: branchLabel.isEmpty ? request.branchId : branchLabel,
      items: items,
      reason: request.notes ?? 'Procurement request awaiting review.',
      notes: request.status.trim().isEmpty ? '' : 'Status: ${request.status}',
    );
  }

  RequestLineItem _lineItemFromApi(procurement_model.ProcurementItem item) {
    return RequestLineItem(
      name: item.item.itemName.trim().isEmpty
          ? 'Stock item'
          : item.item.itemName,
      quantity: _formatQuantity(item.qtyNeededValue),
      unit: item.item.unit,
      unitCost: item.unitCostDouble > 0 ? item.unitCostDouble : null,
    );
  }

  String _displayPriority(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) return 'Medium';
    if (normalized == 'URGENT' || normalized == 'CRITICAL') return 'High';
    return '${normalized[0]}${normalized.substring(1).toLowerCase()}';
  }

  String _formatQuantity(double value) {
    return NumberFormat(value % 1 == 0 ? '#,##0' : '#,##0.##').format(value);
  }

  String _formatTimeAgo(String isoValue) {
    final createdAt = DateTime.tryParse(isoValue);
    if (createdAt == null) return '';

    final diff = DateTime.now().difference(createdAt.toLocal());
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(createdAt.toLocal());
  }

  Widget _buildRequestCard(Request request, double screenWidth) {
    final fromFontSize = _getFromFontSize(screenWidth);
    final titleFontSize = _getTitleFontSize(screenWidth);
    final descriptionFontSize = _getDescriptionFontSize(screenWidth);
    final priorityFontSize = _getPriorityFontSize(screenWidth);
    final buttonFontSize = _getButtonFontSize(screenWidth);

    return InkWell(
      onTap: () => _showRequestDetails(request),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(_getCardPadding(screenWidth)),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.modeBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'From: ${request.from} - ${request.timeAgo}',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: fromFontSize,
                          fontWeight: FontWeight.w400,
                          color: context.modeTextSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPriorityBadge(
                      request.priority,
                      priorityFontSize,
                      screenWidth,
                    ),
                  ],
                ),
                SizedBox(height: _getTitleSpacing(screenWidth)),

                // Title
                Text(
                  request.title,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextPrimary,
                  ),
                ),
                SizedBox(height: _getDescriptionSpacing(screenWidth)),

                // Description or details
                if (request.description != null)
                  Text(
                    request.description!,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: descriptionFontSize,
                      fontWeight: FontWeight.w400,
                      color: context.modeTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (request.supplier != null && request.amount != null) ...[
                  Text(
                    'Supplier: ${request.supplier}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: descriptionFontSize,
                      fontWeight: FontWeight.w400,
                      color: context.modeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Amount: ${_formatMoney(request.amount!)}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: descriptionFontSize,
                      fontWeight: FontWeight.w400,
                      color: context.modeTextSecondary,
                    ),
                  ),
                ],
                SizedBox(height: _getDescriptionSpacing(screenWidth)),
                Text(
                  'Tap to review full details',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: descriptionFontSize - 1,
                    fontWeight: FontWeight.w700,
                    color: context.modePrimary,
                  ),
                ),
                SizedBox(height: _getButtonSpacing(screenWidth)),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'Reject',
                        context.modeSurfaceMuted,
                        context.modeTextPrimary,
                        buttonFontSize,
                        screenWidth,
                        () => _showRequestDetails(
                          request,
                          initialAction: 'Reject',
                        ),
                      ),
                    ),
                    SizedBox(width: _getButtonGap(screenWidth)),
                    Expanded(
                      child: _buildActionButton(
                        'Approve',
                        context.modePrimary,
                        context.modeTextInverse,
                        buttonFontSize,
                        screenWidth,
                        () => _showRequestDetails(
                          request,
                          initialAction: 'Approve',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRequestDetails(
    Request request, {
    String? initialAction,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.modeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.84,
            minChildSize: 0.5,
            maxChildSize: 0.94,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.modeBorder,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  request.title,
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: context.modeTextPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _buildPriorityBadge(request.priority, 12, 390),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDetailGrid(request),
                          const SizedBox(height: 18),
                          _buildDetailSection(
                            'Items requested',
                            request.items
                                .map((item) => _buildLineItemRow(item))
                                .toList(),
                          ),
                          const SizedBox(height: 18),
                          _buildDetailSection('Reason', [
                            _buildDetailText(
                              _fallbackText(
                                request.reason,
                                'No reason provided.',
                              ),
                            ),
                          ]),
                          if ((request.notes ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _buildDetailSection('Notes', [
                              _buildDetailText(request.notes!),
                            ]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            _actioningRequestIds.contains(request.id)
                                ? 'Working...'
                                : initialAction == 'Reject'
                                ? 'Confirm Reject'
                                : 'Reject',
                            context.modeSurfaceMuted,
                            context.modeTextPrimary,
                            14,
                            390,
                            () => _completeReview(request, 'reject'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            _actioningRequestIds.contains(request.id)
                                ? 'Working...'
                                : initialAction == 'Approve'
                                ? 'Confirm Approve'
                                : 'Approve',
                            context.modePrimary,
                            context.modeTextInverse,
                            14,
                            390,
                            () => _completeReview(request, 'approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailGrid(Request request) {
    final rows = [
      ('From', request.from),
      ('Requested by', _fallbackText(request.requestedBy, 'Unknown')),
      ('Reference', _fallbackText(request.reference, 'N/A')),
      ('Needed by', _fallbackText(request.neededBy, 'Not specified')),
      ('Destination', _fallbackText(request.destination, 'Not specified')),
      if (request.supplier != null) ('Supplier', request.supplier!),
      if (request.amount != null) ('Amount', _formatMoney(request.amount!)),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: rows
          .map(
            (row) =>
                SizedBox(width: 150, child: _buildDetailTile(row.$1, row.$2)),
          )
          .toList(),
    );
  }

  Widget _buildDetailTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.modeSurfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.modeTextMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildLineItemRow(RequestLineItem item) {
    final quantity = double.tryParse(item.quantity);
    final total = item.unitCost == null || quantity == null
        ? null
        : _formatMoney(quantity * item.unitCost!);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: context.modeBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.modeTextPrimary,
                  ),
                ),
                if (item.unitCost != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Unit cost: ${_formatMoney(item.unitCost!)}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 12,
                      color: context.modeTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${item.quantity} ${item.unit}${total == null ? '' : '\n$total'}',
            textAlign: TextAlign.right,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: context.modeTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailText(String text) {
    return Text(
      text,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: 14,
        height: 1.45,
        color: context.modeTextSecondary,
      ),
    );
  }

  Future<void> _completeReview(Request request, String action) async {
    if (_actioningRequestIds.contains(request.id)) return;

    final actor = await _currentApprovalActor();
    if (actor.isEmpty) {
      _showSnackBar('Could not identify current employee.', isError: true);
      return;
    }

    String? rejectionNote;
    if (action == 'reject') {
      rejectionNote = await _promptRejectionReason();
      if (rejectionNote == null || rejectionNote.trim().isEmpty) return;
    }

    if (!mounted) return;
    setState(() => _actioningRequestIds.add(request.id));

    final repository = context.read<ProcurementRepositoryInterface>();
    final response = action == 'approve'
        ? await repository.approveProcurementRequest(
            requestId: request.id,
            approvedBy: actor,
            notes: 'Approved from mobile app',
          )
        : await repository.rejectProcurementRequest(
            requestId: request.id,
            rejectedBy: actor,
            rejectionNote: rejectionNote!,
          );

    if (!mounted) return;
    setState(() => _actioningRequestIds.remove(request.id));

    response.when(
      success: (updated) {
        Navigator.pop(context);
        _showSnackBar(
          action == 'approve'
              ? '${request.title} approved.'
              : '${request.title} rejected.',
        );
        _loadRequests();
      },
      error: (error) {
        _showSnackBar(error.toString(), isError: true);
      },
    );
  }

  Future<String> _currentApprovalActor() async {
    final employeeId = await AuthCacheHelper.instance.getEmpID() ?? '';
    if (employeeId.trim().isNotEmpty) return employeeId.trim();

    final user = await AuthCacheHelper.instance.getUserData();
    final fullName = user?.fullName?.trim() ?? '';
    if (fullName.isNotEmpty) return fullName;
    return user?.id.trim() ?? '';
  }

  Future<String?> _promptRejectionReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.modeSurface,
          title: Text(
            'Reject Request',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            cursorColor: context.modePrimary,
            style: WorkSansAppTextStyles.medium.copyWith(
              color: context.modeTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Reason for rejection',
              hintStyle: WorkSansAppTextStyles.medium.copyWith(
                color: context.modeTextMuted,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.modePrimary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                foregroundColor: context.modeTextInverse,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? context.modeError : null,
      ),
    );
  }

  String _formatMoney(double value) {
    return 'NGN ${NumberFormat('#,##0.00').format(value)}';
  }

  String _fallbackText(String? value, String fallback) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  Widget _buildActionButton(
    String text,
    Color bgColor,
    Color textColor,
    double fontSize,
    double screenWidth,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: _getButtonPaddingHorizontal(screenWidth),
          vertical: _getButtonPaddingVertical(screenWidth),
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(
    String priority,
    double fontSize,
    double screenWidth,
  ) {
    Color bgColor;
    Color textColor;

    switch (priority.toLowerCase()) {
      case 'high':
        bgColor = context.modeError.withValues(alpha: 0.12);
        textColor = context.modeError;
        break;
      case 'medium':
        bgColor = context.modePrimary.withValues(alpha: 0.12);
        textColor = context.modePrimary;
        break;
      case 'low':
        bgColor = context.modeSuccess.withValues(alpha: 0.12);
        textColor = context.modeSuccess;
        break;
      default:
        bgColor = context.modeSurfaceMuted;
        textColor = context.modeTextSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getPriorityPaddingHorizontal(screenWidth),
        vertical: _getPriorityPaddingVertical(screenWidth),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    final iconSize = _getEmptyIconSize(screenWidth);
    final titleFontSize = _getEmptyTitleFontSize(screenWidth);
    final descriptionFontSize = _getEmptyDescriptionFontSize(screenWidth);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _getHorizontalPadding(screenWidth),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: context.modeSurfaceMuted,
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                Icons.check_circle_outline,
                size: iconSize * 0.6,
                color: context.modeTextMuted,
              ),
            ),
            SizedBox(height: _getEmptySpacing(screenWidth)),
            Text(
              'All caught up!',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            SizedBox(height: _getEmptyDescriptionSpacing(screenWidth)),
            Text(
              'There are no new requests for you to\nreview at this time.',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: descriptionFontSize,
                fontWeight: FontWeight.w400,
                color: context.modeTextSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator(color: context.modePrimary));
  }

  Widget _buildErrorState(double screenWidth, String message) {
    final titleFontSize = _getEmptyTitleFontSize(screenWidth);
    final descriptionFontSize = _getEmptyDescriptionFontSize(screenWidth);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _getHorizontalPadding(screenWidth),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(Icons.error_outline, size: 56, color: context.modeError),
            const SizedBox(height: 14),
            Text(
              'Could not load requests',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: descriptionFontSize,
                color: context.modeTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                foregroundColor: context.modeTextInverse,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Responsive sizing functions
  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 32;
    return 48;
  }

  double _getMaxContentWidth(double width) {
    if (width < 600) return double.infinity;
    if (width < 900) return 600;
    return 800;
  }

  double _getSearchFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getSearchPaddingHorizontal(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getSearchPaddingVertical(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getSearchIconSize(double width) {
    if (width < 360) return 20;
    if (width < 600) return 22;
    return 24;
  }

  double _getFilterHeight(double width) {
    if (width < 360) return 36;
    if (width < 600) return 40;
    return 44;
  }

  double _getFilterFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getFilterSpacing(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getFilterPaddingHorizontal(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getFilterPaddingVertical(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getCardPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getFromFontSize(double width) {
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  double _getTitleFontSize(double width) {
    if (width < 360) return 15;
    if (width < 600) return 16;
    return 17;
  }

  double _getDescriptionFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getPriorityFontSize(double width) {
    if (width < 360) return 11;
    if (width < 600) return 12;
    return 13;
  }

  double _getButtonFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getTitleSpacing(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getDescriptionSpacing(double width) {
    if (width < 360) return 6;
    if (width < 600) return 8;
    return 10;
  }

  double _getButtonSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getButtonGap(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getButtonPaddingHorizontal(double width) {
    if (width < 360) return 20;
    if (width < 600) return 24;
    return 28;
  }

  double _getButtonPaddingVertical(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getPriorityPaddingHorizontal(double width) {
    if (width < 360) return 10;
    if (width < 600) return 12;
    return 14;
  }

  double _getPriorityPaddingVertical(double width) {
    if (width < 360) return 4;
    if (width < 600) return 5;
    return 6;
  }

  double _getEmptyIconSize(double width) {
    if (width < 360) return 80;
    if (width < 600) return 100;
    return 120;
  }

  double _getEmptyTitleFontSize(double width) {
    if (width < 360) return 18;
    if (width < 600) return 20;
    return 22;
  }

  double _getEmptyDescriptionFontSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }

  double _getEmptySpacing(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getEmptyDescriptionSpacing(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }
}

// Request Model
class Request {
  final String id;
  final String status;
  final String from;
  final String timeAgo;
  final String title;
  final String? description;
  final String? supplier;
  final double? amount;
  final String priority;
  final String? requestedBy;
  final String? reference;
  final String? neededBy;
  final String? destination;
  final List<RequestLineItem> items;
  final String? reason;
  final String? notes;

  Request({
    required this.id,
    required this.status,
    required this.from,
    required this.timeAgo,
    required this.title,
    this.description,
    this.supplier,
    this.amount,
    required this.priority,
    this.requestedBy,
    this.reference,
    this.neededBy,
    this.destination,
    this.items = const [],
    this.reason,
    this.notes = '',
  });
}

class RequestLineItem {
  final String name;
  final String quantity;
  final String unit;
  final double? unitCost;

  const RequestLineItem({
    required this.name,
    required this.quantity,
    required this.unit,
    this.unitCost,
  });
}
