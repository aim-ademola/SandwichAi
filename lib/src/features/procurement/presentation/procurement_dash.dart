import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/globals/notifications/notification_bell.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/dashboard/bloc/dashboard_contract_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/dashboard/bloc/dashboard_contract_bloc/event.dart';
import 'package:sandwich_ai/src/features/dashboard/bloc/dashboard_contract_bloc/state.dart';
import 'package:sandwich_ai/src/features/dashboard/data/model/dashboard_contract_model.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_performance_model.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/supplier_stat_model.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/supplier_stat_repo.dart';

import 'package:sandwich_ai/src/features/procurement/presentation/procurement_drawer.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_performance_cubit/procurement_performance_cubit.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_performance_cubit/procurement_performance_state.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_stat_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_stat_bloc/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_stat_bloc/state.dart';

class ProcurementDashboardScreen extends StatefulWidget {
  const ProcurementDashboardScreen({super.key});

  @override
  State<ProcurementDashboardScreen> createState() =>
      _ProcurementDashboardScreenState();
}

class _ProcurementDashboardScreenState
    extends State<ProcurementDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _branchId = '';
  String? _dashboardSetupError;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool refresh = false}) async {
    final branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    final organizationId = await AuthCacheHelper.instance.getOrgId() ?? '';

    if (!mounted) return;

    setState(() {
      _branchId = branchId;
      _dashboardSetupError = organizationId.isEmpty
          ? 'Organization ID not found. Please login again.'
          : null;
    });

    if (organizationId.isEmpty) return;

    final request = DashboardFilterRequest(
      domain: DashboardDomain.procurement,
      organizationId: organizationId,
      branchId: branchId.isEmpty ? null : branchId,
    );

    context.read<DashboardContractBloc>().add(
      refresh
          ? RefreshDashboardContract(request: request)
          : LoadDashboardContract(request: request),
    );
    await context.read<ProcurementPerformanceCubit>().loadDashboardPerformance(
      branchId: branchId.isEmpty ? null : branchId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              SupplierStatsBloc(repository: SupplierStatsRepository())
                ..add(const LoadSupplierStats()),
        ),
      ],
      child: DefaultTextStyle.merge(
        style: WorkSansAppTextStyles.medium,
        child: Scaffold(
          drawer: ProcurementAppDrawer(),
          key: _scaffoldKey,
          backgroundColor: context.modeBackground,
          appBar: _buildAppBar(context),
          body: _buildBody(context),
        ),
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
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: Text(
        'Dashboard',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: context.modeTextPrimary,
        ),
      ),
      centerTitle: true,
      actions: const [NotificationBellAction()],
    );
  }

  Widget _buildBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _getHorizontalPadding(constraints.maxWidth);
        final maxContentWidth = _getMaxContentWidth(constraints.maxWidth);

        return RefreshIndicator(
          color: context.modePrimary,
          onRefresh: () async {
            context.read<SupplierStatsBloc>().add(const RefreshSupplierStats());
            await _loadDashboardData(refresh: true);
          },
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildStatusCards(constraints.maxWidth),
                    const SizedBox(height: 32),
                    _buildDashboardFeedSection(constraints.maxWidth),
                    const SizedBox(height: 32),
                    _buildPerformanceSection(constraints.maxWidth),
                    const SizedBox(height: 32),
                    _buildSupplierRankingsSection(constraints.maxWidth),
                    const SizedBox(height: 32),
                    _buildSuppliersSection(constraints.maxWidth),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCards(double width) {
    final cardHeight = _getStatusCardHeight(width);
    final fontSize = _getStatusCardFontSize(width);
    final numberFontSize = _getStatusCardNumberSize(width);

    if (_dashboardSetupError != null) {
      return _buildErrorState(
        _dashboardSetupError!,
        width,
        context,
        title: 'Dashboard unavailable',
        onRetry: () => _loadDashboardData(refresh: true),
      );
    }

    return BlocBuilder<DashboardContractBloc, DashboardContractState>(
      builder: (context, state) {
        final isLoading =
            state is DashboardContractLoading ||
            state is DashboardContractRefreshing;
        DashboardResponse? data;
        if (state is DashboardContractLoaded) {
          data = state.data;
        } else if (state is DashboardContractRefreshing) {
          data = state.currentData;
        }

        if (state is DashboardContractError) {
          return _buildErrorState(
            state.message,
            width,
            context,
            title: 'Failed to load dashboard overview',
            onRetry: () => _loadDashboardData(refresh: true),
          );
        }

        final cards = _overviewCards(data);

        return Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                height: cardHeight,
                number: cards[0].value,
                label: cards[0].label,
                color: context.modePrimary.withValues(alpha: 0.12),
                numberColor: context.modePrimary,
                fontSize: fontSize,
                numberFontSize: numberFontSize,
                isLoading: isLoading,
              ),
            ),
            SizedBox(width: _getCardSpacing(width)),
            Expanded(
              child: _buildStatusCard(
                height: cardHeight,
                number: cards[1].value,
                label: cards[1].label,
                color: context.modePrimary.withValues(alpha: 0.12),
                numberColor: context.modePrimary,
                fontSize: fontSize,
                numberFontSize: numberFontSize,
                isLoading: isLoading,
              ),
            ),
            SizedBox(width: _getCardSpacing(width)),
            Expanded(
              child: _buildStatusCard(
                height: cardHeight,
                number: cards[2].value,
                label: cards[2].label,
                color: context.modePrimary.withValues(alpha: 0.12),
                numberColor: context.modePrimary,
                fontSize: fontSize,
                numberFontSize: numberFontSize,
                isLoading: isLoading,
              ),
            ),
          ],
        );
      },
    );
  }

  List<_OverviewCardData> _overviewCards(DashboardResponse? data) {
    final procurementOverview = _asMap(data?.rawData['overview']);
    if (data?.domain == DashboardDomain.procurement &&
        procurementOverview.isNotEmpty) {
      final totalSpend = _asMap(procurementOverview['totalSpend']);
      final purchaseOrders = _asMap(procurementOverview['purchaseOrders']);
      final deliveriesCompleted = _asMap(
        procurementOverview['deliveriesCompleted'],
      );

      return [
        _OverviewCardData(
          label: 'Total Spend',
          value: _formatFullMoney(_asDouble(totalSpend['value'])),
        ),
        _OverviewCardData(
          label: 'POs',
          value: _asInt(purchaseOrders['total']).toString(),
        ),
        _OverviewCardData(
          label: 'Completed',
          value: _asInt(deliveriesCompleted['total']).toString(),
        ),
      ];
    }

    final metrics = data?.metrics ?? const <DashboardMetric>[];
    final pending = _metricByTerms(metrics, const ['pending']);
    final approved = _metricByTerms(metrics, const ['approved']);
    final received = _metricByTerms(metrics, const ['received', 'completed']);

    if (pending != null || approved != null || received != null) {
      return [
        _OverviewCardData.fromMetric(pending, fallbackLabel: 'Pending'),
        _OverviewCardData.fromMetric(approved, fallbackLabel: 'Approved'),
        _OverviewCardData.fromMetric(received, fallbackLabel: 'Received'),
      ];
    }

    if (metrics.length >= 3) {
      return metrics.take(3).map(_OverviewCardData.fromMetric).toList();
    }

    return const [
      _OverviewCardData(label: 'Pending', value: '0'),
      _OverviewCardData(label: 'Approved', value: '0'),
      _OverviewCardData(label: 'Received', value: '0'),
    ];
  }

  DashboardMetric? _metricByTerms(
    List<DashboardMetric> metrics,
    List<String> terms,
  ) {
    for (final metric in metrics) {
      final searchable = '${metric.key} ${metric.label}'.toLowerCase();
      if (terms.any(searchable.contains)) return metric;
    }
    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Widget _buildDashboardFeedSection(double width) {
    final titleFontSize = _getSectionTitleSize(width);

    return BlocBuilder<DashboardContractBloc, DashboardContractState>(
      builder: (context, state) {
        DashboardResponse? data;
        final isLoading =
            state is DashboardContractLoading ||
            state is DashboardContractRefreshing;
        if (state is DashboardContractLoaded) {
          data = state.data;
        } else if (state is DashboardContractRefreshing) {
          data = state.currentData;
        }

        final requests = _asMapList(data?.rawData['requestsReceived']);
        final orders = _asMapList(data?.rawData['purchaseOrders']);
        final goodsLogs = _asMapList(data?.rawData['goodsReceivedLogs']);
        final supplierSpend = _asMapList(
          data?.rawData['supplierSpendAnalysis'],
        );
        final aiInsight = data?.rawData['aiInsight']?.toString() ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Dashboard Feed',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: context.modeTextPrimary,
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.modePrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDashboardRecordCard(
              width: width,
              child: _buildDashboardRecordGroup(
                title: 'Requests Received',
                emptyText: 'No requests received yet.',
                records: requests,
                icon: Icons.assignment_outlined,
                titleKey: 'requestId',
                subtitleKeys: const ['item', 'requestedBy'],
                metaKeys: const ['qtyNeeded', 'status'],
                width: width,
              ),
            ),
            const SizedBox(height: 12),
            _buildDashboardRecordCard(
              width: width,
              child: _buildDashboardRecordGroup(
                title: 'Purchase Orders',
                emptyText: 'No purchase orders in this period.',
                records: orders,
                icon: Icons.receipt_long_outlined,
                titleKey: 'orderNumber',
                fallbackTitleKey: 'purchaseOrderId',
                subtitleKeys: const ['supplierName', 'supplier'],
                metaKeys: const ['totalAmount', 'status'],
                width: width,
              ),
            ),
            const SizedBox(height: 12),
            _buildDashboardRecordCard(
              width: width,
              child: _buildDashboardRecordGroup(
                title: 'Goods Received',
                emptyText: 'No goods received logs yet.',
                records: goodsLogs,
                icon: Icons.inventory_2_outlined,
                titleKey: 'grnId',
                fallbackTitleKey: 'goodsReceivedId',
                subtitleKeys: const ['itemName', 'supplier'],
                metaKeys: const ['receivedQty', 'qcStatus'],
                width: width,
              ),
            ),
            const SizedBox(height: 12),
            _buildDashboardRecordCard(
              width: width,
              child: _buildDashboardRecordGroup(
                title: 'Supplier Spend',
                emptyText: 'No supplier spend analysis yet.',
                records: supplierSpend,
                icon: Icons.payments_outlined,
                titleKey: 'supplier',
                subtitleKeys: const ['category'],
                metaKeys: const ['totalSpend', 'orderCount'],
                width: width,
              ),
            ),
            if (aiInsight.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDashboardRecordCard(
                width: width,
                child: _buildAiInsightCard(aiInsight, width),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDashboardRecordCard({
    required double width,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_getContainerPadding(width)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        border: Border.all(color: context.modeBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildDashboardRecordGroup({
    required String title,
    required String emptyText,
    required List<Map<String, dynamic>> records,
    required IconData icon,
    required String titleKey,
    String? fallbackTitleKey,
    required List<String> subtitleKeys,
    required List<String> metaKeys,
    required double width,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getSupplierLabelSize(width) + 1,
            fontWeight: FontWeight.w700,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (records.isEmpty)
          Text(
            emptyText,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getSupplierLabelSize(width),
              color: context.modeTextSecondary,
            ),
          )
        else
          ...records
              .take(3)
              .map(
                (record) => _buildDashboardRecordRow(
                  record: record,
                  icon: icon,
                  titleKey: titleKey,
                  fallbackTitleKey: fallbackTitleKey,
                  subtitleKeys: subtitleKeys,
                  metaKeys: metaKeys,
                  width: width,
                ),
              ),
      ],
    );
  }

  Widget _buildDashboardRecordRow({
    required Map<String, dynamic> record,
    required IconData icon,
    required String titleKey,
    String? fallbackTitleKey,
    required List<String> subtitleKeys,
    required List<String> metaKeys,
    required double width,
  }) {
    final titleKeys = <String>[titleKey];
    if (fallbackTitleKey != null) titleKeys.add(fallbackTitleKey);
    final title = _firstText(record, titleKeys);
    final subtitle = _firstText(record, subtitleKeys);
    final meta = metaKeys
        .map((key) => record[key]?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .join(' | ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.modePrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: AppIcon(icon, size: 18, color: context.modePrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Untitled record' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getSupplierLabelSize(width),
                    fontWeight: FontWeight.w700,
                    color: context.modeTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    subtitle,
                    meta,
                  ].where((value) => value.isNotEmpty).join(' | '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getSupplierLabelSize(width) - 1,
                    color: context.modeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _firstText(Map<String, dynamic> record, List<String> keys) {
    for (final key in keys) {
      final value = record[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  Widget _buildAiInsightCard(String insight, double width) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.modeWarning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeWarning.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            Icons.lightbulb_outline,
            color: context.modeWarning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              insight,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getSupplierLabelSize(width),
                color: context.modeTextPrimary,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required double height,
    required String number,
    required String label,
    required Color color,
    required Color numberColor,
    required double fontSize,
    required double numberFontSize,
    bool isLoading = false,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(numberColor),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  number,
                  maxLines: 1,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: numberFontSize,
                    fontWeight: FontWeight.w700,
                    color: numberColor,
                    height: 1,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: fontSize - 1,
              fontWeight: FontWeight.w500,
              color: context.modeTextSecondary,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildBudgetSection(double width) {
    final titleFontSize = _getSectionTitleSize(width);
    final budgetFontSize = _getBudgetFontSize(width);

    return Container(
      padding: EdgeInsets.all(_getContainerPadding(width)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        border: Border.all(color: context.modeBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '₦350,000 / ₦500,000',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: budgetFontSize,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.7,
              minHeight: _getProgressBarHeight(width),
              backgroundColor: context.modePrimary.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(context.modePrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliersSection(double width) {
    final titleFontSize = _getSectionTitleSize(width);
    final supplierNumberSize = _getSupplierNumberSize(width);
    final supplierLabelSize = _getSupplierLabelSize(width);
    final cardHeight = _getSupplierCardHeight(width);

    return BlocBuilder<SupplierStatsBloc, SupplierStatsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suppliers',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextPrimary,
                  ),
                ),
                if (state is SupplierStatsLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.modePrimary,
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _openSuppliersTab,
                    style: TextButton.styleFrom(
                      foregroundColor: context.modePrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View all suppliers',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: width < 360 ? 11 : 12,
                        fontWeight: FontWeight.w700,
                        color: context.modePrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (state is SupplierStatsError)
              _buildErrorState(state.error, width, context)
            else if (state is SupplierStatsLoaded) ...[
              _buildSupplierChart(state.stats),
              const SizedBox(height: 16),
              _buildSupplierStatsCards(
                state.stats,
                cardHeight,
                width,
                supplierNumberSize,
                supplierLabelSize,
              ),
            ] else ...[
              _buildSupplierChart(SupplierStats.empty),
              const SizedBox(height: 16),
              _buildSupplierStatsCards(
                SupplierStats.empty,
                cardHeight,
                width,
                supplierNumberSize,
                supplierLabelSize,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPerformanceSection(double width) {
    final titleFontSize = _getSectionTitleSize(width);
    final cardHeight = _getSupplierCardHeight(width);
    final numberSize = _getSupplierNumberSize(width);
    final labelSize = _getSupplierLabelSize(width);

    return BlocBuilder<
      ProcurementPerformanceCubit,
      ProcurementPerformanceState
    >(
      builder: (context, state) {
        final isLoading =
            state.performanceStatus == ProcurementPerformanceStatus.loading;
        final performance = state.performance;

        if (state.performanceStatus == ProcurementPerformanceStatus.error) {
          return _buildErrorState(
            state.performanceError ?? 'Failed to load procurement performance.',
            width,
            context,
            title: 'Failed to load procurement performance',
            onRetry: () => context
                .read<ProcurementPerformanceCubit>()
                .loadDashboardPerformance(
                  branchId: _branchId.isEmpty ? null : _branchId,
                ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Procurement Performance',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSupplierStatCard(
                    height: cardHeight,
                    value: isLoading
                        ? '-'
                        : _formatMoney(performance?.totalSpend ?? 0),
                    label: 'Total Spend',
                    width: width,
                    numberSize: numberSize,
                    labelSize: labelSize,
                    valueColor: context.modePrimary,
                  ),
                ),
                SizedBox(width: _getCardSpacing(width)),
                Expanded(
                  child: _buildSupplierStatCard(
                    height: cardHeight,
                    value: isLoading
                        ? '-'
                        : '${(performance?.averageDeliveryDays ?? 0).toStringAsFixed(1)}d',
                    label: 'Avg Delivery',
                    width: width,
                    numberSize: numberSize,
                    labelSize: labelSize,
                  ),
                ),
              ],
            ),
            SizedBox(height: _getCardSpacing(width)),
            Row(
              children: [
                Expanded(
                  child: _buildSupplierStatCard(
                    height: cardHeight,
                    value: isLoading
                        ? '-'
                        : _formatPercent(performance?.onTimeDeliveryRate ?? 0),
                    label: 'On-Time Rate',
                    width: width,
                    numberSize: numberSize,
                    labelSize: labelSize,
                    valueColor: context.modeSuccess,
                  ),
                ),
                SizedBox(width: _getCardSpacing(width)),
                Expanded(
                  child: _buildSupplierStatCard(
                    height: cardHeight,
                    value: isLoading
                        ? '-'
                        : _formatPercent(performance?.qualityPassRate ?? 0),
                    label: 'QC Pass Rate',
                    width: width,
                    numberSize: numberSize,
                    labelSize: labelSize,
                    valueColor: context.modeSuccess,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSupplierRankingsSection(double width) {
    final titleFontSize = _getSectionTitleSize(width);

    return BlocBuilder<
      ProcurementPerformanceCubit,
      ProcurementPerformanceState
    >(
      builder: (context, state) {
        final rankings = state.rankings?.rankings ?? const [];

        return Container(
          padding: EdgeInsets.all(_getContainerPadding(width)),
          decoration: BoxDecoration(
            color: context.modeSurface,
            border: Border.all(color: context.modeBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Supplier Rankings',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: context.modeTextPrimary,
                      ),
                    ),
                  ),
                  if (state.rankingsStatus ==
                      ProcurementPerformanceStatus.loading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.modePrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.rankingsStatus == ProcurementPerformanceStatus.error)
                Text(
                  state.rankingsError ?? 'Failed to load supplier rankings.',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: context.modeError,
                  ),
                )
              else if (rankings.isEmpty)
                Text(
                  'No supplier rankings available yet.',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: context.modeTextSecondary,
                  ),
                )
              else
                ...rankings
                    .take(5)
                    .map((ranking) => _buildRankingRow(ranking, width)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRankingRow(ProcurementPerformanceRanking ranking, double width) {
    final rank = ranking.rank > 0 ? ranking.rank : 0;
    final score = ranking.score > 0 ? ranking.score.toStringAsFixed(1) : '-';

    return InkWell(
      onTap: _openSuppliersTab,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.modePrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rank == 0 ? '-' : '#$rank',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.modePrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ranking.supplierName.isEmpty
                        ? 'Unknown supplier'
                        : ranking.supplierName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getSupplierLabelSize(width) + 1,
                      fontWeight: FontWeight.w600,
                      color: context.modeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'On-time ${_formatPercent(ranking.onTimeDeliveryRate)} | QC ${_formatPercent(ranking.qualityPassRate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getSupplierLabelSize(width) - 1,
                      color: context.modeTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              score,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getSupplierLabelSize(width) + 1,
                fontWeight: FontWeight.w700,
                color: context.modeTextPrimary,
              ),
            ),
            AppIcon(
              Icons.chevron_right,
              color: context.modeTextMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _openSuppliersTab() {
    context.go('/Procurement-nav?tab=suppliers');
  }

  Widget _buildErrorState(
    String error,
    double width,
    BuildContext context, {
    String title = 'Failed to load supplier stats',
    VoidCallback? onRetry,
  }) {
    return Container(
      padding: EdgeInsets.all(_getContainerPadding(width)),
      decoration: BoxDecoration(
        color: context.modeError.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.modeError.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          AppIcon(Icons.error_outline, color: context.modeError, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.modeError,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    color: context.modeError,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: AppIcon(Icons.refresh, color: context.modeError),
            onPressed:
                onRetry ??
                () {
                  context.read<SupplierStatsBloc>().add(
                    const LoadSupplierStats(),
                  );
                },
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierStatsCards(
    SupplierStats stats,
    double cardHeight,
    double width,
    double supplierNumberSize,
    double supplierLabelSize,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSupplierStatCard(
                height: cardHeight,
                value: '${stats.onTimeDeliveryPercentage.toStringAsFixed(0)}%',
                label: 'On-Time Delivery',
                width: width,
                numberSize: supplierNumberSize,
                labelSize: supplierLabelSize,
                showPercentage: false,
              ),
            ),
            SizedBox(width: _getCardSpacing(width)),
            Expanded(
              child: _buildSupplierStatCard(
                height: cardHeight,
                value: stats.averageRating.toStringAsFixed(1),
                label: 'Average Rating',
                width: width,
                numberSize: supplierNumberSize,
                labelSize: supplierLabelSize,
              ),
            ),
          ],
        ),
        SizedBox(height: _getCardSpacing(width)),
        Row(
          children: [
            Expanded(
              child: _buildSupplierStatCard(
                height: cardHeight,
                value: stats.totalSuppliers.toString(),
                label: 'Total Suppliers',
                width: width,
                numberSize: supplierNumberSize,
                labelSize: supplierLabelSize,
              ),
            ),
            SizedBox(width: _getCardSpacing(width)),
            Expanded(
              child: _buildSupplierStatCard(
                height: cardHeight,
                value: stats.activeSuppliers.toString(),
                label: 'Active Suppliers',
                width: width,
                numberSize: supplierNumberSize,
                labelSize: supplierLabelSize,
              ),
            ),
          ],
        ),
        SizedBox(height: _getCardSpacing(width)),
        Row(
          children: [
            Expanded(
              child: _buildSupplierStatCard(
                height: cardHeight,
                value: stats.pendingSuppliers.toString(),
                label: 'Pending Suppliers',
                width: width,
                numberSize: supplierNumberSize,
                labelSize: supplierLabelSize,
                valueColor: context.modeWarning,
              ),
            ),
            SizedBox(width: _getCardSpacing(width)),
            Expanded(
              child: _buildSupplierStatCard(
                height: cardHeight,
                value: stats.verifiedSuppliers.toString(),
                label: 'Verified Suppliers',
                width: width,
                numberSize: supplierNumberSize,
                labelSize: supplierLabelSize,
                valueColor: context.modeSuccess,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupplierStatCard({
    required double height,
    required String value,
    required String label,
    required double width,
    required double numberSize,
    required double labelSize,
    Color? valueColor,
    bool showPercentage = false,
  }) {
    return Container(
      height: height,
      padding: EdgeInsets.all(_getContainerPadding(width)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: numberSize,
              fontWeight: FontWeight.w700,
              color: valueColor ?? context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: labelSize,
                fontWeight: FontWeight.w500,
                color: context.modeTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildRecentActivity(double width) {
    final titleFontSize = _getSectionTitleSize(width);
    final activityTitleSize = _getActivityTitleSize(width);
    final activitySubtitleSize = _getActivitySubtitleSize(width);
    final iconSize = _getActivityIconSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildActivityItem(
          icon: Icons.access_time,
          iconColor: context.modeWarning,
          iconBgColor: context.modeWarning.withValues(alpha: 0.14),
          title: 'Pending Approval',
          subtitle: 'Order #12345 from Fresh Veggies Inc.',
          width: width,
          activityTitleSize: activityTitleSize,
          activitySubtitleSize: activitySubtitleSize,
          iconSize: iconSize,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          icon: Icons.local_shipping_outlined,
          iconColor: context.modeError,
          iconBgColor: context.modeError.withValues(alpha: 0.14),
          title: 'Delayed Delivery',
          subtitle: 'Order #67890 is running late',
          width: width,
          activityTitleSize: activityTitleSize,
          activitySubtitleSize: activitySubtitleSize,
          iconSize: iconSize,
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required double width,
    required double activityTitleSize,
    required double activitySubtitleSize,
    required double iconSize,
  }) {
    return Container(
      padding: EdgeInsets.all(_getContainerPadding(width)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        border: Border.all(color: context.modeBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(100),
            ),
            child: AppIcon(icon, color: iconColor, size: iconSize * 0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: activityTitleSize,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: activitySubtitleSize,
                    fontWeight: FontWeight.w400,
                    color: context.modeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  double _getStatusCardHeight(double width) {
    if (width < 360) return 80;
    if (width < 600) return 90;
    return 100;
  }

  double _getStatusCardFontSize(double width) {
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  double _getStatusCardNumberSize(double width) {
    if (width < 360) return 24;
    if (width < 600) return 26;
    return 36;
  }

  double _getCardSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 16;
    return 20;
  }

  double _getContainerPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getSectionTitleSize(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getBudgetFontSize(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getProgressBarHeight(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getSupplierCardHeight(double width) {
    if (width < 360) return 112;
    if (width < 600) return 122;
    return 132;
  }

  double _getSupplierNumberSize(double width) {
    if (width < 360) return 28;
    if (width < 600) return 32;
    return 36;
  }

  double _getSupplierLabelSize(double width) {
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  double _getActivityIconSize(double width) {
    if (width < 360) return 40;
    if (width < 600) return 48;
    return 56;
  }

  double _getActivityTitleSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }

  double _getActivitySubtitleSize(double width) {
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  Widget _buildSupplierChart(SupplierStats stats) {
    final total =
        stats.activeSuppliers +
        stats.pendingSuppliers +
        stats.verifiedSuppliers;
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
            'Supplier Status Breakdown',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
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
                          value: stats.activeSuppliers.toDouble(),
                          title:
                              '${((stats.activeSuppliers / total) * 100).toStringAsFixed(0)}%',
                          radius: 25,
                          titleStyle: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.modeTextInverse,
                          ),
                        ),
                        PieChartSectionData(
                          color: context.modeWarning,
                          value: stats.pendingSuppliers.toDouble(),
                          title:
                              '${((stats.pendingSuppliers / total) * 100).toStringAsFixed(0)}%',
                          radius: 25,
                          titleStyle: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.modeTextInverse,
                          ),
                        ),
                        PieChartSectionData(
                          color: context.modeSuccess,
                          value: stats.verifiedSuppliers.toDouble(),
                          title:
                              '${((stats.verifiedSuppliers / total) * 100).toStringAsFixed(0)}%',
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
                      label: 'Active (${stats.activeSuppliers})',
                    ),
                    const SizedBox(height: 8),
                    _chartIndicator(
                      color: context.modeWarning,
                      label: 'Pending (${stats.pendingSuppliers})',
                    ),
                    const SizedBox(height: 8),
                    _chartIndicator(
                      color: context.modeSuccess,
                      label: 'Verified (${stats.verifiedSuppliers})',
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

  String _formatMoney(double value) {
    if (value >= 1000000) return 'N${(value / 1000000).toStringAsFixed(1)}m';
    if (value >= 1000) return 'N${(value / 1000).toStringAsFixed(1)}k';
    return 'N${value.toStringAsFixed(0)}';
  }

  String _formatFullMoney(double value) {
    final amount = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < amount.length; i++) {
      final remaining = amount.length - i;
      buffer.write(amount[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return 'N$buffer';
  }

  String _formatPercent(double value) {
    final normalized = value > 0 && value <= 1 ? value * 100 : value;
    return '${normalized.toStringAsFixed(0)}%';
  }
}

class _OverviewCardData {
  final String label;
  final String value;

  const _OverviewCardData({required this.label, required this.value});

  factory _OverviewCardData.fromMetric(
    DashboardMetric? metric, {
    String? fallbackLabel,
  }) {
    if (metric == null) {
      return _OverviewCardData(label: fallbackLabel ?? 'Metric', value: '0');
    }

    final value = metric.unit == null || metric.unit!.isEmpty
        ? metric.value.toString()
        : '${metric.value}${metric.unit}';

    return _OverviewCardData(
      label: metric.label.isEmpty
          ? (fallbackLabel ?? metric.key)
          : metric.label,
      value: value,
    );
  }
}
