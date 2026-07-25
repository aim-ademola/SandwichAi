import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_control_reports_cubit/stock_control_reports_cubit.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_control_reports_cubit/stock_control_reports_state.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_summary_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_summary_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_summary_bloc/state.dart';

import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_summary_model.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/stock_control_drawer.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/stock_control_report_screens.dart';
import 'package:intl/intl.dart';

final NumberFormat _commaFormatter = NumberFormat('#,##0');

class _ReportShortcut {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;

  const _ReportShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screen,
  });
}

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
    context.read<StockControlReportsCubit>().loadMovementTrends(
      branchId: context.read<BranchStockSummaryBloc>().branchId,
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
                    Center(
                      child: AppIcon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: context.modeTextMuted,
                      ),
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
                    Center(
                      child: AppIcon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: context.modeTextMuted,
                      ),
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
            Center(
              child: AppIcon(
                _getErrorIcon(state.errorType),
                size: 64,
                color: context.modeError,
              ),
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
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              children: [
                _buildStatsCards(constraints.maxWidth, overview),
                SizedBox(height: _getSectionSpacing(constraints.maxWidth)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildReportsShortcutSection(constraints.maxWidth),
                ),
                SizedBox(height: _getSectionSpacing(constraints.maxWidth)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildTotalStockCard(
                    constraints.maxWidth,
                    overview.totalValue,
                  ),
                ),
                SizedBox(height: _getSectionSpacing(constraints.maxWidth)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildStockStatusChart(overview),
                ),
                SizedBox(height: _getSectionSpacing(constraints.maxWidth)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildMovementTrendsChart(),
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
    final horizontalPadding = _getHorizontalPadding(screenWidth);
    final spacing = _getCardSpacing(screenWidth);
    final visibleCards = screenWidth < 600 ? 3 : 4;
    final availableWidth =
        screenWidth - (horizontalPadding * 2) - (spacing * (visibleCards - 1));
    final cardWidth = (availableWidth / visibleCards).clamp(86.0, 160.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Overview',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: screenWidth < 360 ? 20 : 22,
              fontWeight: FontWeight.w800,
              color: context.modeTextPrimary,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A quick snapshot of your inventory',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: context.modeTextSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildStatCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Total Items',
                    value: overview.totalItems,
                    valueColor: context.modePrimary,
                    screenWidth: screenWidth,
                  ),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: _buildStatCard(
                    icon: Icons.category_outlined,
                    label: 'Total Stock Quantity',
                    value: overview.totalStockQuantity,
                    valueColor: context.modePrimary,
                    screenWidth: screenWidth,
                  ),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: _buildStatCard(
                    icon: Icons.fact_check_outlined,
                    label: 'In Stock',
                    value: overview.statusBreakdown.inStock,
                    valueColor: context.modePrimary,
                    screenWidth: screenWidth,
                  ),
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: _buildStatCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Expired',
                    value: overview.statusBreakdown.expired,
                    valueColor: context.modePrimary,
                    screenWidth: screenWidth,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsShortcutSection(double screenWidth) {
    final shortcuts = [
      _ReportShortcut(
        icon: Icons.summarize_outlined,
        title: 'Reports',
        subtitle: 'View and analyze detailed stock reports',
        screen: const StockReportsScreen(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock Reports',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getSectionTitleFontSize(screenWidth),
            fontWeight: FontWeight.w600,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...shortcuts.map((shortcut) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => shortcut.screen),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Ink(
                  height: screenWidth < 360 ? 72 : 78,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: context.modeSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.modePrimary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: context.modePrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: AppIcon(
                            shortcut.icon,
                            color: context.modePrimary,
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              shortcut.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.modeTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              shortcut.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: context.modeTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppIcon(
                        Icons.chevron_right_rounded,
                        color: context.modePrimary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required num value,
    required Color valueColor,
    required double screenWidth,
  }) {
    final labelFontSize = _getStatLabelFontSize(screenWidth);
    final valueFontSize = _getStatValueFontSize(screenWidth);

    final formattedValue = _commaFormatter.format(value);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: _getStatCardHeight(screenWidth),
        padding: EdgeInsets.all(_getStatCardPadding(screenWidth)),
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.2
                    : 0.06,
              ),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -34,
              bottom: -30,
              child: Container(
                width: 104,
                height: 62,
                decoration: BoxDecoration(
                  color: context.modePrimary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: context.modePrimary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: AppIcon(icon, color: context.modePrimary, size: 15),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w500,
                    color: context.modeTextSecondary,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: _getStatValueSpacing(screenWidth)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formattedValue,
                      maxLines: 1,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.w800,
                        color: valueColor,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalStockCard(double screenWidth, double totalValue) {
    final labelFontSize = _getTotalStockLabelFontSize(screenWidth);
    final valueFontSize = _getTotalStockValueFontSize(screenWidth);

    return Container(
      padding: EdgeInsets.all(_getTotalStockPadding(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modePrimary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.05,
            ),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: screenWidth < 360 ? -32 : -22,
            bottom: -16,
            child: Opacity(
              opacity: Theme.of(context).brightness == Brightness.dark
                  ? 0.16
                  : 0.42,
              child: SvgPicture.asset(
                'assets/svg/stock_value_wallet.svg',
                width: screenWidth < 360 ? 116 : 142,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.modePrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: AppIcon(
                    Icons.account_balance_wallet_outlined,
                    color: context.modePrimary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: screenWidth < 360 ? 42 : 58),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Stock Value',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.w500,
                          color: context.modeTextSecondary,
                        ),
                      ),
                      SizedBox(height: _getTotalStockValueSpacing(screenWidth)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formatCurrency(totalValue),
                            maxLines: 1,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: valueFontSize,
                              fontWeight: FontWeight.w800,
                              color: context.modeTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
            return Center(
              child: AppIcon(
                Icons.inventory_2,
                size: 45,
                color: context.modeTextMuted,
              ),
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
    if (width < 360) return 8;
    if (width < 600) return 14;
    return 16;
  }

  double _getStatCardHeight(double width) {
    if (width < 360) return 100;
    if (width < 600) return 122;
    return 112;
  }

  double _getStatLabelFontSize(double width) {
    if (width < 360) return 10;
    if (width < 600) return 12;
    return 13;
  }

  double _getStatValueFontSize(double width) {
    if (width < 360) return 19;
    if (width < 600) return 24;
    return 28;
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
    if (width < 360) return 18;
    if (width < 600) return 21;
    return 28;
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

  Widget _buildStockStatusChart(Overview overview) {
    final status = overview.statusBreakdown;
    final total = status.inStock + status.expired;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Availability Breakdown',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 25,
                      sections: [
                        PieChartSectionData(
                          color: context.modePrimary,
                          value: status.inStock.toDouble(),
                          title:
                              '${((status.inStock / total) * 100).toStringAsFixed(0)}%',
                          radius: 25,
                          titleStyle: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.modeTextInverse,
                          ),
                        ),
                        PieChartSectionData(
                          color: context.modeError,
                          value: status.expired.toDouble(),
                          title:
                              '${((status.expired / total) * 100).toStringAsFixed(0)}%',
                          radius: 25,
                          titleStyle: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.modeTextInverse,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _chartIndicator(
                      color: context.modePrimary,
                      label: 'In Stock (${status.inStock})',
                    ),
                    const SizedBox(height: 8),
                    _chartIndicator(
                      color: context.modeError,
                      label: 'Expired (${status.expired})',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovementTrendsChart() {
    return BlocBuilder<StockControlReportsCubit, StockControlReportsState>(
      builder: (context, state) {
        if (state.movementStatus == StockControlReportStatus.loading ||
            state.movementStatus == StockControlReportStatus.initial) {
          return Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.modeBorder),
            ),
            child: CircularProgressIndicator(color: context.modePrimary),
          );
        }

        final trends = state.movementTrends?.trends ?? const [];
        if (state.movementStatus == StockControlReportStatus.error ||
            trends.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.modeBorder),
            ),
            child: Row(
              children: [
                Center(
                  child: AppIcon(
                    Icons.show_chart,
                    color: context.modeTextMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.movementError ?? 'No movement trends available',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: context.modeTextMuted,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final visible = trends.length > 8
            ? trends.sublist(trends.length - 8)
            : trends;
        final maxValue = visible
            .map((trend) => trend.netQty.abs())
            .fold<double>(1, (max, value) => value > max ? value : max);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.modeSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.modeBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock Movement Trends',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    minY: -maxValue,
                    maxY: maxValue,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: context.modeBorder, strokeWidth: 1),
                    ),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < visible.length; i++)
                            FlSpot(i.toDouble(), visible[i].netQty),
                        ],
                        isCurved: true,
                        color: context.modePrimary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: context.modePrimary.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chartIndicator({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.modeTextPrimary,
          ),
        ),
      ],
    );
  }
}
