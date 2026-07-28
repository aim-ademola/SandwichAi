import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/utils/debouncer.dart';
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
  final _stockNotificationHelper = StockNotificationHelper();
  final _searchController = TextEditingController();
  late final Debouncer _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _searchDebouncer = Debouncer(
      delay: const Duration(milliseconds: 350),
    );
    // Load branch stock on init
    context.read<BranchStockBloc>().add(LoadBranchStock());
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
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
      backgroundColor: context.modeBackground,
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
                  AppIcon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: context.modeTextMuted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "No stock data found",
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 16,
                      color: context.modeTextMuted,
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
                    AppIcon(
                      _getErrorIcon(state.errorType),
                      size: 64,
                      color: context.modeError,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getErrorTitle(state.errorType),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.modeTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: context.modeTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<BranchStockBloc>().add(LoadBranchStock());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.modePrimary,
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
                          color: context.modeTextInverse,
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
                    color: context.modePrimary,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: _getSearchSectionPadding(constraints.maxWidth),
                    ),
                    child: Column(
                      children: [
                        _buildSearchField(context, constraints.maxWidth, state),
                        SizedBox(
                          height: _getSearchToTabSpacing(constraints.maxWidth),
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
            AppIcon(
              Icons.inventory_2_outlined,
              size: 64,
              color: context.modeTextMuted,
            ),
            const SizedBox(height: 16),
            Text(
              state.searchQuery.trim().isEmpty
                  ? 'No items found'
                  : 'No items match "${state.searchQuery}"',
              style: TextStyle(fontSize: 16, color: context.modeTextSecondary),
              textAlign: TextAlign.center,
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
          color: context.modeSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.modeBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (item.status != null)
                        _buildStatusBadge(item.status!, screenWidth),
                      if (item.isLocked)
                        _buildInfoBadge(
                          'LOCKED',
                          Icons.lock_outline,
                          context.modeError,
                          screenWidth,
                        ),
                      if (item.allowNegativeStock)
                        _buildInfoBadge(
                          'NEGATIVE OK',
                          Icons.remove_circle_outline,
                          context.modeWarning,
                          screenWidth,
                        ),
                    ],
                  ),
                ),
                _buildQuantityControl(item, screenWidth),
              ],
            ),
            SizedBox(height: _getCardSectionSpacing(screenWidth)),
            Text(
              item.name,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: nameFontSize,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            if (item.sku.isNotEmpty || item.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (item.sku.isNotEmpty) item.sku,
                  if (item.description.isNotEmpty) item.description,
                ].join(' - '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: detailsFontSize,
                  fontWeight: FontWeight.w400,
                  color: context.modeTextSecondary,
                ),
              ),
            ],
            if (item.expiryDays > 0 && item.expiryDays < 999) ...[
              const SizedBox(height: 4),
              Text(
                'Expires in ${item.expiryDays} days',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: detailsFontSize,
                  fontWeight: FontWeight.w400,
                  color: context.modeTextSecondary,
                ),
              ),
            ],
            SizedBox(height: _getCardSectionSpacing(screenWidth)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: context.modeSurfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  if (item.storage.trim().isNotEmpty) ...[
                    AppIcon(
                      _getStorageIcon(item.storage),
                      size: _getInfoIconSize(screenWidth),
                      color: context.modeTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.storage,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: detailsFontSize,
                        fontWeight: FontWeight.w700,
                        color: context.modeTextPrimary,
                      ),
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  AppIcon(
                    Icons.layers_outlined,
                    size: _getInfoIconSize(screenWidth),
                    color: context.modeTextSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.batches} ${item.batches == 1 ? 'Batch' : 'Batches'}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: detailsFontSize,
                      fontWeight: FontWeight.w700,
                      color: context.modeTextPrimary,
                    ),
                  ),
                  if (item.expiringBatchCount > 0) ...[
                    const SizedBox(width: 10),
                    AppIcon(
                      Icons.warning_amber_rounded,
                      size: _getInfoIconSize(screenWidth),
                      color: context.modeWarning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.expiringBatchCount} expiring',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: detailsFontSize,
                        fontWeight: FontWeight.w700,
                        color: context.modeWarning,
                      ),
                    ),
                  ],
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
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: _getRestockButtonPaddingHorizontal(screenWidth),
          vertical: _getRestockButtonPaddingVertical(screenWidth),
        ),
        decoration: BoxDecoration(
          color: context.modePrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Raise Procurement Request',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getRestockButtonFontSize(screenWidth),
            fontWeight: FontWeight.w600,
            color: context.modeTextInverse,
          ),
        ),
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

  Widget _buildSearchField(
    BuildContext context,
    double screenWidth,
    BranchStockLoaded state,
  ) {
    if (_searchController.text != state.searchQuery) {
      _searchController.value = TextEditingValue(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: _getSearchFontSize(screenWidth),
        color: context.modeTextPrimary,
      ),
      onChanged: (value) {
        _searchDebouncer(() {
          if (!mounted) return;
          context.read<BranchStockBloc>().add(SearchItems(query: value.trim()));
        });
      },
      decoration: InputDecoration(
        hintText: 'Search stock items...',
        hintStyle: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getSearchFontSize(screenWidth),
          color: context.modeTextMuted,
        ),
        prefixIcon: AppIconSlot(
          Icons.search_rounded,
          color: context.modeTextSecondary,
          size: _getSearchIconSize(screenWidth),
        ),
        suffixIcon: state.searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: AppIcon(
                  Icons.close_rounded,
                  color: context.modeTextSecondary,
                  size: _getSearchIconSize(screenWidth),
                ),
                onPressed: () {
                  _searchDebouncer.cancel();
                  _searchController.clear();
                  context.read<BranchStockBloc>().add(const ClearSearch());
                },
              ),
        filled: true,
        fillColor: context.modeSurface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: _getSearchHorizontalPadding(screenWidth),
          vertical: _getSearchVerticalPadding(screenWidth),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getSearchRadius(screenWidth)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getSearchRadius(screenWidth)),
          borderSide: BorderSide(
            color: context.modeBorder.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getSearchRadius(screenWidth)),
          borderSide: BorderSide(color: context.modePrimary, width: 1.5),
        ),
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
          color: isSelected ? context.modeSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          category,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getTabFontSize(screenWidth),
            fontWeight: FontWeight.w700,
            color: isSelected
                ? context.modeTextPrimary
                : context.modeTextInverse,
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
          color: context.modeSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.modeBorder, width: 1),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: _getTableHeaderHeight(screenWidth),
            dataRowMinHeight: _getTableRowHeight(screenWidth),
            dataRowMaxHeight: _getTableRowHeight(screenWidth),
            horizontalMargin: _getTableHorizontalMargin(screenWidth),
            columnSpacing: _getTableColumnSpacing(screenWidth),
            headingRowColor: WidgetStateProperty.all(context.modeSurfaceAlt),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            columns: [
              DataColumn(
                label: Text(
                  'Item Name',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: context.modeTextPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: context.modeTextPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Quantity',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: context.modeTextPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Expiry',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: context.modeTextPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Storage',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: context.modeTextPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Batches',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: context.modeTextPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Category',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: context.modeTextPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Action',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getTableHeaderFontSize(screenWidth),
                    fontWeight: FontWeight.w700,
                    color: context.modeTextPrimary,
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
                      item.sku.isEmpty
                          ? item.name
                          : '${item.name}\n${item.sku}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getTableCellFontSize(screenWidth),
                        fontWeight: FontWeight.w600,
                        color: context.modeTextPrimary,
                      ),
                    ),
                  ),
                  DataCell(
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        item.status != null
                            ? _buildTableStatusBadge(item.status!, screenWidth)
                            : Text(
                                'Good',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: _getTableCellFontSize(screenWidth),
                                  fontWeight: FontWeight.w500,
                                  color: context.modeTextSecondary,
                                ),
                              ),
                        if (item.isLocked)
                          _buildInfoBadge(
                            'LOCKED',
                            Icons.lock_outline,
                            context.modeError,
                            screenWidth,
                            compact: true,
                          ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      '${item.quantity} ${item.unit}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getTableCellFontSize(screenWidth),
                        fontWeight: FontWeight.w600,
                        color: context.modeTextPrimary,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      item.expiryDisplay,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getTableCellFontSize(screenWidth),
                        fontWeight: FontWeight.w400,
                        color: item.expiryDays >= 0
                            ? context.modeTextSecondary
                            : context.modeError,
                      ),
                    ),
                  ),
                  DataCell(
                    item.storage.trim().isEmpty
                        ? Text(
                            '-',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: _getTableCellFontSize(screenWidth),
                              fontWeight: FontWeight.w500,
                              color: context.modeTextMuted,
                            ),
                          )
                        : Row(
                            children: [
                              AppIcon(
                                _getStorageIcon(item.storage),
                                size: _getTableIconSize(screenWidth),
                                color: context.modeTextSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.storage,
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: _getTableCellFontSize(screenWidth),
                                  fontWeight: FontWeight.w500,
                                  color: context.modeTextSecondary,
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
                        color: context.modeTextSecondary,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      item.category,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getTableCellFontSize(screenWidth),
                        fontWeight: FontWeight.w500,
                        color: context.modeTextSecondary,
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
                                color: context.modePrimary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Restock',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: _getTableRestockFontSize(
                                    screenWidth,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: context.modeTextInverse,
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
        bgColor = context.modeWarning.withValues(alpha: 0.14);
        textColor = context.modeWarning;
        label = 'USE SOON';
        break;
      case ItemStatus.lowStock:
        bgColor = context.modePrimary.withValues(alpha: 0.12);
        textColor = context.modePrimary;
        label = 'LOW STOCK';
        break;
      case ItemStatus.expired:
        bgColor = context.modeError.withValues(alpha: 0.12);
        textColor = context.modeError;
        label = 'EXPIRED';
        break;
      case ItemStatus.nearReorder:
        bgColor = context.modeWarning.withValues(alpha: 0.14);
        textColor = context.modeWarning;
        label = 'NEAR REORDER';
        break;
      case ItemStatus.outOfStock:
        bgColor = context.modeError.withValues(alpha: 0.12);
        textColor = context.modeError;
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
        bgColor = context.modeWarning.withValues(alpha: 0.14);
        iconColor = context.modeWarning;
        label = 'USE SOON';
        icon = Icons.warning_amber_rounded;
        break;
      case ItemStatus.lowStock:
        bgColor = context.modePrimary.withValues(alpha: 0.12);
        iconColor = context.modePrimary;
        label = 'LOW STOCK';
        icon = Icons.inventory_2_outlined;
        break;
      case ItemStatus.expired:
        bgColor = context.modeError.withValues(alpha: 0.12);
        iconColor = context.modeError;
        label = 'EXPIRED';
        icon = Icons.error_outline;
        break;
      case ItemStatus.nearReorder:
        bgColor = context.modeWarning.withValues(alpha: 0.14);
        iconColor = context.modeWarning;
        label = 'NEAR REORDER';
        icon = Icons.trending_down;
        break;
      case ItemStatus.outOfStock:
        bgColor = context.modeError.withValues(alpha: 0.12);
        iconColor = context.modeError;
        label = 'OUT OF STOCK';
        icon = Icons.remove_circle_outline;
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
          AppIcon(
            icon,
            size: _getStatusIconSize(screenWidth),
            color: iconColor,
          ),
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

  Widget _buildInfoBadge(
    String label,
    IconData icon,
    Color color,
    double screenWidth, {
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact
            ? _getTableBadgePaddingHorizontal(screenWidth)
            : _getStatusBadgePaddingHorizontal(screenWidth),
        vertical: compact
            ? _getTableBadgePaddingVertical(screenWidth)
            : _getStatusBadgePaddingVertical(screenWidth),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon,
            size: compact
                ? _getTableIconSize(screenWidth)
                : _getStatusIconSize(screenWidth),
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: compact
                  ? _getTableBadgeFontSize(screenWidth)
                  : _getStatusFontSize(screenWidth),
              fontWeight: FontWeight.w600,
              color: color,
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
              color: context.modeTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStorageIcon(String storage) {
    final label = storage.toLowerCase();
    if (label.contains('freezer') || label.contains('frozen')) {
      return Icons.ac_unit;
    } else if (label.contains('dry')) {
      return Icons.inventory_2_outlined;
    } else if (label.contains('protein') ||
        label.contains('meat') ||
        label.contains('chicken')) {
      return Icons.set_meal_outlined;
    } else if (label.contains('spice') || label.contains('seasoning')) {
      return Icons.spa_outlined;
    } else if (label.contains('grain') || label.contains('rice')) {
      return Icons.grass_outlined;
    } else if (label.contains('dairy') || label.contains('milk')) {
      return Icons.local_drink_outlined;
    } else if (label.contains('oil')) {
      return Icons.opacity_outlined;
    } else if (label.contains('fruit') ||
        label.contains('vegetable') ||
        label.contains('fresh')) {
      return Icons.eco_outlined;
    }
    return Icons.category_outlined;
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

  double _getSearchToTabSpacing(double width) {
    if (width < 360) return 10;
    if (width < 600) return 12;
    return 14;
  }

  double _getSearchFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getSearchIconSize(double width) {
    if (width < 360) return 19;
    if (width < 600) return 20;
    return 22;
  }

  double _getSearchHorizontalPadding(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getSearchVerticalPadding(double width) {
    if (width < 360) return 10;
    if (width < 600) return 12;
    return 14;
  }

  double _getSearchRadius(double width) {
    if (width < 360) return 10;
    if (width < 600) return 12;
    return 14;
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
