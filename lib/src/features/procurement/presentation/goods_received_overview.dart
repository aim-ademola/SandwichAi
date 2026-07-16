import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
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
    context.read<GoodsReceivedAdvancedCubit>().loadOverview();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: context.modePrimary,
      onRefresh: () =>
          context.read<GoodsReceivedAdvancedCubit>().loadOverview(),
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
      childAspectRatio: 2.3,
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
      return _InfoPanel(
        icon: Icons.error_outline,
        title: 'Could not load suggestions',
        message: state.reorderError ?? '',
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.modeSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.modeBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: context.modePrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName.isEmpty ? 'Stock item' : item.itemName,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.modeTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Current: ${item.currentStock} | Suggested: ${item.suggestedQty}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: context.modeTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.urgency,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.modePrimary,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modePrimary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: context.modeTextMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.modePrimary,
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
        children: [
          Icon(icon, color: context.modeTextMuted),
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
