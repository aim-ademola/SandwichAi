import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/wastage_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/wastage_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/wastage_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/wastage_log.dart';

class WasteLogsHistoryScreen extends StatefulWidget {
  const WasteLogsHistoryScreen({super.key});

  @override
  State<WasteLogsHistoryScreen> createState() => _WasteLogsHistoryScreenState();
}

class _WasteLogsHistoryScreenState extends State<WasteLogsHistoryScreen> {
  String? _selectedReason;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<WasteLogsBloc>();
    bloc.add(LoadWasteLogs(branchId: bloc.branchId));
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: context.modePrimary,
              onPrimary: context.modeTextInverse,
              onSurface: context.modeTextPrimary,
              surface: context.modeSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      context.read<WasteLogsBloc>().add(
        FilterByDateRange(
          startDate: picked.start.toIso8601String(),
          endDate: picked.end.toIso8601String(),
        ),
      );
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedReason = null;
      _startDate = null;
      _endDate = null;
    });
    context.read<WasteLogsBloc>().add(RefreshWasteLogs());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WasteLogsBloc, WasteLogsState>(
      builder: (context, state) {
        if (state is WasteLogsLoading) {
          return Center(
            child: CircularProgressIndicator(color: context.modePrimary),
          );
        }

        if (state is WasteLogsError) {
          AppLogger.log(state.error);
          return _buildErrorState(state.error);
        }

        if (state is WasteLogsEmpty) {
          return _buildEmptyState();
        }

        if (state is WasteLogsLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<WasteLogsBloc>().add(RefreshWasteLogs());
            },
            child: Column(
              children: [
                _buildFiltersSection(state),
                _buildSummaryCards(state.response),
                Expanded(child: _buildLogsList(state.response.logs)),
              ],
            ),
          );
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildFiltersSection(WasteLogsLoaded state) {
    return Container(
      color: context.modeSurface,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildReasonFilter()),
              SizedBox(width: 12),
              _buildDateRangeButton(),
            ],
          ),
          if (_selectedReason != null || _startDate != null) ...[
            SizedBox(height: 12),
            _buildActiveFilters(),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: context.modeBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedReason,
          hint: Text(
            'Filter by reason',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: context.modeTextSecondary,
            ),
          ),
          isExpanded: true,
          dropdownColor: context.modeSurface,
          iconEnabledColor: context.modeTextSecondary,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: context.modeTextPrimary,
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                'All Reasons',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: context.modeTextPrimary,
                ),
              ),
            ),
            ...WasteReason.values.map((reason) {
              return DropdownMenuItem(
                value: reason.value,
                child: Text(
                  reason.displayName,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: context.modeTextPrimary,
                  ),
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedReason = value;
            });
            context.read<WasteLogsBloc>().add(FilterByReason(reason: value));
          },
        ),
      ),
    );
  }

  Widget _buildDateRangeButton() {
    return InkWell(
      onTap: _selectDateRange,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: context.modeBorder),
          borderRadius: BorderRadius.circular(8),
          color: _startDate != null
              ? context.modePrimary.withValues(alpha: 0.1)
              : context.modeSurface,
        ),
        child: AppIcon(
          Icons.date_range,
          color: _startDate != null
              ? context.modePrimary
              : context.modeTextSecondary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Row(
      children: [
        if (_selectedReason != null)
          _buildFilterChip(
            'Reason: ${WasteReason.values.firstWhere((r) => r.value == _selectedReason).displayName}',
            () {
              setState(() => _selectedReason = null);
              context.read<WasteLogsBloc>().add(FilterByReason(reason: null));
            },
          ),
        if (_startDate != null) ...[
          SizedBox(width: 8),
          _buildFilterChip(
            '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}',
            () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
              context.read<WasteLogsBloc>().add(FilterByDateRange());
            },
          ),
        ],
        Spacer(),
        TextButton(
          onPressed: _clearFilters,
          child: Text(
            'Clear All',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              color: context.modePrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.modePrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: context.modePrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: AppIcon(Icons.close, size: 16, color: context.modePrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(WasteLogsResponse response) {
    return Container(
      color: context.modeBackground,
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Logs',
              response.totalCount.toString(),
              Icons.description_outlined,
              Colors.blue,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Total Loss',
              'â‚¦${_formatCurrency(response.totalValueLost)}',
              Icons.money_off_outlined,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modeSurface,
        border: Border.all(color: context.modeBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.22
                  : 0.04,
            ),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppIcon(icon, color: color, size: 20),
              ),
              Spacer(),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: context.modeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<WasteLogItem> logs) {
    return Container(
      color: context.modeBackground,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          return _buildLogCard(logs[index]);
        },
      ),
    );
  }

  Widget _buildLogCard(WasteLogItem log) {
    final reasonColor = _getReasonColor(log.reason);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.modeSurface,
        border: Border.all(color: context.modeBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.22
                  : 0.04,
            ),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.itemName,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.modeTextPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            log.item.category,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 13,
                              color: context.modeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: reasonColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        WasteReason.values
                            .firstWhere((r) => r.value == log.reason)
                            .displayName,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: reasonColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.scale_outlined,
                      '${log.quantity} ${log.unit}',
                    ),
                    SizedBox(width: 20),
                    _buildInfoItem(
                      Icons.payments_outlined,
                      'â‚¦${_formatCurrency(log.valueLostAsDouble)}',
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (log.notes.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.modeSurfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        AppIcon(
                          Icons.note_outlined,
                          size: 16,
                          color: context.modeTextSecondary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            log.notes,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 13,
                              color: context.modeTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],
                Row(
                  children: [
                    AppIcon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: context.modeTextSecondary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      DateFormat('MMM d, yyyy').format(log.date),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: context.modeTextSecondary,
                      ),
                    ),
                    SizedBox(width: 16),
                    AppIcon(
                      Icons.person_outline,
                      size: 14,
                      color: context.modeTextSecondary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      log.recordedBy,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: context.modeTextSecondary,
                      ),
                    ),
                    if (log.isVerified) ...[
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(
                              Icons.verified_outlined,
                              size: 12,
                              color: Colors.green,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        AppIcon(icon, size: 16, color: context.modeTextSecondary),
        SizedBox(width: 6),
        Text(
          text,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.modeTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(Icons.delete_outline, size: 80, color: context.modeTextMuted),
          SizedBox(height: 16),
          Text(
            'No waste logs found',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start logging waste to see records here',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: context.modeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              Icons.error_outline,
              size: 80,
              color: context.modeError.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16),
            Text(
              'Error loading waste logs',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<WasteLogsBloc>().add(RefreshWasteLogs());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }

  Color _getReasonColor(String reason) {
    switch (reason) {
      case 'SPOILAGE':
        return Colors.orange;
      case 'THEFT':
        return Colors.red;
      case 'EXPIRED':
        return Colors.purple;
      case 'DAMAGED':
        return Colors.brown;
      case 'SHRINKAGE':
        return Colors.blue;
      case 'OVERUSE':
        return Colors.teal;
      case 'POOR_STORAGE':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }
}
