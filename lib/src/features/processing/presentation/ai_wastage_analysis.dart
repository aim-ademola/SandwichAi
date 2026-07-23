import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/globals/drawer_toggle.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/bloc/wastage_analysis_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/wastage_analysis_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/wastage_analysis_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/wastage_analysis_model.dart';
import 'package:sandwich_ai/src/features/processing/presentation/processing_drawer.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';

// ignore: must_be_immutable
class WastageAnalysisScreen extends StatefulWidget {
  bool isFromStock;
  WastageAnalysisScreen({super.key, required this.isFromStock});

  @override
  State<WastageAnalysisScreen> createState() => _WastageAnalysisScreenState();
}

class _WastageAnalysisScreenState extends State<WastageAnalysisScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedPeriod = 30;
  final List<int> _periods = [7, 14, 30, 60, 90];

  @override
  void initState() {
    super.initState();
    context.read<WastageAnalysisBloc>().add(
      LoadWastageAnalysis(daysBack: _selectedPeriod),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: widget.isFromStock ? SizedBox() : ProcessingAppDrawer(),
        backgroundColor: context.modeBackground,
        appBar: _buildAppBar(),
        body: BlocConsumer<WastageAnalysisBloc, WastageAnalysisState>(
          listener: (context, state) {
            if (state is WastageAnalysisError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.error,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: context.modeTextInverse,
                    ),
                  ),
                  backgroundColor: context.modeError,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is WastageAnalysisLoading) {
              return _buildLoadingState();
            }

            if (state is WastageAnalysisEmpty) {
              return _buildEmptyState(state.daysBack);
            }

            if (state is WastageAnalysisLoaded) {
              return _buildLoadedState(state.analysis, state.daysBack);
            }

            if (state is WastageAnalysisRefreshing) {
              return _buildLoadedState(
                state.currentData,
                _selectedPeriod,
                isRefreshing: true,
              );
            }

            return _buildInitialState();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.modeSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: widget.isFromStock
          ? IconButton(
              icon: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
              onPressed: () => Navigator.pop(context),
            )
          : IconButton(
              icon: AppIcon(Icons.menu, color: context.modeTextPrimary),
              tooltip: 'Open drawer',
              onPressed: _openDrawer,
            ),
      title: Text(
        'AI Wastage Analysis',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: context.modeTextPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        if (widget.isFromStock)
          IconButton(
            icon: AppIcon(Icons.menu, color: context.modeTextPrimary),
            tooltip: 'Open drawer',
            onPressed: _openDrawer,
          ),
        BlocBuilder<WastageAnalysisBloc, WastageAnalysisState>(
          builder: (context, state) {
            if (state is WastageAnalysisLoaded) {
              return IconButton(
                icon: AppIcon(Icons.refresh, color: context.modeTextPrimary),
                onPressed: () {
                  context.read<WastageAnalysisBloc>().add(
                    RefreshWastageAnalysis(daysBack: _selectedPeriod),
                  );
                },
                tooltip: 'Refresh',
              );
            }
            return IconButton(
              icon: AppIcon(Icons.refresh, color: context.modeTextPrimary),
              onPressed: () {
                context.read<WastageAnalysisBloc>().add(
                  LoadWastageAnalysis(daysBack: 30),
                );
              },
              tooltip: 'Refresh',
            );
          },
        ),
      ],
    );
  }

  void _openDrawer() {
    final scopedDrawer = AppDrawerScope.maybeOf(context);
    if (scopedDrawer != null) {
      scopedDrawer.openDrawer();
      return;
    }

    _scaffoldKey.currentState?.openDrawer();
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const AppIcon(
              Icons.analytics_outlined,
              size: 64,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Wastage Analytics',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'AI-powered wastage analysis to help you reduce costs and optimize inventory',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
                height: 1.5,
              ),
            ),
          ),
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

  Widget _buildEmptyState(int daysBack) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.modeSurfaceAlt,
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                Icons.inventory_2_outlined,
                size: 64,
                color: context.modeTextMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Wastage Data',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No wastage records found for the last $daysBack days.',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _buildPeriodSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(
    WastageAnalysisResponse analysis,
    int daysBack, {
    bool isRefreshing = false,
  }) {
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async {
        context.read<WastageAnalysisBloc>().add(
          RefreshWastageAnalysis(daysBack: _selectedPeriod),
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 20),
            _buildOverviewCards(analysis),
            const SizedBox(height: 20),
            _buildFinancialImpactCard(analysis.financialImpact),
            if (analysis.patterns.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildPatternsCard(analysis.patterns),
            ],
            if (analysis.highRiskItems.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildHighRiskItemsCard(analysis.highRiskItems),
            ],
            if (analysis.anomalies.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildAnomaliesCard(analysis.anomalies),
            ],
            if (analysis.recommendations.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildRecommendationsCard(analysis.recommendations),
            ],
            const SizedBox(height: 20),
            _buildGeneratedAtFooter(analysis.generatedAt),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder),
      ),
      child: Row(
        children: _periods.map((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = period);
                context.read<WastageAnalysisBloc>().add(
                  UpdateAnalysisPeriod(daysBack: period),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${period}d',
                  textAlign: TextAlign.center,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? context.modeTextInverse
                        : context.modeTextSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewCards(WastageAnalysisResponse analysis) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.receipt_long,
            label: 'Total Logs',
            value: '${analysis.totalLogs}',
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.calendar_today,
            label: 'Days Analyzed',
            value: '${analysis.daysAnalyzed}',
            color: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialImpactCard(FinancialImpact impact) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimary, Color(0xFFE85D4C)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const AppIcon(
                  Icons.trending_down,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Impact',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Total value lost to wastage',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '₦${NumberFormat('#,##0.00').format(impact.totalValueLost)}',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Loss',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const AppIcon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₦${NumberFormat('#,##0').format(impact.avgDailyLoss)}',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Avg Daily Loss',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const AppIcon(
                        Icons.warning_amber,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${impact.peakWastageItems.length}',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Peak Items',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (impact.peakWastageItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Wastage Items:',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: impact.peakWastageItems
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              item,
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatternsCard(List<WastagePattern> patterns) {
    final totalValue = patterns.fold<double>(
      0,
      (sum, pattern) => sum + pattern.totalValueLost,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.modeSurfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppIcon(
                  Icons.pie_chart,
                  size: 24,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wastage Patterns',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.modeTextPrimary,
                      ),
                    ),

                    Text(
                      'Breakdown by reason',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: context.modeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: patterns
                    .asMap()
                    .entries
                    .map(
                      (entry) => _buildPieChartSection(
                        entry.value,
                        entry.key,
                        totalValue,
                      ),
                    )
                    .toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...patterns.asMap().entries.map((entry) {
            final pattern = entry.value;
            final percentage = totalValue > 0
                ? (pattern.totalValueLost / totalValue) * 100
                : 0;
            final color = _getPatternColor(entry.key);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatReason(pattern.reason),
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.modeTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pattern.occurrences} occurrence${pattern.occurrences > 1 ? 's' : ''}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: context.modeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₦${NumberFormat('#,##0').format(pattern.totalValueLost)}',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 12,
                          color: context.modeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieChartSection(
    WastagePattern pattern,
    int index,
    double totalValue,
  ) {
    final percentage = totalValue > 0
        ? (pattern.totalValueLost / totalValue) * 100
        : 0;
    final color = _getPatternColor(index);

    return PieChartSectionData(
      value: pattern.totalValueLost,
      title: '${percentage.toStringAsFixed(0)}%',
      radius: 70,
      titleStyle: WorkSansAppTextStyles.medium.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      color: color,
    );
  }

  Color _getPatternColor(int index) {
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
    return colors[index % colors.length];
  }

  String _formatReason(String reason) {
    return reason
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildHighRiskItemsCard(List<HighRiskItem> items) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.modeError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppIcon(
                  Icons.warning_amber_rounded,
                  size: 24,
                  color: context.modeError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'High-Risk Items',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.modeTextPrimary,
                      ),
                    ),
                    Text(
                      'Most frequently wasted',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: context.modeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                Divider(height: 20, color: context.modeDivider),
            itemBuilder: (context, index) {
              final item = items[index];
              final riskLevel = _calculateRiskLevel(item);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: riskLevel.color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: riskLevel.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: riskLevel.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: riskLevel.color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemName,
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.modeTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: riskLevel.color.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      riskLevel.label,
                                      style: WorkSansAppTextStyles.medium
                                          .copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: riskLevel.color,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatReason(item.primaryReason),
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: 12,
                                          color: context.modeTextMuted,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₦${NumberFormat('#,##0').format(item.totalValueLost)}',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: riskLevel.color,
                              ),
                            ),
                            Text(
                              'Lost',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 11,
                                color: context.modeTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildItemStat(
                            'Frequency',
                            '${item.wasteFrequency}x',
                            Icons.repeat,
                          ),
                        ),
                        Expanded(
                          child: _buildItemStat(
                            'Avg Quantity',
                            '${item.avgQuantityPerIncident.toStringAsFixed(1)} ${item.unit}',
                            Icons.scale,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          AppIcon(icon, size: 16, color: context.modeTextSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 10,
                    color: context.modeTextMuted,
                  ),
                ),
                Text(
                  value,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({Color color, String label}) _calculateRiskLevel(HighRiskItem item) {
    if (item.totalValueLost > 15000 || item.wasteFrequency > 5) {
      return (color: const Color(0xFFDC2626), label: 'CRITICAL');
    } else if (item.totalValueLost > 10000 || item.wasteFrequency > 3) {
      return (color: const Color(0xFFF59E0B), label: 'HIGH');
    } else {
      return (color: const Color(0xFFEAB308), label: 'MODERATE');
    }
  }

  Widget _buildAnomaliesCard(List<WastageAnomaly> anomalies) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.modeWarning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppIcon(
                  Icons.error_outline,
                  size: 24,
                  color: context.modeWarning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anomalies Detected',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.modeTextPrimary,
                      ),
                    ),
                    Text(
                      'Items exceeding normal wastage',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: context.modeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: anomalies.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final anomaly = anomalies[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.modeWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.modeWarning.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            anomaly.itemName,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.modeTextPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: context.modeWarning.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${anomaly.deviationScore.toStringAsFixed(1)}σ',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.modeWarning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${anomaly.quantity} ${anomaly.unit} • ${_formatReason(anomaly.reason)}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        color: context.modeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy').format(anomaly.date),
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: context.modeTextMuted,
                          ),
                        ),
                        Text(
                          '₦${NumberFormat('#,##0').format(anomaly.valueLost)}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.modeWarning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.modeWarning.withValues(alpha: 0.12),
            context.modeWarning.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modeWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.modeWarning,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const AppIcon(
                  Icons.lightbulb,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Recommendations',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.modeTextPrimary,
                      ),
                    ),
                    Text(
                      'Action steps to reduce wastage',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: context.modeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommendations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final recommendation = recommendations[index]
                  .replaceAll('**', '')
                  .replaceAll('*', '');

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: context.modeWarning,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: context.modeTextPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedAtFooter(DateTime generatedAt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(Icons.schedule, size: 16, color: context.modeTextMuted),
          const SizedBox(width: 8),
          Text(
            'Generated on ${DateFormat('MMM d, yyyy • h:mm a').format(generatedAt)}',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: context.modeTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
