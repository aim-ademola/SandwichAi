import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/goods_received_advanced_cubit/goods_received_advanced_cubit.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/goods_received_advanced_cubit/goods_received_advanced_state.dart';

class GoodsReceivedOverviewScreen extends StatefulWidget {
  const GoodsReceivedOverviewScreen({super.key});

  @override
  State<GoodsReceivedOverviewScreen> createState() =>
      _GoodsReceivedOverviewScreenState();
}

class _GoodsReceivedOverviewScreenState
    extends State<GoodsReceivedOverviewScreen> {
  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    final branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    if (!mounted) return;
    await context.read<GoodsReceivedAdvancedCubit>().loadOverview(
      branchId: branchId.isEmpty ? null : branchId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: context.modePrimary,
      onRefresh: _loadOverview,
      child:
          BlocBuilder<GoodsReceivedAdvancedCubit, GoodsReceivedAdvancedState>(
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'QC Stats',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.modeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStats(state),
                  const SizedBox(height: 24),
                  Text(
                    'Reorder Suggestions',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.modeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildReorderSuggestions(state),
                ],
              );
            },
          ),
    );
  }

  Widget _buildStats(GoodsReceivedAdvancedState state) {
    if (state.statsStatus == GoodsReceivedAdvancedStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.statsStatus == GoodsReceivedAdvancedStatus.error) {
      return _InfoPanel(
        icon: Icons.error_outline,
        title: 'Could not load QC stats',
        message: state.statsError ?? '',
      );
    }
    final stats = state.qcStats;
    if (stats == null) {
      return const _InfoPanel(
        icon: Icons.fact_check_outlined,
        title: 'No QC stats yet',
        message: '',
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.05,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _MetricCard(label: 'Inspected', value: '${stats.totalInspected}'),
        _MetricCard(label: 'Passed', value: '${stats.passed}'),
        _MetricCard(label: 'Failed', value: '${stats.failed}'),
        _MetricCard(
          label: 'Pass Rate',
          value: '${stats.passRate.toStringAsFixed(0)}%',
        ),
      ],
    );
  }

  Widget _buildReorderSuggestions(GoodsReceivedAdvancedState state) {
    if (state.reorderStatus == GoodsReceivedAdvancedStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.reorderStatus == GoodsReceivedAdvancedStatus.error) {
      final permissionError =
          (state.reorderError ?? '').contains('stock-cards:read') ||
          (state.reorderError ?? '').toLowerCase().contains(
            'missing permission',
          );
      return _InfoPanel(
        icon: permissionError ? Icons.lock_outline : Icons.error_outline,
        title: permissionError
            ? 'Reorder suggestions unavailable'
            : 'Could not load suggestions',
        message: permissionError
            ? 'Your account needs stock-cards:read permission to view these suggestions.'
            : state.reorderError ?? '',
      );
    }
    final suggestions = state.reorderSuggestions?.suggestions ?? const [];
    if (suggestions.isEmpty) {
      return const _InfoPanel(
        icon: Icons.inventory_2_outlined,
        title: 'No reorder suggestions',
        message: '',
      );
    }
    return Column(
      children: suggestions
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.modeSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.modeBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: context.modePrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: AppIcon(
                            Icons.inventory_2_outlined,
                            color: context.modePrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.itemName.isEmpty ? 'Stock item' : item.itemName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.modeTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.modePrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.urgency.isEmpty ? 'Reorder' : item.urgency,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: context.modePrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildReorderDetailChip(
                        'Current',
                        item.currentStockDisplay,
                      ),
                      _buildReorderDetailChip(
                        'Reorder level',
                        item.reorderLevelDisplay,
                      ),
                      _buildReorderDetailChip(
                        'Suggested',
                        item.suggestedQtyDisplay,
                      ),
                      if (item.purchaseQtyDisplay.isNotEmpty)
                        _buildReorderDetailChip(
                          'Purchase qty',
                          item.purchaseQtyDisplay,
                        ),
                      if (item.estimatedUnitCost != null)
                        _buildReorderDetailChip(
                          'Unit cost',
                          _formatCurrency(item.estimatedUnitCost!),
                        ),
                      if (item.estimatedTotalCost != null)
                        _buildReorderDetailChip(
                          'Est. total',
                          _formatCurrency(item.estimatedTotalCost!),
                        ),
                      if (item.daysUntilStockout != null)
                        _buildReorderDetailChip(
                          'Stockout',
                          '${item.daysUntilStockout} days',
                        ),
                    ],
                  ),
                  if (item.category.trim().isNotEmpty ||
                      item.branchName.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (item.category.trim().isNotEmpty)
                          _buildReorderMetaText('Category: ${item.category}'),
                        if (item.branchName.trim().isNotEmpty)
                          _buildReorderMetaText('Branch: ${item.branchName}'),
                      ],
                    ),
                  ],
                  if (item.supplierName.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Supplier: ${item.supplierName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.modeTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () =>
                          context.pushNamed('order-form', extra: item),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.modePrimary,
                        side: BorderSide(color: context.modePrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Create PO',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: context.modePrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatCurrency(double value) {
    return 'NGN ${NumberFormat('#,##0.##').format(value)}';
  }

  Widget _buildReorderMetaText(String text) {
    return Text(
      text,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: context.modeTextSecondary,
      ),
    );
  }

  Widget _buildReorderDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.modeTextMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
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
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modePrimary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: context.modeTextMuted,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.modePrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: AppIcon(icon, color: context.modeTextMuted, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.isEmpty ? title : '$title\n$message',
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
}
