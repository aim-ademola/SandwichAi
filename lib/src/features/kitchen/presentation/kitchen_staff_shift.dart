import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen_shift_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen_shift_bloc/event.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen_shift_bloc/state.dart';
import 'package:sandwich_ai/src/features/kitchen/data/model/kitchen_shift_model.dart';
import 'package:sandwich_ai/src/features/kitchen/presentation/add_edit_shift.dart';

import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';
import 'package:intl/intl.dart';

class KitchenShiftManagementScreen extends StatefulWidget {
  const KitchenShiftManagementScreen({super.key});

  @override
  State<KitchenShiftManagementScreen> createState() =>
      _KitchenShiftManagementScreenState();
}

class _KitchenShiftManagementScreenState
    extends State<KitchenShiftManagementScreen> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    // Set default date range to current week
    _selectedStartDate = _getWeekStart(DateTime.now());
    _selectedEndDate = _getWeekEnd(DateTime.now());

    context.read<KitchenShiftBloc>().add(
      LoadKitchenShifts(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      ),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  DateTime _getWeekEnd(DateTime date) {
    return date.add(Duration(days: 7 - date.weekday));
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: WorkSansAppTextStyles.medium.copyWith(
            color: context.modeTextInverse,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError ? context.modeError : context.modeSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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

  void _showAddShiftDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<KitchenShiftBloc>(),
        child: AddShiftDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<KitchenShiftBloc, KitchenShiftState>(
          listener: (context, state) {
            if (state is KitchenShiftOperationSuccess) {
              _showSnackBar(state.message);
            } else if (state is KitchenShiftError) {
              _showSnackBar(state.error, isError: true);
            }
          },
        ),
      ],
      child: LayoutBuilder(
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
                          _buildWeeklyView(screenWidth, state),
                          SizedBox(height: _getVerticalPadding(screenWidth)),
                        ],
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddShiftDialog(context),
              backgroundColor: context.modePrimary,
              foregroundColor: context.modeTextInverse,
              icon: const AppIcon(Icons.add),
              label: Text(
                'Add Shift',
                style: WorkSansAppTextStyles.medium.copyWith(
                  color: context.modeTextInverse,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
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
        ],
      ),
    );
  }

  Widget _buildWeeklyView(double screenWidth, KitchenShiftLoaded state) {
    final shifts = state.filteredShifts;
    final employees = state.employees;

    // Group shifts by date and employee
    final shiftsByDateAndEmployee = <String, Map<String, List<KitchenShift>>>{};

    for (var shift in shifts) {
      final dateKey = shift.date.split('T')[0];
      if (!shiftsByDateAndEmployee.containsKey(dateKey)) {
        shiftsByDateAndEmployee[dateKey] = {};
      }
      if (!shiftsByDateAndEmployee[dateKey]!.containsKey(shift.employeeId)) {
        shiftsByDateAndEmployee[dateKey]![shift.employeeId] = [];
      }
      shiftsByDateAndEmployee[dateKey]![shift.employeeId]!.add(shift);
    }

    // Generate date range
    final dates = <DateTime>[];
    if (_selectedStartDate != null && _selectedEndDate != null) {
      var current = _selectedStartDate!;
      while (current.isBefore(_selectedEndDate!) ||
          current.isAtSameMomentAs(_selectedEndDate!)) {
        dates.add(current);
        current = current.add(const Duration(days: 1));
      }
    }

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cooks on Duty',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getSectionTitleFontSize(screenWidth),
                    fontWeight: FontWeight.w600,
                    color: context.modeTextPrimary,
                  ),
                ),
                Text(
                  _selectedStartDate != null && _selectedEndDate != null
                      ? '${DateFormat('MMM d').format(_selectedStartDate!)} - ${DateFormat('MMM d, y').format(_selectedEndDate!)}'
                      : '',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getCaptionFontSize(screenWidth),
                    color: context.modeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.modeDivider),

          // Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: _getInputPaddingHorizontal(screenWidth),
              headingRowColor: WidgetStateProperty.all(context.modeSurfaceAlt),
              columns: [
                DataColumn(
                  label: Text(
                    'Employee',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getLabelFontSize(screenWidth),
                      fontWeight: FontWeight.w600,
                      color: context.modeTextPrimary,
                    ),
                  ),
                ),
                ...dates.map(
                  (date) => DataColumn(
                    label: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date),
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getCaptionFontSize(screenWidth),
                            color: context.modeTextSecondary,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d').format(date),
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getLabelFontSize(screenWidth),
                            fontWeight: FontWeight.w600,
                            color: context.modeTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              rows: employees.map((employee) {
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            employee.fullName,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: _getInputFontSize(screenWidth),
                              fontWeight: FontWeight.w600,
                              color: context.modeTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...dates.map((date) {
                      final dateKey = DateFormat('yyyy-MM-dd').format(date);
                      final employeeShifts =
                          shiftsByDateAndEmployee[dateKey]?[employee.id] ?? [];

                      if (employeeShifts.isEmpty) {
                        return DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: context.modeSurfaceAlt,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'OFF',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: _getCaptionFontSize(screenWidth),
                                color: context.modeTextSecondary,
                              ),
                            ),
                          ),
                        );
                      }

                      return DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: employeeShifts.map((shift) {
                            return GestureDetector(
                              onTap: () => _showShiftDetails(context, shift),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getShiftTypeColor(shift.shiftType),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${shift.shiftTypeDisplay} (${shift.formattedTimeRange})',
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: _getCaptionFontSize(screenWidth),
                                    color: context.modeTextInverse,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
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

  void _showShiftDetails(BuildContext context, KitchenShift shift) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => BlocProvider.value(
        value: context.read<KitchenShiftBloc>(),
        child: ShiftDetailsSheet(shift: shift),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth, double horizontalPadding) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              Icons.calendar_today_outlined,
              size: 80,
              color: context.modeTextMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No shifts scheduled',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getSectionTitleFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a new shift',
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
              'Error loading shifts',
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
}

// Continue with dialog widgets...
