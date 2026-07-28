import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_control_reports_cubit/stock_control_reports_cubit.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_control_reports_cubit/stock_control_reports_state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/reorder_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/stock_card_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/stock_card_repo.dart';

class StockReportsScreen extends StatefulWidget {
  const StockReportsScreen({super.key});

  @override
  State<StockReportsScreen> createState() => _StockReportsScreenState();
}

class _StockReportsScreenState extends State<StockReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<_ExpiryTrackingScreenState> _expiryKey = GlobalKey();
  final GlobalKey<_LockedStockScreenState> _lockedKey = GlobalKey();
  final GlobalKey<_NegativeStockReportScreenState> _negativeKey = GlobalKey();
  // final GlobalKey<_ReorderReportScreenState> _reorderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrentReport() async {
    switch (_tabController.index) {
      case 0:
        await _expiryKey.currentState?._load();
      case 1:
        await _lockedKey.currentState?._load();
      case 2:
        await _negativeKey.currentState?._load();
      // case 3:
      //   await _reorderKey.currentState?._load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
        appBar: AppBar(
          backgroundColor: context.modeSurface,
          elevation: 0,
          leading: IconButton(
            icon: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Reports',
            style: WorkSansAppTextStyles.medium.copyWith(
              color: context.modeTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: AppIcon(Icons.refresh, color: context.modePrimary),
              onPressed: _refreshCurrentReport,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: context.modeSurface,
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                labelColor: context.modePrimary,
                unselectedLabelColor: context.modeTextSecondary,
                indicatorColor: context.modePrimary,
                indicatorWeight: 3,
                labelStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Expiry'),
                  Tab(text: 'Locked Stock'),
                  Tab(text: 'Negative Stock'),
                  // Tab(text: 'Reorder'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            ExpiryTrackingScreen(key: _expiryKey, showAppBar: false),
            LockedStockScreen(key: _lockedKey, showAppBar: false),
            NegativeStockReportScreen(key: _negativeKey, showAppBar: false),
            // ReorderReportScreen(key: _reorderKey, showAppBar: false),
          ],
        ),
      ),
    );
  }
}

class ExpiryTrackingScreen extends StatefulWidget {
  final bool showAppBar;

  const ExpiryTrackingScreen({super.key, this.showAppBar = true});

  @override
  State<ExpiryTrackingScreen> createState() => _ExpiryTrackingScreenState();
}

class _ExpiryTrackingScreenState extends State<ExpiryTrackingScreen> {
  static const int _defaultWithinDays = 100;

  String _branchId = '';
  DateTime? _expiryUntilDate;
  bool _includeExpired = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    if (!mounted) return;
    context.read<StockControlReportsCubit>().loadExpiryTracking(
      branchId: _branchId,
      withinDays: _selectedWithinDays,
      includeExpired: _includeExpired,
    );
  }

  int? get _selectedWithinDays {
    final date = _expiryUntilDate;
    if (date == null) return _defaultWithinDays;
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = DateUtils.dateOnly(date);
    return selected.difference(today).inDays.clamp(0, 3650);
  }

  bool get _hasFilters => _expiryUntilDate != null || _includeExpired;

  Future<void> _pickExpiryUntilDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expiryUntilDate ?? now.add(const Duration(days: _defaultWithinDays)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() => _expiryUntilDate = picked);
    await _load();
  }

  Future<void> _clearFilters() async {
    setState(() {
      _expiryUntilDate = null;
      _includeExpired = false;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return _ReportScaffold(
      title: 'Expiry Tracking',
      onRefresh: _load,
      showAppBar: widget.showAppBar,
      child: BlocBuilder<StockControlReportsCubit, StockControlReportsState>(
        builder: (context, state) {
          return _ReportStateBody(
            status: state.expiryStatus,
            error: state.expiryError,
            emptyMessage: 'No expiring products found.',
            onRetry: _load,
            child: () {
              final report = state.expiryReport;
              final summary = state.expirySummary;
              if (report == null) return const SizedBox.shrink();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ExpiryFilterBar(
                    expiryUntilDate: _expiryUntilDate,
                    includeExpired: _includeExpired,
                    hasFilters: _hasFilters,
                    onPickDate: _pickExpiryUntilDate,
                    onIncludeExpiredChanged: (value) async {
                      setState(() => _includeExpired = value);
                      await _load();
                    },
                    onClear: _clearFilters,
                  ),
                  const SizedBox(height: 16),
                  if (summary != null) _ExpirySummaryGrid(summary: summary),
                  if (summary != null) const SizedBox(height: 16),
                  ...report.items.indexed.expand((entry) sync* {
                    final (index, item) = entry;
                    if (index > 0) yield const SizedBox(height: 12);
                    yield _ExpiryItemCard(
                      item: item,
                      branchId: _branchId,
                      onBatchUpdated: _load,
                    );
                  }),
                ],
              );
            }(),
          );
        },
      ),
    );
  }
}

