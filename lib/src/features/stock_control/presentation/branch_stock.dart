import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/globals/notifications/stock_notification_helper.dart';

import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_model.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/branch_stock_details.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/precuremnt_req.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';

class InventoryBody extends StatefulWidget {
  final bool isTableView;

  const InventoryBody({super.key, required this.isTableView});

  @override
  State<InventoryBody> createState() => _InventoryBodyState();
}

class _InventoryBodyState extends State<InventoryBody> {
  final TextEditingController _searchController = TextEditingController();
  final _stockNotificationHelper = StockNotificationHelper();

  @override
  void initState() {
    super.initState();
    // Load branch stock on init
    context.read<BranchStockBloc>().add(LoadBranchStock());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Check stock levels and trigger notifications
  Future<void> _checkStockAndNotify(List<CatalogItem> items) async {
    await _stockNotificationHelper.checkStockLevels(items);
  }

  /// Handle restock action
  void _handleRestock(CatalogItem item) {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (_) => StockProcurementRequestScreen()));
  }

  /// Check if restock button should be shown
  bool _shouldShowRestockButton(ItemStatus? status) {
    return status == ItemStatus.lowStock || status == ItemStatus.outOfStock;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: BlocBuilder<BranchStockBloc, BranchStockState>(
        builder: (context, state) {
          if (state is BranchStockLoading || state is BranchStockRefreshing) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return shimmerCatalogCard(constraints.maxWidth);
              },
            );
          }
          if (state is BranchStockEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "No stock data found",
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is BranchStockError) {
            AppLogger.log(state.error);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getErrorIcon(state.errorType),
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getErrorTitle(state.errorType),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF757575),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<BranchStockBloc>().add(LoadBranchStock());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is BranchStockLoaded) {
            // Check stock levels and send notifications
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkStockAndNotify(state.filteredItems);
            });

            return _buildBody(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, BranchStockLoaded state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _getHorizontalPadding(constraints.maxWidth);
        final maxContentWidth = _getMaxContentWidth(constraints.maxWidth);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<BranchStockBloc>().add(RefreshBranchStock());
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: Column(
                children: [
                  Container(
                    color: kPrimary,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: _getSearchSectionPadding(constraints.maxWidth),
                    ),
                    child: Column(
                      children: [
                        _buildSearchBar(context, constraints.maxWidth, state),
                        SizedBox(
                          height: _getCategorySpacing(constraints.maxWidth),
                        ),
                        _buildCategoryTabs(
                          context,
                          constraints.maxWidth,
                          state,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: widget.isTableView
                        ? GestureDetector(
                            child: _buildTableView(
                              constraints.maxWidth,
                              horizontalPadding,
                              state,
                            ),
                          )
                        : _buildCardView(
                            context,
                            constraints.maxWidth,
                            horizontalPadding,
                            state,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardView(
    BuildContext context,
    double screenWidth,
    double horizontalPadding,
    BranchStockLoaded state,
  ) {
    if (state.filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: _getSectionSpacing(screenWidth),
      ),
      children: state.filteredItems
          .map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: _getItemSpacing(screenWidth)),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => BranchStockDetailsScreen(
                        itemName: item.name,
                        stockId: item.id,
                      ),
                    ),
                  );
                },
                child: _buildCatalogItemCard(context, item, screenWidth, state),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCatalogItemCard(
    BuildContext context,
    CatalogItem item,
    double screenWidth,
    BranchStockLoaded state,
  ) {
    final nameFontSize = _getItemNameFontSize(screenWidth);
    final detailsFontSize = _getItemDetailsFontSize(screenWidth);

    // Get the actual itemId from the state
    final itemId = state.getItemId(item.name);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) =>
                BranchStockDetailsScreen(itemName: item.name, stockId: item.id),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(_getItemCardPadding(screenWidth)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (item.status != null) ...[
                  _buildStatusBadge(item.status!, screenWidth),
                  const Spacer(),
                ] else
                  const Spacer(),
                _buildQuantityControl(item, screenWidth),
              ],
            ),
            SizedBox(height: _getCardSectionSpacing(screenWidth)),
            Text(
              item.name,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: nameFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            if (item.expiryDays > 0 && item.expiryDays < 999) ...[
              const SizedBox(height: 4),
              Text(
                'Expires in ${item.expiryDays} days',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: detailsFontSize,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
            SizedBox(height: _getCardSectionSpacing(screenWidth)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0XFFECECEA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStorageIcon(item.storage),
                    size: _getInfoIconSize(screenWidth),
                    color: const Color(0xFF757575),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.storage,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: detailsFontSize,
                      fontWeight: FontWeight.w700,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.layers_outlined,
                    size: _getInfoIconSize(screenWidth),
                    color: const Color(0xFF757575),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.batches} ${item.batches == 1 ? 'Batch' : 'Batches'}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: detailsFontSize,
                      fontWeight: FontWeight.w700,
                      color: kprimaryTextColor1,
                    ),
                  ),
                ],
              ),
            ),
            // Add restock button for low stock or out of stock items
            if (_shouldShowRestockButton(item.status)) ...[
              SizedBox(height: _getCardSectionSpacing(screenWidth)),
              _buildRestockButton(
                screenWidth,
                onTap: () => _handleRestock(item),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build restock button widget
  Widget _buildRestockButton(double screenWidth, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _getRestockButtonPaddingHorizontal(screenWidth),
          vertical: _getRestockButtonPaddingVertical(screenWidth),
        ),
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Restock Now',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getRestockButtonFontSize(screenWidth),
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    double screenWidth,
    BranchStockLoaded state,
  ) {
    final fontSize = _getSearchFontSize(screenWidth);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getSearchPaddingHorizontal(screenWidth),
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: const Color(0xFF9E9E9E),
            size: _getSearchIconSize(screenWidth),
          ),
          SizedBox(width: _getSearchIconSpacing(screenWidth)),
          Expanded(
            child: TextField(
              cursorColor: kPrimary,
              controller: _searchController,
              onChanged: (value) {
                context.read<BranchStockBloc>().add(SearchItems(query: value));
              },
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search for foods',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9E9E9E),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
          if (state.searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                context.read<BranchStockBloc>().add(const ClearSearch());
              },
              child: Icon(
                Icons.clear,
                color: const Color(0xFF9E9E9E),
                size: _getSearchIconSize(screenWidth),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(
    BuildContext context,
    double screenWidth,
    BranchStockLoaded state,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: state.categories.map((category) {
          final isSelected = state.selectedCategory == category;
          return Padding(
            padding: EdgeInsets.only(right: _getTabSpacing(screenWidth)),
            child: _buildCategoryTab(
              context,
              category,
              isSelected,
              screenWidth,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryTab(
    BuildContext context,
    String category,
    bool isSelected,
    double screenWidth,
  ) {
    return GestureDetector(
      onTap: () {
        context.read<BranchStockBloc>().add(SelectCategory(category: category));
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _getTabPaddingHorizontal(screenWidth),
          vertical: _getTabPaddingVertical(screenWidth),
        ),
        decoration: BoxDecoration(
          color: isSelected ? kWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          category,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getTabFontSize(screenWidth),
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTableView(
    double screenWidth,
    double horizontalPadding,
    BranchStockLoaded state,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: _getSectionSpacing(screenWidth),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: _getTableHeaderHeight(screenWidth),
            dataRowHeight: _getTableRowHeight(screenWidth),
            horizontalMargin: _getTableHorizontalMargin(screenWidth),
            columnSpacing: _getTableColumnSpacing(screenWidth),
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F6F6)),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            columns: [
              DataColumn(
                label: Text(
                  'Item Name',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: kprimaryTextColor1,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: kprimaryTextColor1,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Quantity',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: kprimaryTextColor1,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Expiry',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: kprimaryTextColor1,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Storage',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: kprimaryTextColor1,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Batches',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: kprimaryTextColor1,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Category',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: kprimaryTextColor1,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Action',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: kprimaryTextColor1,
                  ),
                ),
              ),
            ],
            rows: state.filteredItems.map((item) {
              return DataRow(
                cells: [
                  DataCell(
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => BranchStockDetailsScreen(
                            itemName: item.name,
                            stockId: item.id,
                          ),
                        ),
                      );
                    },
                    Text(
                      item.name,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getTableCellFontSize(screenWidth),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  DataCell(
                    item.status != null
                        ? _buildTableStatusBadge(item.status!, screenWidth)
                        : Text(
                            'Good',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: _getTableCellFontSize(screenWidth),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF757575),
                            ),
                          ),
                  ),
                  DataCell(
                    Text(
                      '${item.quantity} ${item.unit}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getTableCellFontSize(screenWidth),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      item.expiryDays > 0
                          ? '${item.expiryDays} days'
                          : 'Expired',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getTableCellFontSize(screenWidth),
                        fontWeight: FontWeight.w400,
                        color: item.expiryDays > 0
                            ? const Color(0xFF757575)
                            : const Color(0xFFE53935),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Icon(
                          _getStorageIcon(item.storage),
                          size: _getTableIconSize(screenWidth),
                          color: const Color(0xFF757575),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.storage,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getTableCellFontSize(screenWidth),
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      '${item.batches}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getTableCellFontSize(screenWidth),
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      item.category,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getTableCellFontSize(screenWidth),
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ),
                  DataCell(
                    _shouldShowRestockButton(item.status)
                        ? GestureDetector(
                            onTap: () => _handleRestock(item),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: _getTableRestockPaddingHorizontal(
                                  screenWidth,
                                ),
                                vertical: _getTableRestockPaddingVertical(
                                  screenWidth,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: kPrimary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Restock',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: _getTableRestockFontSize(
                                    screenWidth,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTableStatusBadge(ItemStatus status, double screenWidth) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case ItemStatus.useSoon:
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFA1000C);
        label = 'USE SOON';
        break;
      case ItemStatus.lowStock:
        bgColor = const Color(0xFFFFF3E0);
        textColor = kPrimary;
        label = 'LOW STOCK';
        break;
      case ItemStatus.expired:
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFE53935);
        label = 'EXPIRED';
        break;
      case ItemStatus.nearReorder:
        bgColor = const Color(0xFFFFF9C4);
        textColor = const Color(0xFFF57F17);
        label = 'NEAR REORDER';
        break;
      case ItemStatus.outOfStock:
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        label = 'OUT OF STOCK';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getTableBadgePaddingHorizontal(screenWidth),
        vertical: _getTableBadgePaddingVertical(screenWidth),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getTableBadgeFontSize(screenWidth),
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ItemStatus status, double screenWidth) {
    Color bgColor;
    Color iconColor;
    String label;
    IconData icon;

    switch (status) {
      case ItemStatus.useSoon:
        bgColor = const Color(0xFFFFF3E0);
        iconColor = const Color(0XFFA1000C);
        label = 'USE SOON';
        icon = Icons.warning_amber_rounded;
        break;
      case ItemStatus.lowStock:
        bgColor = const Color(0xFFFFF3E0);
        iconColor = kPrimary;
        label = 'LOW STOCK';
        icon = Icons.inventory_2_outlined;
        break;
      case ItemStatus.expired:
        bgColor = const Color(0xFFFFEBEE);
        iconColor = const Color(0xFFE53935);
        label = 'EXPIRED';
        icon = Icons.error_outline;
        break;
      case ItemStatus.nearReorder:
        bgColor = const Color(0xFFFFFDE7); // Light yellow
        iconColor = const Color(0xFFF57F17); // Dark amber
        label = 'NEAR REORDER';
        icon = Icons.trending_down; // or Icons.show_chart
        break;
      case ItemStatus.outOfStock:
        bgColor = const Color(0xFFFFEBEE); // Light red
        iconColor = const Color(0xFFC62828); // Dark red
        label = 'OUT OF STOCK';
        icon = Icons.remove_circle_outline; // or Icons.block
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getStatusBadgePaddingHorizontal(screenWidth),
        vertical: _getStatusBadgePaddingVertical(screenWidth),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getStatusIconSize(screenWidth), color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getStatusFontSize(screenWidth),
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getErrorIcon(BranchStockErrorType errorType) {
    switch (errorType) {
      case BranchStockErrorType.network:
        return Icons.wifi_off;
      case BranchStockErrorType.timeout:
        return Icons.access_time;
      case BranchStockErrorType.server:
        return Icons.cloud_off;
      default:
        return Icons.error_outline;
    }
  }

  String _getErrorTitle(BranchStockErrorType errorType) {
    switch (errorType) {
      case BranchStockErrorType.network:
        return 'Connection Error';
      case BranchStockErrorType.timeout:
        return 'Request Timeout';
      case BranchStockErrorType.server:
        return 'Server Error';
      default:
        return 'Something Went Wrong';
    }
  }

  Widget _buildQuantityControl(CatalogItem item, double screenWidth) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _getQuantityTextPadding(screenWidth),
          ),
          child: Text(
            '${item.quantity} ${item.unit}',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getQuantityFontSize(screenWidth),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStorageIcon(String storage) {
    if (storage.toLowerCase().contains('freezer')) {
      return Icons.ac_unit;
    } else if (storage.toLowerCase().contains('dry')) {
      return Icons.inventory_2_outlined;
    }
    return Icons.storage;
  }

  // Responsive sizing functions
  double _getTableBadgePaddingHorizontal(double width) {
    if (width < 360) return 6;
    if (width < 600) return 8;
    return 10;
  }

  double _getTableBadgePaddingVertical(double width) {
    if (width < 360) return 2;
    if (width < 600) return 3;
    return 4;
  }

  double _getTableBadgeFontSize(double width) {
    if (width < 360) return 10;
    if (width < 600) return 11;
    return 12;
  }

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

  double _getSectionSpacing(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getSearchSectionPadding(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getCategorySpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
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

  double _getTabSpacing(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getTabPaddingHorizontal(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getTabPaddingVertical(double width) {
    if (width < 360) return 6;
    if (width < 600) return 7;
    return 8;
  }

  double _getTabFontSize(double width) {
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  double _getItemSpacing(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getItemCardPadding(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getItemNameFontSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }

  double _getItemDetailsFontSize(double width) {
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  double _getAppBarIconSize(double width) {
    if (width < 360) return 22;
    if (width < 600) return 24;
    return 26;
  }

  double _getAppBarTitleFontSize(double width) {
    if (width < 360) return 17;
    if (width < 600) return 18;
    return 19;
  }

  double _getCardSectionSpacing(double width) {
    if (width < 360) return 10;
    if (width < 600) return 12;
    return 14;
  }

  double _getStatusBadgePaddingHorizontal(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getStatusBadgePaddingVertical(double width) {
    if (width < 360) return 4;
    if (width < 600) return 5;
    return 6;
  }

  double _getStatusIconSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }

  double _getStatusFontSize(double width) {
    if (width < 360) return 10;
    if (width < 600) return 11;
    return 12;
  }

  double _getQuantityFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getQuantityTextPadding(double width) {
    if (width < 360) return 10;
    if (width < 600) return 12;
    return 14;
  }

  double _getInfoIconSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }

  // Table view
  double _getTableHeaderHeight(double width) {
    if (width < 360) return 48;
    if (width < 600) return 52;
    return 56;
  }

  double _getTableRowHeight(double width) {
    if (width < 360) return 56;
    if (width < 600) return 60;
    return 64;
  }

  double _getTableHorizontalMargin(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getTableColumnSpacing(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getTableHeaderFontSize(double width) {
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  double _getTableCellFontSize(double width) {
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  double _getTableIconSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 16;
    return 18;
  }

  // Restock button sizing functions
  double _getRestockButtonPaddingHorizontal(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getRestockButtonPaddingVertical(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getRestockButtonFontSize(double width) {
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  double _getRestockButtonIconSize(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getRestockButtonIconSpacing(double width) {
    if (width < 360) return 6;
    if (width < 600) return 7;
    return 8;
  }

  double _getRestockButtonSpacing(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  // Table restock button sizing
  double _getTableRestockPaddingHorizontal(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getTableRestockPaddingVertical(double width) {
    if (width < 360) return 4;
    if (width < 600) return 5;
    return 6;
  }

  double _getTableRestockFontSize(double width) {
    if (width < 360) return 11;
    if (width < 600) return 12;
    return 13;
  }
}
