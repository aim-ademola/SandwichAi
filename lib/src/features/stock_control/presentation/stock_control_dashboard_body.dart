import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_summary_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_summary_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_summary_bloc/state.dart';

import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_summary_model.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/stock_control_drawer.dart';
import 'package:intl/intl.dart';

final NumberFormat _commaFormatter = NumberFormat('#,##0');

class StockControlDashboardBodyScreen extends StatefulWidget {
  const StockControlDashboardBodyScreen({super.key});

  @override
  State<StockControlDashboardBodyScreen> createState() =>
      _StockControlDashboardBodyScreenState();
}

class _StockControlDashboardBodyScreenState
    extends State<StockControlDashboardBodyScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Load data on init
    context.read<BranchStockSummaryBloc>().add(
      LoadBranchStockSummary(
        branchId: context.read<BranchStockSummaryBloc>().branchId,
      ),
    );
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        drawer: StockControlAppDrawer(),
        key: _scaffoldKey,
        backgroundColor: context.modeBackground,

        body: BlocConsumer<BranchStockSummaryBloc, BranchStockSummaryState>(
          listener: (context, state) {
            if (state is BranchStockSummaryError) {
              AppLogger.log(state.error);
            }
            if (state is BranchStockSummaryEmpty) {
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
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
          },
          builder: (context, state) {
            if (state is BranchStockSummaryLoading ||
                state is BranchStockSummaryRefreshing) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return shimmerCatalogCard(constraints.maxWidth);
                },
              );
            }

            if (state is BranchStockSummaryError) {
              return _buildErrorWidget(context, state);
            }
            if (state is BranchStockSummaryEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
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

            if (state is BranchStockSummaryLoaded ||
                state is BranchStockSummaryRefreshing) {
              final loadedState = state is BranchStockSummaryLoaded
                  ? state
                  : (state as BranchStockSummaryRefreshing).currentData;

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<BranchStockSummaryBloc>().add(
                    const RefreshBranchStockSummary(),
                  );
                },
                color: context.modePrimary,
                child: _buildBody(
                  context,
                  state is BranchStockSummaryLoaded
                      ? loadedState
                      : loadedState as BranchStockSummaryResponse,
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    BranchStockSummaryError state,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
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
                color: context.modeTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<BranchStockSummaryBloc>().add(
                  LoadBranchStockSummary(
                    branchId: context.read<BranchStockSummaryBloc>().branchId,
                  ),
                );
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

  IconData _getErrorIcon(BranchStockSummaryErrorType errorType) {
    switch (errorType) {
      case BranchStockSummaryErrorType.network:
        return Icons.wifi_off;
      case BranchStockSummaryErrorType.timeout:
        return Icons.access_time;
      case BranchStockSummaryErrorType.server:
        return Icons.cloud_off;
      default:
        return Icons.error_outline;
    }
  }

  String _getErrorTitle(BranchStockSummaryErrorType errorType) {
    switch (errorType) {
      case BranchStockSummaryErrorType.network:
        return 'Connection Error';
      case BranchStockSummaryErrorType.timeout:
        return 'Request Timeout';
      case BranchStockSummaryErrorType.server:
        return 'Server Error';
      default:
        return 'Something Went Wrong';
    }
  }

  Widget _buildBody(BuildContext context, dynamic loadedState) {
    final state = loadedState is BranchStockSummaryLoaded ? loadedState : null;

    bool isValueVisible = true; // initial state

    void toggleVisibility() {
      setState(() {
        isValueVisible = !isValueVisible;
      });
    }

    if (state == null) return const SizedBox.shrink();

    final response = state.response;
    final overview = response.data.overview;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _getHorizontalPadding(constraints.maxWidth);
        final maxContentWidth = _getMaxContentWidth(constraints.maxWidth);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildStatsCards(constraints.maxWidth, overview),
                SizedBox(height: _getSectionSpacing(constraints.maxWidth)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildTotalStockCard(
                    constraints.maxWidth,
                    overview.totalValue,
                    isValueVisible,
                    toggleVisibility,
                  ),
                ),
                SizedBox(height: _getSectionSpacing(constraints.maxWidth)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildStockLevelsSection(
                    constraints.maxWidth,
                    state.filteredItems,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCards(double screenWidth, Overview overview) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            _buildStatCard(
              'Total Items',
              overview.totalItems,
              context.modePrimary,
              screenWidth,
            ),
            SizedBox(width: _getCardSpacing(screenWidth)),
            _buildStatCard(
              'Total Stock Quantity',
              overview.totalStockQuantity,
              context.modePrimary,
              screenWidth,
            ),
            SizedBox(width: _getCardSpacing(screenWidth)),
            _buildStatCard(
              'In Stock',
              overview.statusBreakdown.inStock,
              context.modePrimary,
              screenWidth,
            ),
            SizedBox(width: _getCardSpacing(screenWidth)),
            _buildStatCard(
              'Expired Stock',
              overview.statusBreakdown.expired,
              context.modeError,
              screenWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    num value,
    Color valueColor,
    double screenWidth,
  ) {
    final labelFontSize = _getStatLabelFontSize(screenWidth);
    final valueFontSize = _getStatValueFontSize(screenWidth);

    final formattedValue = _commaFormatter.format(value);

    return Container(
      padding: EdgeInsets.all(_getStatCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modePrimary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w400,
              color: context.modeTextMuted,
            ),
          ),
          SizedBox(height: _getStatValueSpacing(screenWidth)),
          Text(
            formattedValue,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalStockCard(
    double screenWidth,
    double totalValue,
    bool isValueVisible,
    VoidCallback onToggleVisibility,
  ) {
    final labelFontSize = _getTotalStockLabelFontSize(screenWidth);
    final valueFontSize = _getTotalStockValueFontSize(screenWidth);

    return Container(
      padding: EdgeInsets.all(_getTotalStockPadding(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Stock Value',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w400,
                      color: context.modeTextSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: _getTotalStockValueSpacing(screenWidth)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  isValueVisible ? _formatCurrency(totalValue) : '••••••',
                  key: ValueKey(isValueVisible),
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.bold,
                    color: context.modeTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockLevelsSection(
    double screenWidth,
    List<InventoryItem> items,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No stock categories found',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 16,
              color: context.modeTextMuted,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock Levels by Category',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getSectionTitleFontSize(screenWidth),
            fontWeight: FontWeight.w600,
            color: context.modeTextPrimary,
          ),
        ),
        SizedBox(height: _getStockLevelSpacing(screenWidth)),
        ...items.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: _getItemSpacing(screenWidth)),
            child: _buildInventoryItemCard(item, screenWidth),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryItemCard(InventoryItem item, double screenWidth) {
    final nameFontSize = _getItemNameFontSize(screenWidth);
    final detailsFontSize = _getItemDetailsFontSize(screenWidth);
    final badgeFontSize = _getItemBadgeFontSize(screenWidth);
    final imageSize = _getItemImageSize(screenWidth);

    return Container(
      padding: EdgeInsets.all(_getItemCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modePrimary, width: 1.5),
      ),
      child: Row(
        children: [
          // Item image
          Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: context.modeSurfaceMuted,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildItemImage(item),
            ),
          ),
          SizedBox(width: _getItemContentSpacing(screenWidth)),
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.unitsRemaining} Units remaining',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: detailsFontSize,
                    fontWeight: FontWeight.w400,
                    color: context.modeTextMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.itemCount} items • ${_formatCurrency(item.totalValue)}',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: detailsFontSize - 1,
                    fontWeight: FontWeight.w400,
                    color: context.modeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Stock level badge
          _buildStockLevelBadge(item.stockLevel, badgeFontSize, screenWidth),
        ],
      ),
    );
  }

  Widget _buildItemImage(InventoryItem item) {
    String assetPath;

    switch (item.category.toLowerCase()) {
      case 'vegetable':
        assetPath = 'assets/img/tomatoe_bask.png';
        break;
      case 'grain':
        assetPath = 'assets/img/rice_bag.png';
        break;
      case 'protein':
        assetPath = 'assets/img/beef.jpg';
        break;
      case 'dairy':
        assetPath = 'assets/img/chesse.jpg';
        break;
      case 'spices':
        assetPath = 'assets/img/spices.jpg';
      case 'beverage':
        assetPath = 'assets/img/beverage.JPG';
        break;
      case 'oil':
        assetPath = 'assets/img/oil.jpg';
        break;
      case 'seasoning':
        assetPath = 'assets/img/seasonng.jpg';

      case 'others':
        assetPath = '';
        break;
      default:
        assetPath = '';
    }

    return Container(
      color: context.modeSurfaceMuted,
      child: Center(
        child: Image.asset(
          assetPath,
          width: 45,
          height: 45,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.inventory_2,
              size: 45,
              color: context.modeTextMuted,
            );
          },
        ),
      ),
    );
  }

  Widget _buildStockLevelBadge(
    String level,
    double fontSize,
    double screenWidth,
  ) {
    Color bgColor;
    Color textColor;

    switch (level.toLowerCase()) {
      case 'low':
        bgColor = context.modePrimary.withValues(alpha: 0.12);
        textColor = context.modePrimary;
        break;
      case 'medium':
        bgColor = context.modeWarning.withValues(alpha: 0.16);
        textColor = context.modeWarning;
        break;
      case 'high':
        bgColor = context.modeSuccess.withValues(alpha: 0.16);
        textColor = context.modeSuccess;
        break;
      default:
        bgColor = context.modeSurfaceMuted;
        textColor = context.modeTextMuted;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getBadgePaddingHorizontal(screenWidth),
        vertical: _getBadgePaddingVertical(screenWidth),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
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

  double _getSectionSpacing(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getCardSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getStatCardPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getStatLabelFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getStatValueFontSize(double width) {
    if (width < 360) return 28;
    if (width < 600) return 32;
    return 36;
  }

  double _getStatValueSpacing(double width) {
    if (width < 360) return 4;
    if (width < 600) return 6;
    return 8;
  }

  double _getTotalStockPadding(double width) {
    if (width < 360) return 20;
    if (width < 600) return 24;
    return 28;
  }

  double _getTotalStockLabelFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getTotalStockValueFontSize(double width) {
    if (width < 360) return 28;
    if (width < 600) return 32;
    return 36;
  }

  double _getTotalStockValueSpacing(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getSectionTitleFontSize(double width) {
    if (width < 360) return 16;
    if (width < 600) return 17;
    return 18;
  }

  double _getStockLevelSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getItemSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getItemCardPadding(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getItemImageSize(double width) {
    if (width < 360) return 60;
    if (width < 600) return 70;
    return 80;
  }

  double _getItemContentSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getItemNameFontSize(double width) {
    if (width < 360) return 15;
    if (width < 600) return 16;
    return 17;
  }

  double _getItemDetailsFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getItemBadgeFontSize(double width) {
    if (width < 360) return 11;
    if (width < 600) return 12;
    return 13;
  }

  double _getBadgePaddingHorizontal(double width) {
    if (width < 360) return 10;
    if (width < 600) return 12;
    return 14;
  }

  double _getBadgePaddingVertical(double width) {
    if (width < 360) return 4;
    if (width < 600) return 5;
    return 6;
  }
}
