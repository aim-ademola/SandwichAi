import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen_shift_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen_shift_bloc/event.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen_shift_bloc/state.dart';
import 'package:sandwich_ai/src/features/kitchen/data/model/kitchen_shift_model.dart';

class AddShiftDialog extends StatefulWidget {
  final KitchenShift? existingShift;

  const AddShiftDialog({super.key, this.existingShift});

  @override
  State<AddShiftDialog> createState() => _AddShiftDialogState();
}

class _AddShiftDialogState extends State<AddShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedEmployeeId;
  DateTime? _selectedDate;
  ShiftType? _selectedShiftType;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    context.read<KitchenShiftBloc>().add(LoadKitchenEmployees());

    if (widget.existingShift != null) {
      _initializeFromExistingShift();
    }
  }

  void _initializeFromExistingShift() {
    final shift = widget.existingShift!;
    _selectedEmployeeId = shift.employee.id; // Store employee ID
    _selectedDate = DateTime.parse(shift.date);
    _selectedShiftType = shift.shiftType;
    _notesController.text = shift.notes ?? '';

    try {
      final start = DateTime.parse(shift.startTime);
      _startTime = TimeOfDay(hour: start.hour, minute: start.minute);

      final end = DateTime.parse(shift.endTime);
      _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
    } catch (e) {
      AppLogger.log('Error parsing shift times: $e');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStartTime ? _startTime : _endTime) ?? TimeOfDay.now(),
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
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEmployeeId == null) {
      _showError('Please select an employee');
      return;
    }

    if (_selectedDate == null) {
      _showError('Please select a date');
      return;
    }

    if (_selectedShiftType == null) {
      _showError('Please select a shift type');
      return;
    }

    if (_startTime == null || _endTime == null) {
      _showError('Please select start and end times');
      return;
    }

    final startTimeStr =
        '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00';
    final endTimeStr =
        '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00';

    if (widget.existingShift == null) {
      // Create new shift
      final bloc = context.read<KitchenShiftBloc>();
      final request = CreateKitchenShiftRequest(
        employeeId: _selectedEmployeeId!,
        branchId: bloc.branchId,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        shiftType: _selectedShiftType!,
        startTime: startTimeStr,
        endTime: endTimeStr,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      context.read<KitchenShiftBloc>().add(CreateShift(request: request));
    } else {
      // Update existing shift
      final request = UpdateKitchenShiftRequest(
        employeeId: _selectedEmployeeId,
        date: _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : null,
        shiftType: _selectedShiftType,
        startTime: startTimeStr,
        endTime: endTimeStr,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      context.read<KitchenShiftBloc>().add(
        UpdateShift(shiftId: widget.existingShift!.id, request: request),
      );
    }

    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE53935),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existingShift == null
                          ? 'Add New Shift'
                          : 'Edit Shift',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kprimaryTextColor1,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Employee Selection
                BlocBuilder<KitchenShiftBloc, KitchenShiftState>(
                  builder: (context, state) {
                    AppLogger.log('DEBUG: Current state: ${state.runtimeType}');

                    final employees = state is KitchenShiftLoaded
                        ? state.employees
                        : <Employee>[];

                    AppLogger.log(
                      'DEBUG: Employees count: ${employees.length}',
                    );
                    AppLogger.log(
                      'DEBUG: Selected employee ID: $_selectedEmployeeId',
                    );

                    // Remove duplicates by ID
                    final uniqueEmployees = <String, Employee>{};
                    for (var emp in employees) {
                      uniqueEmployees[emp.id] = emp;
                    }
                    final employeesList = uniqueEmployees.values.toList();

                    AppLogger.log(
                      'DEBUG: Unique employees count: ${employeesList.length}',
                    );

                    if (employeesList.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Loading employees...',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            color: kprimaryTextColor2,
                          ),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedEmployeeId,
                      decoration: InputDecoration(
                        labelText: 'Employee *',
                        labelStyle: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          color: kprimaryTextColor2,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: employeesList
                          .map(
                            (emp) => DropdownMenuItem<String>(
                              value: emp.id,
                              child: Text(emp.fullName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEmployeeId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an employee';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Date Selection
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date *',
                      labelStyle: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: kprimaryTextColor2,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate != null
                              ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(_selectedDate!)
                              : 'Select date',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 15,
                            color: _selectedDate != null
                                ? kprimaryTextColor1
                                : kprimaryTextColor2,
                          ),
                        ),
                        Icon(Icons.calendar_today, color: kPrimary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Shift Type Selection
                DropdownButtonFormField<ShiftType>(
                  initialValue: _selectedShiftType,
                  decoration: InputDecoration(
                    labelText: 'Shift Type *',
                    labelStyle: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: kprimaryTextColor2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items: ShiftType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_getShiftTypeName(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedShiftType = value;
                      _updateTimesForShiftType(value);
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a shift type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Time Selection
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Start Time *',
                            labelStyle: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 14,
                              color: kprimaryTextColor2,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startTime != null
                                    ? _startTime!.format(context)
                                    : 'Select',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 15,
                                  color: _startTime != null
                                      ? kprimaryTextColor1
                                      : kprimaryTextColor2,
                                ),
                              ),
                              Icon(
                                Icons.access_time,
                                color: kPrimary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End Time *',
                            labelStyle: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 14,
                              color: kprimaryTextColor2,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _endTime != null
                                    ? _endTime!.format(context)
                                    : 'Select',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 15,
                                  color: _endTime != null
                                      ? kprimaryTextColor1
                                      : kprimaryTextColor2,
                                ),
                              ),
                              Icon(
                                Icons.access_time,
                                color: kPrimary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Add any relevant notes or instructions',
                    labelStyle: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: kprimaryTextColor2,
                    ),
                    hintStyle: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: kprimaryTextColor2.withValues(alpha: 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kPrimary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 15,
                    color: kprimaryTextColor1,
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: kPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cancel',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            color: kPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          widget.existingShift == null ? 'Add Shift' : 'Update',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getShiftTypeName(ShiftType type) {
    switch (type) {
      case ShiftType.MORNING:
        return 'Morning Shift';
      case ShiftType.AFTERNOON:
        return 'Afternoon Shift';
      case ShiftType.EVENING:
        return 'Evening Shift';
      case ShiftType.NIGHT:
        return 'Night Shift';
      case ShiftType.FULL_DAY:
        return 'Full Day';
    }
  }

  void _updateTimesForShiftType(ShiftType? type) {
    if (type == null) return;

    switch (type) {
      case ShiftType.MORNING:
        _startTime = const TimeOfDay(hour: 8, minute: 0);
        _endTime = const TimeOfDay(hour: 16, minute: 0);
        break;
      case ShiftType.AFTERNOON:
        _startTime = const TimeOfDay(hour: 10, minute: 0);
        _endTime = const TimeOfDay(hour: 15, minute: 0);
        break;
      case ShiftType.EVENING:
        _startTime = const TimeOfDay(hour: 17, minute: 0);
        _endTime = const TimeOfDay(hour: 22, minute: 0);
        break;
      case ShiftType.NIGHT:
        _startTime = const TimeOfDay(hour: 22, minute: 0);
        _endTime = const TimeOfDay(hour: 6, minute: 0);
        break;
      case ShiftType.FULL_DAY:
        _startTime = const TimeOfDay(hour: 8, minute: 0);
        _endTime = const TimeOfDay(hour: 22, minute: 0);
        break;
    }
    setState(() {});
  }
}

// Shift Details Bottom Sheet (unchanged)
class ShiftDetailsSheet extends StatelessWidget {
  final KitchenShift shift;

  const ShiftDetailsSheet({super.key, required this.shift});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shift Details',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kprimaryTextColor1,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildDetailRow('Employee', shift.employee.fullName),
          _buildDetailRow('Date', shift.formattedDate),
          _buildDetailRow('Shift Type', shift.shiftTypeDisplay),
          _buildDetailRow('Time', shift.formattedTimeRange),
          if (shift.notes != null && shift.notes!.isNotEmpty)
            _buildDetailRow('Notes', shift.notes!),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
