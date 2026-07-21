import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

class ProcurementRequestsScreen extends StatefulWidget {
  const ProcurementRequestsScreen({super.key});

  @override
  State<ProcurementRequestsScreen> createState() =>
      _ProcurementRequestsScreenState();
}

class _ProcurementRequestsScreenState extends State<ProcurementRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Request> _allRequests = [
    Request(
      from: 'Kitchen',
      timeAgo: '2h ago',
      title: 'Stock Replenishment',
      description: '10kg Tomatoes, 5kg Onions, 2L Olive Oil...',
      priority: 'High',
    ),
    Request(
      from: 'Procurement',
      timeAgo: '8h ago',
      title: 'Invoice Approval #INV-12045',
      supplier: 'Global Foods Inc.',
      amount: 1250.30,
      priority: 'Medium',
    ),
    Request(
      from: 'Bar',
      timeAgo: '1d ago',
      title: 'New Cocktail Glassware Order',
      description: '24x Highball, 24x Coupe glasses...',
      priority: 'Low',
    ),
  ];

  List<Request> get _filteredRequests {
    if (_selectedFilter == 'All') return _allRequests;
    return _allRequests
        .where((req) => req.from.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        icon: AppIcon(Icons.menu, color: context.modeTextPrimary),
        onPressed: () {},
      ),
      title: Text(
        'Requests',
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
                  child: _filteredRequests.isEmpty
                      ? _buildEmptyState(constraints.maxWidth)
                      : _buildRequestsList(
                          horizontalPadding,
                          maxContentWidth,
                          constraints.maxWidth,
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

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getSearchPaddingHorizontal(screenWidth),
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder),
      ),
      child: Row(
        children: [
          AppIcon(
            Icons.search,
            color: context.modeTextMuted,
            size: _getSearchIconSize(screenWidth),
          ),
          SizedBox(width: _getSearchIconSpacing(screenWidth)),
          Expanded(
            child: TextField(
              cursorColor: context.modePrimary,
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
                color: context.modeTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search by item or department...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: context.modeTextMuted,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              child: AppIcon(
                Icons.clear,
                color: context.modeTextMuted,
                size: _getSearchIconSize(screenWidth),
              ),
            ),
        ],
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
      itemCount: _filteredRequests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildRequestCard(_filteredRequests[index], screenWidth);
      },
    );
  }

  Widget _buildRequestCard(Request request, double screenWidth) {
    final fromFontSize = _getFromFontSize(screenWidth);
    final titleFontSize = _getTitleFontSize(screenWidth);
    final descriptionFontSize = _getDescriptionFontSize(screenWidth);
    final priorityFontSize = _getPriorityFontSize(screenWidth);
    final buttonFontSize = _getButtonFontSize(screenWidth);

    return Container(
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
              Text(
                'From: ${request.from} â€¢ ${request.timeAgo}',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: fromFontSize,
                  fontWeight: FontWeight.w400,
                  color: context.modeTextSecondary,
                ),
              ),
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
              'Amount: \$${request.amount!.toStringAsFixed(2)}',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: descriptionFontSize,
                fontWeight: FontWeight.w400,
                color: context.modeTextSecondary,
              ),
            ),
          ],
          SizedBox(height: _getButtonSpacing(screenWidth)),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                'Reject',
                context.modeSurfaceMuted,
                context.modeTextPrimary,
                buttonFontSize,
                screenWidth,
                () {},
              ),
              SizedBox(width: _getButtonGap(screenWidth)),
              _buildActionButton(
                'Approve',
                context.modePrimary,
                context.modeTextInverse,
                buttonFontSize,
                screenWidth,
                () {},
              ),
            ],
          ),
        ],
      ),
    );
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

  double _getSearchIconSize(double width) {
    if (width < 360) return 20;
    if (width < 600) return 22;
    return 24;
  }

  double _getSearchIconSpacing(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
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
  final String from;
  final String timeAgo;
  final String title;
  final String? description;
  final String? supplier;
  final double? amount;
  final String priority;

  Request({
    required this.from,
    required this.timeAgo,
    required this.title,
    this.description,
    this.supplier,
    this.amount,
    required this.priority,
  });
}
