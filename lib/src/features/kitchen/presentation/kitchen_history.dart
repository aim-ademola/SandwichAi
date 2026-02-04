import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
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
              primary: kPrimary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      context.read<KitchenShiftBloc>().add(
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
          backgroundColor: const Color(0xFFF8F6F6),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: kprimaryTextColor1,
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
                color: kprimaryTextColor2,
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
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(
                  _getBorderRadius(screenWidth),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range, color: kPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedStartDate != null && _selectedEndDate != null
                          ? '${DateFormat('MMM d').format(_selectedStartDate!)} - ${DateFormat('MMM d, y').format(_selectedEndDate!)}'
                          : 'Select Date Range',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getInputFontSize(screenWidth),
                        color: kprimaryTextColor1,
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
              icon: const Icon(Icons.clear, size: 18),
              label: Text('Clear Filters'),
              style: TextButton.styleFrom(foregroundColor: kPrimary),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: kprimaryTextColor1,
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
                  kPrimary,
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: _getIconSize(screenWidth) + 4),
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
              color: kprimaryTextColor2,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                color: kprimaryTextColor1,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shifts.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade200),
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
          color: _getShiftTypeColor(shift.shiftType).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
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
          color: kprimaryTextColor1,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '${shift.formattedDate} • ${shift.shiftTypeDisplay}',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getCaptionFontSize(screenWidth),
              color: kprimaryTextColor2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            shift.formattedTimeRange,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getCaptionFontSize(screenWidth),
              color: kprimaryTextColor2,
            ),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: shift.isActive
              ? kGreen.withOpacity(0.1)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          shift.isActive ? 'Active' : 'Inactive',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getCaptionFontSize(screenWidth),
            fontWeight: FontWeight.w600,
            color: shift.isActive ? kGreen : kprimaryTextColor2,
          ),
        ),
      ),
    );
  }

  Color _getShiftTypeColor(ShiftType type) {
    switch (type) {
      case ShiftType.MORNING:
        return const Color(0xFFFFB74D);
      case ShiftType.AFTERNOON:
        return const Color(0xFF64B5F6);
      case ShiftType.EVENING:
        return const Color(0xFFBA68C8);
      case ShiftType.NIGHT:
        return const Color(0xFF4DB6AC);
      case ShiftType.FULL_DAY:
        return kPrimary;
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
            Icon(
              Icons.history,
              size: 80,
              color: kprimaryTextColor2.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No shift history',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getSectionTitleFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Past shifts will appear here',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                color: kprimaryTextColor2,
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
            Icon(
              Icons.error_outline,
              size: 80,
              color: const Color(0xFFE53935).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading history',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getSectionTitleFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                color: kprimaryTextColor2,
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
                backgroundColor: kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(screenWidth),
                  ),
                ),
              ),
              child: Text(
                'Retry',
                style: WorkSansAppTextStyles.medium.copyWith(
                  color: Colors.white,
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
