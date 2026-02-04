import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/pos/data/model/staffmember_model.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_staff_screen.dart';

enum Priority { normal, high, urgent }

class PosAssignTaskScreen extends StatefulWidget {
  final StaffMember staff;

  const PosAssignTaskScreen({super.key, required this.staff});

  @override
  State<PosAssignTaskScreen> createState() => _PosAssignTaskScreenState();
}

class _PosAssignTaskScreenState extends State<PosAssignTaskScreen> {
  final TextEditingController _taskController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  Priority _selectedPriority = Priority.normal;

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    //the date dynamically adjust yearly. in 2025 it captures the remining months and in 2026 it capture everything to nov 2026, since we are also in nov 2025 atm. when we get to 2026 it adjust. so its a ll dynamic based on a year diff
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              onSurface: kprimaryTextColor1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: kPrimary,
                onPrimary: Colors.white,
                onSurface: kprimaryTextColor1,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _assignTask() {
    if (_taskController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add a task description',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Task Assigned Successfully',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The task has been assigned to ${widget.staff.name}',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to staff list
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Done',
                textAlign: TextAlign.center,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            children: [
              Text(
                'Assign Task',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kprimaryTextColor1,
                ),
              ),
              Text(
                'Manager View',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: kprimaryTextColor2,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Assigning to header
              Text(
                'Assigning to : ${widget.staff.name}',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kprimaryTextColor1,
                ),
              ),
              const SizedBox(height: 20),
              // Task input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _taskController,
                  cursorColor: kPrimary,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Add custom task...',
                    hintStyle: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: kprimaryTextColor2,
                    ),
                    border: InputBorder.none,
                  ),
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: kprimaryTextColor1,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Set Details header
              Text(
                'Set Details',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kprimaryTextColor1,
                ),
              ),
              const SizedBox(height: 16),
              // Due Date & Time
              Text(
                'Due Date & Time',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kprimaryTextColor1,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDateTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Row(
                    children: [
                      Text(
                        DateFormat(
                          'MMM dd, yyyy \'at\' h:mm a',
                        ).format(_selectedDateTime),
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          color: kprimaryTextColor1,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: kprimaryTextColor2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Priority
              Text(
                'Priority',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kprimaryTextColor1,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPriorityChip(
                    label: 'Normal',
                    priority: Priority.normal,
                  ),
                  const SizedBox(width: 12),
                  _buildPriorityChip(label: 'High', priority: Priority.high),
                  const SizedBox(width: 12),
                  _buildPriorityChip(
                    label: 'Urgent',
                    priority: Priority.urgent,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kprimaryTextColor1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _assignTask,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Assign Tasks',
                          textAlign: TextAlign.center,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
    );
  }

  Widget _buildPriorityChip({
    required String label,
    required Priority priority,
  }) {
    final isSelected = _selectedPriority == priority;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = priority),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? kPrimary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? kPrimary : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : kprimaryTextColor1,
            ),
          ),
        ),
      ),
    );
  }
}
