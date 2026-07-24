import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/bloc/get_recipe_compl.dart/bloc.dart';
import 'package:sandwich_ai/src/features/processing/data/model/recipe_compliance_models.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';

class RecipeComplianceHistoryScreen extends StatefulWidget {
  const RecipeComplianceHistoryScreen({super.key});

  @override
  State<RecipeComplianceHistoryScreen> createState() =>
      _RecipeComplianceHistoryScreenState();
}

class _RecipeComplianceHistoryScreenState
    extends State<RecipeComplianceHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    context.read<RecipeComplianceHistoryBloc>().add(
      const LoadRecipeComplianceHistory(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showComplianceDetails(RecipeComplianceResponse compliance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.modeDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Compliance Details',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: context.modeTextPrimary,
                          ),
                        ),
                      ),
                      _buildStatusBadge(compliance.status),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (compliance.menuItem != null) ...[
                    _buildDetailRow('Menu Item', compliance.menuItem!.dishName),
                    _buildDetailRow('Category', compliance.menuItem!.category),
                  ],
                  _buildDetailRow('Item Name', compliance.itemName),
                  _buildDetailRow(
                    'Batches Prepared',
                    compliance.batchesPrepared.toString(),
                  ),
                  _buildDetailRow(
                    'Expected Input',
                    '${compliance.expectedInput} units',
                  ),
                  _buildDetailRow(
                    'Actual Input',
                    '${compliance.actualInput} units',
                  ),
                  _buildDetailRow(
                    'Variance',
                    '${compliance.variance} (${compliance.variancePercent}%)',
                    valueColor: _getVarianceColor(compliance.variancePercent),
                  ),
                  _buildDetailRow(
                    'Check Date',
                    _formatDate(compliance.checkDate),
                  ),
                  if (compliance.notes != null && compliance.notes!.isNotEmpty)
                    _buildDetailRow('Notes', compliance.notes!),
                  if (compliance.branch != null)
                    _buildDetailRow('Branch', compliance.branch!.name),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: context.modePrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Close',
                        textAlign: TextAlign.center,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.modeTextInverse,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Status',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildFilterChip('All', null, bottomSheetContext),
            _buildFilterChip('CRITICAL', 'CRITICAL', bottomSheetContext),
            _buildFilterChip('LOW', 'LOW', bottomSheetContext),
            _buildFilterChip('OPTIMAL', 'OPTIMAL', bottomSheetContext),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? value,
    BuildContext bottomSheetContext,
  ) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = value;
        });
        context.read<RecipeComplianceHistoryBloc>().add(
          FilterByStatus(status: value),
        );
        Navigator.pop(bottomSheetContext);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? context.modePrimary.withValues(alpha: 0.1)
              : context.modeSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? context.modePrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? context.modePrimary : context.modeTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: context.modeTextSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? context.modeTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'CRITICAL':
        backgroundColor = context.modeError.withValues(alpha: 0.12);
        textColor = context.modeError;
        break;
      case 'LOW':
        backgroundColor = context.modeWarning.withValues(alpha: 0.12);
        textColor = context.modeWarning;
        break;
      case 'OPTIMAL':
        backgroundColor = context.modeSuccess.withValues(alpha: 0.12);
        textColor = context.modeSuccess;
        break;
      default:
        backgroundColor = context.modeSurfaceAlt;
        textColor = context.modeTextSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Color _getVarianceColor(String variancePercent) {
    final variance = double.tryParse(variancePercent) ?? 0;
    if (variance.abs() > 20) {
      return context.modeError;
    } else if (variance.abs() > 10) {
      return context.modeWarning;
    } else {
      return context.modeSuccess;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,

        body:
            BlocConsumer<
              RecipeComplianceHistoryBloc,
              RecipeComplianceHistoryState
            >(
              listener: (context, state) {
                if (state is RecipeComplianceHistoryError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.error,
                        style: TextStyle(color: context.modeTextInverse),
                      ),
                      backgroundColor: context.modeError,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is RecipeComplianceHistoryLoading ||
                    state is RecipeComplianceHistoryRefreshing) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return shimmerCatalogCard(constraints.maxWidth);
                    },
                  );
                }

                if (state is RecipeComplianceHistoryEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          Icons.assessment_outlined,
                          size: 64,
                          color: context.modeTextMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No compliance records found',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 16,
                            color: context.modeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is RecipeComplianceHistoryError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          Icons.error_outline,
                          size: 64,
                          color: context.modeTextMuted,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            state.error,
                            textAlign: TextAlign.center,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 16,
                              color: context.modeTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            context.read<RecipeComplianceHistoryBloc>().add(
                              const LoadRecipeComplianceHistory(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.modePrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              color: context.modeTextInverse,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is RecipeComplianceHistoryLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<RecipeComplianceHistoryBloc>().add(
                        const RefreshRecipeComplianceHistory(),
                      );
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          // Summary Cards
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    icon: Icons.assessment,
                                    iconColor: context.modePrimary,
                                    iconBgColor: context.modePrimary.withValues(
                                      alpha: 0.1,
                                    ),
                                    title: 'Total Checks',
                                    value: state.allRecords.length.toString(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    icon: Icons.trending_up,
                                    iconColor: context.modeWarning,
                                    iconBgColor: context.modeWarning.withValues(
                                      alpha: 0.1,
                                    ),
                                    title: 'Avg Variance',
                                    value:
                                        '${state.averageVariance.toStringAsFixed(1)}%',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Status Distribution
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: context.modeSurface,
                                border: Border.all(
                                  color: context.modeBorder.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.modeTextPrimary.withValues(
                                      alpha: 0.04,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status Distribution',
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: context.modeTextPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildStatusRow(
                                    'Critical',
                                    state.statusCounts['CRITICAL'] ?? 0,
                                    context.modeError,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildStatusRow(
                                    'Low',
                                    state.statusCounts['LOW'] ?? 0,
                                    context.modeWarning,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildStatusRow(
                                    'Optimal',
                                    state.statusCounts['OPTIMAL'] ?? 0,
                                    context.modeSuccess,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Records List Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Checks',
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: context.modeTextPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.modePrimary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${state.filteredRecords.length} records',
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: context.modePrimary,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Records List
                          if (state.filteredRecords.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(48.0),
                                child: Text(
                                  'No records match your filter',
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 16,
                                    color: context.modeTextSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: state.filteredRecords.length,
                              itemBuilder: (context, index) {
                                final record = state.filteredRecords[index];
                                return GestureDetector(
                                  onTap: () => _showComplianceDetails(record),
                                  child: _buildComplianceCard(record),
                                );
                              },
                            ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modeSurface,
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: AppIcon(icon, color: iconColor, size: 20)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: context.modeTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: context.modeTextPrimary,
            ),
          ),
        ),
        Text(
          count.toString(),
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.modeTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceCard(RecipeComplianceResponse record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modeSurface,
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.menuItem?.dishName ?? record.itemName,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextPrimary,
                  ),
                ),
              ),
              _buildStatusBadge(record.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  Icons.scale,
                  'Variance: ${record.variancePercent}%',
                  _getVarianceColor(record.variancePercent),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  Icons.inventory_2,
                  '${record.batchesPrepared} batches',
                  context.modeTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AppIcon(
                Icons.calendar_today,
                size: 14,
                color: context.modeTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(record.checkDate),
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 13,
                  color: context.modeTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