class LockedStockScreen extends StatefulWidget {
  final bool showAppBar;

  const LockedStockScreen({super.key, this.showAppBar = true});

  @override
  State<LockedStockScreen> createState() => _LockedStockScreenState();
}

class _LockedStockScreenState extends State<LockedStockScreen> {
  String _branchId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    if (!mounted) return;
    context.read<StockControlReportsCubit>().loadLockedStock(
      branchId: _branchId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ReportScaffold(
      title: 'Locked Stock',
      onRefresh: _load,
      showAppBar: widget.showAppBar,
      child: BlocBuilder<StockControlReportsCubit, StockControlReportsState>(
        builder: (context, state) {
          return _ReportStateBody(
            status: state.lockedStatus,
            error: state.lockedError,
            emptyMessage: 'No locked stock found.',
            onRetry: _load,
            child: _RawStockList(items: state.lockedStock?.items ?? const []),
          );
        },
      ),
    );
  }
}

class NegativeStockReportScreen extends StatefulWidget {
  final bool showAppBar;

  const NegativeStockReportScreen({super.key, this.showAppBar = true});

  @override
  State<NegativeStockReportScreen> createState() =>
      _NegativeStockReportScreenState();
}

class _NegativeStockReportScreenState extends State<NegativeStockReportScreen> {
  String _branchId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    if (!mounted) return;
    context.read<StockControlReportsCubit>().loadNegativeStockReport(
      branchId: _branchId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ReportScaffold(
      title: 'Negative Stock Report',
      onRefresh: _load,
      showAppBar: widget.showAppBar,
      child: BlocBuilder<StockControlReportsCubit, StockControlReportsState>(
        builder: (context, state) {
          return _ReportStateBody(
            status: state.negativeStatus,
            error: state.negativeError,
            emptyMessage: 'No negative stock found.',
            onRetry: _load,
            child: _RawStockList(
              items: state.negativeStockReport?.items ?? const [],
              highlightNegative: true,
            ),
          );
        },
      ),
    );
  }
}

class _ExpiryFilterBar extends StatelessWidget {
  final DateTime? expiryUntilDate;
  final bool includeExpired;
  final bool hasFilters;
  final VoidCallback onPickDate;
  final ValueChanged<bool> onIncludeExpiredChanged;
  final VoidCallback onClear;

