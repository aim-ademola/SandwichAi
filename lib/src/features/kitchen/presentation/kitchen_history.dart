import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen_shift_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen_shift_bloc/event.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen_shift_bloc/state.dart';
import 'package:sandwich_ai/src/features/kitchen/data/model/kitchen_shift_model.dart';

import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';
import 'package:intl/intl.dart';

class KitchenShiftHistoryScreen extends StatefulWidget {
  const KitchenShiftHistoryScreen({super.key});

  @override
  State<KitchenShiftHistoryScreen> createState() =>
      _KitchenShiftHistoryScreenState();
}

class _KitchenShiftHistoryScreenState extends State<KitchenShiftHistoryScreen> {
  String? _selectedEmployeeId;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    // Load last 30 days by default
    _selectedStartDate = DateTime.now().subtract(const Duration(days: 30));
    _selectedEndDate = DateTime.now();

    context.read<KitchenShiftBloc>().add(
      LoadKitchenShifts(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.modePrimary,
              onPrimary: context.modeTextInverse,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      this.context.read<KitchenShiftBloc>().add(
        FilterShiftsByDateRange(startDate: picked.start, endDate: picked.end),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final horizontalPadding = _getHorizontalPadding(screenWidth);

        return Scaffold(
          backgroundColor: context.modeBackground,
          body: BlocBuilder<KitchenShiftBloc, KitchenShiftState>(
            builder: (context, state) {
              if (state is KitchenShiftLoading ||
                  state is KitchenShiftRefreshing) {
                return shimmerCatalogCard(screenWidth);
              }

              if (state is KitchenShiftEmpty) {
                return _buildEmptyState(screenWidth, horizontalPadding);
              }

              if (state is KitchenShiftError) {
                return _buildErrorState(
                  screenWidth,
                  horizontalPadding,
                  state.error,
                );
              }

              if (state is KitchenShiftLoaded) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<KitchenShiftBloc>().add(
                      const RefreshKitchenShifts(),
                    );
                  },
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: _getVerticalPadding(screenWidth),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilters(screenWidth, state),
                        SizedBox(height: _getSectionSpacing(screenWidth)),
                        _buildStatistics(screenWidth, state),
                        SizedBox(height: _getSectionSpacing(screenWidth)),
                        _buildShiftsList(screenWidth, state),
                        SizedBox(height: _getVerticalPadding(screenWidth)),
                      ],
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildFilters(double screenWidth, KitchenShiftLoaded state) {
    return Container(
      padding: EdgeInsets.all(_getInputPaddingHorizontal(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getSectionTitleFontSize(screenWidth),
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          SizedBox(height: _getFieldSpacing(screenWidth)),

          // Employee Filter
          DropdownButtonFormField<String>(
            initialValue: _selectedEmployeeId,
            decoration: InputDecoration(
              labelText: 'Filter by Employee',
              labelStyle: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getLabelFontSize(screenWidth),
                color: context.modeTextSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  _getBorderRadius(screenWidth),
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: _getInputPaddingHorizontal(screenWidth),
                vertical: _getInputPaddingVertical(screenWidth),
              ),
            ),
            items: [
              DropdownMenuItem(value: null, child: Text('All Employees')),
              ...state.employees.map(
                (emp) =>
                    DropdownMenuItem(value: emp.id, child: Text(emp.fullName)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedEmployeeId = value;
              });
              context.read<KitchenShiftBloc>().add(
                FilterShiftsByEmployee(employeeId: value),
              );
            },
          ),
          SizedBox(height: _getFieldSpacing(screenWidth)),

          // Date Range Filter
          InkWell(
            onTap: () => _selectDateRange(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _getInputPaddingHorizontal(screenWidth),
                vertical: _getInputPaddingVertical(screenWidth),
              ),
              decoration: BoxDecoration(
                border: Border.all(color: context.modeBorder),
                borderRadius: BorderRadius.circular(
                  _getBorderRadius(screenWidth),
                ),
              ),
              child: Row(
                children: [
                  AppIcon(Icons.date_range, color: context.modePrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedStartDate != null && _selectedEndDate != null
                          ? '${DateFormat('MMM d').format(_selectedStartDate!)} - ${DateFormat('MMM d, y').format(_selectedEndDate!)}'
                          : 'Select Date Range',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getInputFontSize(screenWidth),
                        color: context.modeTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_selectedEmployeeId != null ||
              _selectedStartDate != null ||
              _selectedEndDate != null) ...[
            SizedBox(height: _getFieldSpacing(screenWidth)),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedEmployeeId = null;
                  _selectedStartDate = DateTime.now().subtract(
                    const Duration(days: 30),
                  );
                  _selectedEndDate = DateTime.now();
                });
                context.read<KitchenShiftBloc>().add(const ClearShiftFilters());
              },
              icon: const AppIcon(Icons.clear, size: 18),
              label: Text('Clear Filters'),
              style: TextButton.styleFrom(foregroundColor: context.modePrimary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatistics(double screenWidth, KitchenShiftLoaded state) {
    final shifts = state.filteredShifts;
    final totalShifts = shifts.length;
    final activeShifts = shifts.where((s) => s.isActive).length;
    final uniqueEmployees = shifts.map((s) => s.employeeId).toSet().length;

    return Container(
      padding: EdgeInsets.all(_getInputPaddingHorizontal(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getSectionTitleFontSize(screenWidth),
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          SizedBox(height: _getFieldSpacing(screenWidth)),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  screenWidth,
                  'Total Shifts',
                  totalShifts.toString(),
                  Icons.calendar_today,
                  context.modePrimary,
                ),
              ),
              SizedBox(width: _getFieldSpacing(screenWidth)),
              Expanded(
                child: _buildStatCard(
                  screenWidth,
                  'Active',
                  activeShifts.toString(),
                  Icons.check_circle,
                  kGreen,
                ),
              ),
              SizedBox(width: _getFieldSpacing(screenWidth)),
              Expanded(
                child: _buildStatCard(
                  screenWidth,
                  'Employees',
                  uniqueEmployees.toString(),
                  Icons.people,
                  const Color(0xFF64B5F6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    double screenWidth,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(_getInputPaddingHorizontal(screenWidth)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
      ),
      child: Column(
        children: [
          AppIcon(icon, color: color, size: _getIconSize(screenWidth) + 4),
          SizedBox(height: _getFieldSpacing(screenWidth) / 2),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getSectionTitleFontSize(screenWidth) + 2,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getCaptionFontSize(screenWidth),
              color: context.modeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftsList(double screenWidth, KitchenShiftLoaded state) {
    final shifts = state.filteredShifts;

    return Container(
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(_getInputPaddingHorizontal(screenWidth)),
            child: Text(
              'Shift History',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getSectionTitleFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
          ),
          Divider(height: 1, color: context.modeDivider),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shifts.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: context.modeDivider),
            itemBuilder: (context, index) {
              final shift = shifts[index];
              return _buildShiftTile(screenWidth, shift);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShiftTile(double screenWidth, KitchenShift shift) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: _getInputPaddingHorizontal(screenWidth),
        vertical: _getInputPaddingVertical(screenWidth) / 2,
      ),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getShiftTypeColor(shift.shiftType).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: AppIcon(
          _getShiftTypeIcon(shift.shiftType),
          color: _getShiftTypeColor(shift.shiftType),
          size: 24,
        ),
      ),
      title: Text(
        shift.employee.fullName,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getInputFontSize(screenWidth),
          fontWeight: FontWeight.w600,
          color: context.modeTextPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '${shift.formattedDate} â€¢ ${shift.shiftTypeDisplay}',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getCaptionFontSize(screenWidth),
              color: context.modeTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            shift.formattedTimeRange,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getCaptionFontSize(screenWidth),
              color: context.modeTextSecondary,
            ),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: shift.isActive
              ? kGreen.withValues(alpha: 0.1)
              : context.modeSurfaceAlt,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          shift.isActive ? 'Active' : 'Inactive',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getCaptionFontSize(screenWidth),
            fontWeight: FontWeight.w600,
            color: shift.isActive
                ? context.modeSuccess
                : context.modeTextSecondary,
          ),
        ),
      ),
    );
  }

  Color _getShiftTypeColor(ShiftType type) {
    switch (type) {
      case ShiftType.MORNING:
        return context.modeWarning;
      case ShiftType.AFTERNOON:
        return const Color(0xFF64B5F6);
      case ShiftType.EVENING:
        return const Color(0xFFBA68C8);
      case ShiftType.NIGHT:
        return const Color(0xFF4DB6AC);
      case ShiftType.FULL_DAY:
        return context.modePrimary;
    }
  }

  IconData _getShiftTypeIcon(ShiftType type) {
    switch (type) {
      case ShiftType.MORNING:
        return Icons.wb_sunny;
      case ShiftType.AFTERNOON:
        return Icons.wb_cloudy;
      case ShiftType.EVENING:
        return Icons.wb_twilight;
      case ShiftType.NIGHT:
        return Icons.nights_stay;
      case ShiftType.FULL_DAY:
        return Icons.all_inclusive;
    }
  }

  Widget _buildEmptyState(double screenWidth, double horizontalPadding) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              Icons.history,
              size: 80,
              color: context.modeTextMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No shift history',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getSectionTitleFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Past shifts will appear here',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                color: context.modeTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    double screenWidth,
    double horizontalPadding,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              Icons.error_outline,
              size: 80,
              color: context.modeError.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading history',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getSectionTitleFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                color: context.modeTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<KitchenShiftBloc>().add(
                  LoadKitchenShifts(
                    startDate: _selectedStartDate,
                    endDate: _selectedEndDate,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(screenWidth),
                  ),
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

  // Responsive sizing functions
  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 32;
    return 48;
  }

  double _getVerticalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getSectionSpacing(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getFieldSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getSectionTitleFontSize(double width) {
    if (width < 360) return 16;
    if (width < 600) return 17;
    return 18;
  }

  double _getLabelFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getInputFontSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }

  double _getCaptionFontSize(double width) {
    if (width < 360) return 11;
    if (width < 600) return 12;
    return 13;
  }

  double _getBorderRadius(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getInputPaddingHorizontal(double width) {
    if (width < 360) return 14;
    if (width < 600) return 16;
    return 18;
  }

  double _getInputPaddingVertical(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getIconSize(double width) {
    if (width < 360) return 20;
    if (width < 600) return 22;
    return 24;
  }
}