  const _ExpiryFilterBar({
    required this.expiryUntilDate,
    required this.includeExpired,
    required this.hasFilters,
    required this.onPickDate,
    required this.onIncludeExpiredChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _FilterChipButton(
          icon: Icons.calendar_today_outlined,
          label: expiryUntilDate == null
              ? 'Next 100 days'
              : 'Until ${_formatShortDate(expiryUntilDate!)}',
          isActive: expiryUntilDate != null,
          onTap: onPickDate,
        ),
        FilterChip(
          avatar: AppIcon(
            Icons.history_toggle_off_outlined,
            size: 18,
            color: includeExpired
                ? context.modeTextInverse
                : context.modeTextSecondary,
          ),
          label: Text(
            'Include expired',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              color: includeExpired
                  ? context.modeTextInverse
                  : context.modeTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          selected: includeExpired,
          showCheckmark: false,
          selectedColor: context.modePrimary,
          backgroundColor: context.modeSurface,
          side: BorderSide(
            color: includeExpired ? context.modePrimary : context.modeBorder,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onSelected: onIncludeExpiredChanged,
        ),
        if (hasFilters)
          TextButton.icon(
            onPressed: onClear,
            icon: const AppIcon(Icons.clear, size: 18),
            label: Text(
              'Clear',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  static String _formatShortDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _FilterChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? context.modePrimary : context.modeSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? context.modePrimary : context.modeBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon,
              size: 18,
              color: isActive
                  ? context.modeTextInverse
                  : context.modeTextSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: isActive
                    ? context.modeTextInverse
                    : context.modeTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReorderReportScreen extends StatefulWidget {
  final bool showAppBar;

  const ReorderReportScreen({super.key, this.showAppBar = true});

  @override
  State<ReorderReportScreen> createState() => _ReorderReportScreenState();
}

class _ReorderReportScreenState extends State<ReorderReportScreen> {
  String _branchId = '';
  final Set<String> _acknowledgingIds = {};
  final Set<String> _acknowledgedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    if (!mounted) return;
    context.read<StockControlReportsCubit>().loadReorderReport(_branchId);
  }

  Future<void> _acknowledge(ReorderSuggestion item) async {
    if (_acknowledgingIds.contains(item.branchStockId)) return;
    // Comment flow disabled for now.
    // final comment = await _showReorderCommentDialog(item);
    // if (comment == null || !mounted) return;

    setState(() {
      _acknowledgingIds.add(item.branchStockId);
    });

    final ok = await context
        .read<StockControlReportsCubit>()
        .acknowledgeReorder(item.branchStockId);
    if (!mounted) return;
    setState(() {
      _acknowledgingIds.remove(item.branchStockId);
      if (ok) _acknowledgedIds.add(item.branchStockId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Reorder acknowledged.' : 'Failed to acknowledge.'),
        backgroundColor: ok ? kGreen : const Color(0xFFE53935),
      ),
    );
  }

  // Future<String?> _showReorderCommentDialog(ReorderSuggestion item) async {
  //   final controller = TextEditingController();
  //   String? errorText;
  //
  //   final result = await showDialog<String>(
  //     context: context,
  //     builder: (dialogContext) {
  //       return StatefulBuilder(
  //         builder: (context, setDialogState) {
  //           return AlertDialog(
  //             backgroundColor: context.modeSurface,
  //             title: Text(
  //               'Comment reorder',
  //               style: WorkSansAppTextStyles.medium.copyWith(
  //                 color: context.modeTextPrimary,
  //                 fontSize: 17,
  //                 fontWeight: FontWeight.w700,
  //               ),
  //             ),
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   item.itemName.isEmpty ? 'Stock item' : item.itemName,
  //                   style: WorkSansAppTextStyles.medium.copyWith(
  //                     color: context.modeTextSecondary,
  //                     fontSize: 13,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 12),
  //                 TextField(
  //                   controller: controller,
  //                   minLines: 3,
  //                   maxLines: 5,
  //                   textInputAction: TextInputAction.newline,
  //                   style: WorkSansAppTextStyles.medium.copyWith(
  //                     color: context.modeTextPrimary,
  //                     fontSize: 14,
  //                   ),
  //                   decoration: InputDecoration(
  //                     hintText: 'Add reorder comment',
  //                     errorText: errorText,
  //                     filled: true,
  //                     fillColor: context.modeBackground,
  //                     border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(8),
  //                       borderSide: BorderSide(color: context.modeBorder),
  //                     ),
  //                     enabledBorder: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(8),
  //                       borderSide: BorderSide(color: context.modeBorder),
  //                     ),
  //                     focusedBorder: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(8),
  //                       borderSide: BorderSide(color: context.modePrimary),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.of(dialogContext).pop(),
  //                 child: Text(
  //                   'Cancel',
  //                   style: WorkSansAppTextStyles.medium.copyWith(
  //                     color: context.modeTextSecondary,
  //                     fontWeight: FontWeight.w700,
  //                   ),
  //                 ),
  //               ),
  //               ElevatedButton(
  //                 onPressed: () {
  //                   final comment = controller.text.trim();
  //                   if (comment.isEmpty) {
  //                     setDialogState(() {
  //                       errorText = 'Enter a comment before acknowledging.';
  //                     });
  //                     return;
  //                   }
  //                   Navigator.of(dialogContext).pop(comment);
  //                 },
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: context.modePrimary,
  //                   foregroundColor: context.modeTextInverse,
  //                   elevation: 0,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                 ),
  //                 child: Text(
  //                   'Submit',
  //                   style: WorkSansAppTextStyles.medium.copyWith(
  //                     color: context.modeTextInverse,
  //                     fontWeight: FontWeight.w700,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  //
  //   controller.dispose();
  //   return result;
  // }

  @override
  Widget build(BuildContext context) {
    return _ReportScaffold(
      title: 'Reorder Report',
      onRefresh: _load,
      showAppBar: widget.showAppBar,
      child: BlocBuilder<StockControlReportsCubit, StockControlReportsState>(
        builder: (context, state) {
          final items = state.reorderReport?.items ?? const [];
          return _ReportStateBody(
            status: state.reorderStatus,
            error: state.reorderError,
            emptyMessage: 'No reorder items found.',
            onRetry: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) => _ReorderCard(
                item: items[index],
                isAcknowledging: _acknowledgingIds.contains(
                  items[index].branchStockId,
                ),
                isAcknowledged: _acknowledgedIds.contains(
                  items[index].branchStockId,
                ),
                onAcknowledge: () => _acknowledge(items[index]),
              ),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemCount: items.length,
            ),
          );
        },
      ),
    );
  }
}

class _ReportScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Future<void> Function()? onRefresh;
  final bool showAppBar;

  const _ReportScaffold({
    required this.title,
    required this.child,
    this.onRefresh,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
        appBar: showAppBar
            ? AppBar(
                backgroundColor: context.modeSurface,
                elevation: 0,
                leading: IconButton(
                  icon: AppIcon(
                    Icons.arrow_back,
                    color: context.modeTextPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  title,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    color: context.modeTextPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  if (onRefresh != null)
                    IconButton(
                      icon: AppIcon(Icons.refresh, color: context.modePrimary),
                      onPressed: onRefresh,
                    ),
                ],
              )
            : null,
        body: child,
      ),
    );
  }
}

class _ReportStateBody extends StatelessWidget {
  final StockControlReportStatus status;
  final String? error;
  final String emptyMessage;
  final VoidCallback onRetry;
  final Widget child;

  const _ReportStateBody({
    required this.status,
    required this.error,
    required this.emptyMessage,
    required this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (status == StockControlReportStatus.loading ||
        status == StockControlReportStatus.initial) {
      return Center(
        child: CircularProgressIndicator(color: context.modePrimary),
      );
    }
    if (status == StockControlReportStatus.error) {
      return _CenteredMessage(
        icon: Icons.error_outline,
        title: 'Could not load report',
        message: error ?? 'Please try again.',
        actionText: 'Retry',
        onAction: onRetry,
      );
    }
    if (status == StockControlReportStatus.empty) {
      return _CenteredMessage(
        icon: Icons.inventory_2_outlined,
        title: emptyMessage,
        message: '',
      );
    }
    return child;
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 56, color: context.modeTextMuted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: context.modeTextMuted,
                ),
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpirySummaryGrid extends StatelessWidget {
  final StockExpirySummary summary;

  const _ExpirySummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.0,
      children: [
        _MetricTile(label: 'Expired', value: summary.expired.toString()),
        _MetricTile(
          label: 'Expiring Soon',
          value: summary.expiringSoon.toString(),
        ),
        _MetricTile(
          label: 'This Week',
          value: summary.expiringThisWeek.toString(),
        ),
        _MetricTile(
          label: 'This Month',
          value: summary.expiringThisMonth.toString(),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modePrimary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              height: 1.2,
              color: context.modeTextMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: context.modePrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryItemCard extends StatelessWidget {
  final StockExpiryItem item;
  final String branchId;
  final Future<void> Function() onBatchUpdated;

  const _ExpiryItemCard({
    required this.item,
    required this.branchId,
    required this.onBatchUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      title: item.itemName.isEmpty ? 'Unnamed item' : item.itemName,
      subtitle:
          'Batch: ${item.batchNumber.isEmpty ? 'N/A' : item.batchNumber} | ${item.quantity} ${item.unit}',
      trailing: Text(
        item.daysUntilExpiry <= 0 ? 'Expired' : '${item.daysUntilExpiry} days',
        style: WorkSansAppTextStyles.medium.copyWith(
          color: item.daysUntilExpiry <= 7
              ? const Color(0xFFE53935)
              : context.modePrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: branchId.isEmpty || item.itemId.isEmpty
          ? null
          : () => _showBatches(context, branchId, item.itemId, onBatchUpdated),
    );
  }
}

class _RawStockList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool highlightNegative;

  const _RawStockList({required this.items, this.highlightNegative = false});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = items[index];
        final nestedItem = _asMap(item['item']);
        final branch = _asMap(item['branch']);
        final name = _string(
          item['itemName'] ?? nestedItem['itemName'] ?? nestedItem['name'],
        );
        final stock = _string(item['currentStock'] ?? item['stock']);
        final unit = _string(item['unit'] ?? nestedItem['unit']);
        final sku = _string(item['sku'] ?? nestedItem['sku']);
        final branchName = _string(branch['name']);
        final branchCode = _string(
          branch['branch_code'] ?? branch['branchCode'],
        );
        final lockReason = _string(item['lockReason']);
        final subtitleParts = [
          'Current: ${stock.isEmpty ? '0' : stock}${unit.isEmpty ? '' : ' $unit'}',
          if (branchName.isNotEmpty)
            'Branch: $branchName${branchCode.isEmpty ? '' : ' ($branchCode)'}',
          if (sku.isNotEmpty) 'SKU: $sku',
          if (!highlightNegative && lockReason.isNotEmpty)
            'Reason: $lockReason',
        ];
        return _ReportCard(
          title: name.isEmpty ? 'Stock item' : name,
          subtitle: subtitleParts.join(' | '),
          trailing: highlightNegative
              ? AppIcon(Icons.trending_down, color: context.modeError)
              : AppIcon(Icons.lock_outline, color: context.modePrimary),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemCount: items.length,
    );
  }
}

class _ReorderCard extends StatelessWidget {
  final ReorderSuggestion item;
  final bool isAcknowledging;
  final bool isAcknowledged;
  final VoidCallback onAcknowledge;

  const _ReorderCard({
    required this.item,
    required this.isAcknowledging,
    required this.isAcknowledged,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      title: item.itemName.isEmpty ? 'Stock item' : item.itemName,
      subtitle:
          'Current: ${item.currentStockDisplay} | Reorder: ${item.reorderLevelDisplay} | Suggested: ${item.suggestedQtyDisplay}',
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => context.pushNamed('order-form', extra: item),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.modePrimary,
              side: BorderSide(color: context.modePrimary),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Create PO',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.modePrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: isAcknowledging || isAcknowledged ? null : onAcknowledge,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAcknowledged
                  ? context.modeSuccess
                  : context.modePrimary,
              foregroundColor: context.modeTextInverse,
              disabledBackgroundColor: isAcknowledged
                  ? context.modeSuccess
                  : context.modePrimary.withValues(alpha: 0.45),
              disabledForegroundColor: context.modeTextInverse,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: isAcknowledging
                ? SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.modeTextInverse,
                    ),
                  )
                : AppIcon(
                    isAcknowledged
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    size: 15,
                  ),
            label: Text(
              isAcknowledging
                  ? 'Saving'
                  : isAcknowledged
                  ? 'Acknowledged'
                  : 'Acknowledge',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.modeTextInverse,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ReportCard({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.modePrimary.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            AppIcon(Icons.inventory_2_outlined, color: context.modePrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.modeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 12,
                      color: context.modeTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

void _showBatches(
  BuildContext context,
  String branchId,
  String itemId,
  Future<void> Function() onBatchUpdated,
) {
  final repository = context.read<StockCardRepositoryInterface>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: FutureBuilder(
            future: repository.getBatches(branchId: branchId, itemId: itemId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final response = snapshot.data!;
              if (!response.isSuccess) {
                return _CenteredMessage(
                  icon: Icons.error_outline,
                  title: 'Could not load batches',
                  message: response.error?.toString() ?? '',
                );
              }
              final batches = response.data ?? const <StockBatch>[];
              if (batches.isEmpty) {
                return const _CenteredMessage(
                  icon: Icons.inventory_2_outlined,
                  title: 'No batches found',
                  message: '',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final batch = batches[index];
                  return _ReportCard(
                    title: batch.batchNumber.isEmpty
                        ? 'Batch ${index + 1}'
                        : batch.batchNumber,
                    subtitle:
                        'Qty: ${batch.quantity} ${batch.unit} | Expiry: ${batch.expiryDate?.toIso8601String().split('T').first ?? 'N/A'}',
                    trailing: IconButton(
                      icon: const AppIcon(Icons.edit_outlined),
                      onPressed: () => _showEditBatchDialog(
                        sheetContext,
                        repository,
                        branchId,
                        itemId,
                        batch,
                        onBatchUpdated,
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemCount: batches.length,
              );
            },
          ),
        ),
      );
    },
  );
}

void _showEditBatchDialog(
  BuildContext context,
  StockCardRepositoryInterface repository,
  String branchId,
  String itemId,
  StockBatch batch,
  Future<void> Function() onBatchUpdated,
) {
  final batchNumberController = TextEditingController(text: batch.batchNumber);
  final quantityController = TextEditingController(
    text: batch.quantity.toString(),
  );
  final statusController = TextEditingController(text: batch.status);
  final expiryController = TextEditingController(
    text: batch.expiryDate?.toIso8601String().split('T').first ?? '',
  );

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Edit Batch'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: batchNumberController,
              decoration: const InputDecoration(labelText: 'Batch number'),
            ),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            TextField(
              controller: expiryController,
              decoration: const InputDecoration(labelText: 'Expiry date'),
            ),
            TextField(
              controller: statusController,
              decoration: const InputDecoration(labelText: 'Status'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final response = await repository.updateBatch(
              branchId: branchId,
              itemId: itemId,
              batchId: batch.id,
              request: StockBatchUpdateRequest(
                batchNumber: batchNumberController.text.trim(),
                quantity: double.tryParse(quantityController.text.trim()),
                expiryDate: DateTime.tryParse(expiryController.text.trim()),
                status: statusController.text.trim(),
              ),
            );
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    response.isSuccess
                        ? 'Batch updated.'
                        : 'Failed to update batch.',
                  ),
                  backgroundColor: response.isSuccess
                      ? kGreen
                      : const Color(0xFFE53935),
                ),
              );
            }
            if (response.isSuccess) {
              await onBatchUpdated();
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  ).whenComplete(() {
    batchNumberController.dispose();
    quantityController.dispose();
    statusController.dispose();
    expiryController.dispose();
  });
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _string(dynamic value) => value?.toString() ?? '';
