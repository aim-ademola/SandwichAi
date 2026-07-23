import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_task_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_task_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_task_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/processing_task_model.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';

class ProcessingTaskHistoryScreen extends StatefulWidget {
  const ProcessingTaskHistoryScreen({super.key});

  @override
  State<ProcessingTaskHistoryScreen> createState() =>
      _ProcessingTaskHistoryScreenState();
}

class _ProcessingTaskHistoryScreenState
    extends State<ProcessingTaskHistoryScreen> {
  String _selectedStatus = 'ALL';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProcessingTaskBloc>().add(const LoadProcessingTasks());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        backgroundColor: isError ? context.modeError : kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showTaskDetailsBottomSheet(ProcessingTask task, double screenWidth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTaskDetailsSheet(task, screenWidth),
    );
  }

  void _showUpdateTaskDialog(ProcessingTask task, double screenWidth) {
    // Debug: Print the actual status value
    AppLogger.log(' Task status from API: "${task.status}"');

    // Normalize the status to match dropdown values
    String selectedStatus = task.status.toUpperCase().trim();

    // Ensure the status is one of the valid dropdown options
    final validStatuses = [
      'PENDING_PROCESS',
      'IN_PROCESS',
      'COMPLETED',
      'CANCELLED',
    ];
    if (!validStatuses.contains(selectedStatus)) {
      AppLogger.log(
        'Status "$selectedStatus" not in valid list, defaulting to PENDING_PROCESS',
      );
      // Default to PENDING if status is not recognized
      selectedStatus = 'PENDING_PROCESS';
    } else {
      AppLogger.log(' Status "$selectedStatus" is valid');
    }

    final batchesCompletedController = TextEditingController(
      text: task.batchesCompleted.toString(),
    );
    final notesController = TextEditingController(text: task.notes ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
          ),
          title: Text(
            'Update Task',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getSectionTitleFontSize(screenWidth),
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getLabelFontSize(screenWidth),
                    fontWeight: FontWeight.w500,
                    color: context.modeTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.modeSurface,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        _getBorderRadius(screenWidth),
                      ),
                      borderSide: const BorderSide(color: kPrimary),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        _getBorderRadius(screenWidth),
                      ),
                      borderSide: BorderSide(color: context.modeBorder),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: _getInputPaddingHorizontal(screenWidth),
                      vertical: _getInputPaddingVertical(screenWidth),
                    ),
                  ),
                  items: validStatuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(
                            _formatStatus(status),
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: _getInputFontSize(screenWidth),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Batches Completed',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getLabelFontSize(screenWidth),
                    fontWeight: FontWeight.w500,
                    color: context.modeTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  cursorColor: kPrimary,
                  controller: batchesCompletedController,
                  keyboardType: TextInputType.number,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getInputFontSize(screenWidth),
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.modeSurface,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        _getBorderRadius(screenWidth),
                      ),
                      borderSide: const BorderSide(color: kPrimary),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        _getBorderRadius(screenWidth),
                      ),
                      borderSide: BorderSide(color: context.modeBorder),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: _getInputPaddingHorizontal(screenWidth),
                      vertical: _getInputPaddingVertical(screenWidth),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Notes',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getLabelFontSize(screenWidth),
                    fontWeight: FontWeight.w500,
                    color: context.modeTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  cursorColor: kPrimary,
                  controller: notesController,
                  maxLines: 3,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getInputFontSize(screenWidth),
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.modeSurface,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        _getBorderRadius(screenWidth),
                      ),
                      borderSide: const BorderSide(color: kPrimary),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        _getBorderRadius(screenWidth),
                      ),
                      borderSide: BorderSide(color: context.modeBorder),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: _getInputPaddingHorizontal(screenWidth),
                      vertical: _getInputPaddingVertical(screenWidth),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getInputFontSize(screenWidth),
                  color: context.modeTextSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final batchesCompleted =
                    int.tryParse(batchesCompletedController.text) ?? 0;

                final request = UpdateProcessingTaskRequest(
                  status: selectedStatus,
                  batchesCompleted: batchesCompleted,
                  actualCompletionTime: selectedStatus == 'COMPLETED'
                      ? DateTime.now()
                      : null,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                );

                context.read<ProcessingTaskBloc>().add(
                  UpdateProcessingTask(taskId: task.id, request: request),
                );
                context.read<ProcessingTaskBloc>().add(
                  const LoadProcessingTasks(),
                );
                Navigator.pop(dialogContext);
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
                'Update',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getInputFontSize(screenWidth),
                  color: context.modeTextInverse,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String taskId, double screenWidth) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        ),
        title: Text(
          'Delete Task',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getSectionTitleFontSize(screenWidth),
            fontWeight: FontWeight.w600,
            color: context.modeTextPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth),
            color: context.modeTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                color: context.modeTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProcessingTaskBloc>().add(
                DeleteProcessingTask(taskId: taskId),
              );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.modeError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  _getBorderRadius(screenWidth),
                ),
              ),
            ),
            child: Text(
              'Delete',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                color: context.modeSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProcessingTaskBloc, ProcessingTaskState>(
      listener: (context, state) {
        if (state is ProcessingTaskSuccess) {
          _showSnackBar(state.message);
          // Don't reload here - BLoC already triggers reload after update
        } else if (state is ProcessingTaskDeleted) {
          _showSnackBar(state.message);
          // Don't reload here - BLoC already triggers reload after delete
        } else if (state is ProcessingTaskError) {
          _showSnackBar(state.error, isError: true);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final horizontalPadding = _getHorizontalPadding(screenWidth);

          return Column(
            children: [
              Container(
                color: context.modeBackground,
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  children: [
                    _buildSearchBar(screenWidth),
                    const SizedBox(height: 12),
                    _buildStatusFilter(screenWidth),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<ProcessingTaskBloc, ProcessingTaskState>(
                  builder: (context, state) {
                    if (state is ProcessingTaskLoading) {
                      return shimmerCatalogCard(screenWidth);
                    }

                    if (state is ProcessingTasksLoaded) {
                      if (state.filteredTasks.isEmpty) {
                        return _buildEmptyState(screenWidth);
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<ProcessingTaskBloc>().add(
                            const LoadProcessingTasks(),
                          );
                        },
                        color: kPrimary,
                        child: ListView.builder(
                          padding: EdgeInsets.all(horizontalPadding),
                          itemCount: state.filteredTasks.length,
                          itemBuilder: (context, index) {
                            return _buildTaskCard(
                              state.filteredTasks[index],
                              screenWidth,
                            );
                          },
                        ),
                      );
                    }

                    if (state is ProcessingTaskError) {
                      return _buildErrorState(state.error, screenWidth);
                    }

                    return _buildEmptyState(screenWidth);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(double screenWidth) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {});
        context.read<ProcessingTaskBloc>().add(
          FilterProcessingTasks(
            status: _selectedStatus == 'ALL' ? null : _selectedStatus,
            assignedStaff: value.isNotEmpty ? value : null,
          ),
        );
      },
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: _getInputFontSize(screenWidth),
        color: context.modeTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Search tasks...',
        hintStyle: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getInputFontSize(screenWidth),
          color: context.modeTextSecondary,
        ),
        prefixIcon: AppIconSlot(
          Icons.search,
          color: context.modeTextSecondary,
          size: _getIconSize(screenWidth),
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: AppIcon(
                  Icons.clear,
                  color: context.modeTextSecondary,
                  size: _getIconSize(screenWidth),
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                  context.read<ProcessingTaskBloc>().add(
                    FilterProcessingTasks(
                      status: _selectedStatus == 'ALL' ? null : _selectedStatus,
                    ),
                  );
                },
              )
            : null,
        filled: true,
        fillColor: context.modeSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _getInputPaddingHorizontal(screenWidth),
          vertical: _getInputPaddingVertical(screenWidth),
        ),
      ),
    );
  }

  Widget _buildStatusFilter(double screenWidth) {
    final statuses = [
      'ALL',
      'PENDING',
      'IN_PROGRESS',
      'COMPLETED',
      'CANCELLED',
    ];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = _selectedStatus == status;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                _formatStatus(status),
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getCaptionFontSize(screenWidth),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? context.modeTextInverse
                      : context.modeTextSecondary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = status;
                });
                context.read<ProcessingTaskBloc>().add(
                  FilterProcessingTasks(
                    status: status == 'ALL' ? null : status,
                    assignedStaff: _searchController.text.isNotEmpty
                        ? _searchController.text
                        : null,
                  ),
                );
              },
              selectedColor: kPrimary,
              backgroundColor: context.modeSurface,
              checkmarkColor: context.modeTextInverse,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? kPrimary : context.modeBorder,
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(ProcessingTask task, double screenWidth) {
    return Card(
      color: context.modeSurface,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        side: BorderSide(color: context.modeBorder, width: 1),
      ),
      child: InkWell(
        onTap: () => _showTaskDetailsBottomSheet(task, screenWidth),
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        child: Padding(
          padding: EdgeInsets.all(_getInputPaddingHorizontal(screenWidth)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.recipeName,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getInputFontSize(screenWidth),
                        fontWeight: FontWeight.w600,
                        color: context.modeTextPrimary,
                      ),
                    ),
                  ),
                  _buildStatusChip(task.status, screenWidth),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.person,
                'Staff: ${task.assignedStaff}',
                screenWidth,
              ),
              const SizedBox(height: 4),
              _buildInfoRow(
                Icons.pie_chart,
                'Batches: ${task.batchesCompleted}/${task.batchesRequested}',
                screenWidth,
              ),
              const SizedBox(height: 4),
              _buildInfoRow(
                Icons.flag,
                'Priority: ${task.priorityDisplay}',
                screenWidth,
              ),
              const SizedBox(height: 4),
              _buildInfoRow(
                Icons.access_time,
                'Due: ${_formatDateTime(task.estimatedCompletionTime)}',
                screenWidth,
              ),
              // Only show action buttons if task is not completed
              if (task.status != 'COMPLETED') ...[
                const SizedBox(height: 12),
                BlocBuilder<ProcessingTaskBloc, ProcessingTaskState>(
                  builder: (context, state) {
                    final isLoading = state is ProcessingTaskSubmitting;

                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () =>
                                      _showUpdateTaskDialog(task, screenWidth),
                            icon: isLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        kPrimary.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  )
                                : const AppIcon(Icons.edit, size: 18),
                            label: Text(
                              'Update',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: _getCaptionFontSize(screenWidth),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimary,
                              side: BorderSide(color: kPrimary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  _getBorderRadius(screenWidth),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => _showDeleteConfirmation(
                                    task.id,
                                    screenWidth,
                                  ),
                            icon: isLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        const Color(
                                          0xFFE53935,
                                        ).withValues(alpha: 0.5),
                                      ),
                                    ),
                                  )
                                : const AppIcon(Icons.delete, size: 18),
                            label: Text(
                              'Delete',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: _getCaptionFontSize(screenWidth),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.modeError,
                              side: BorderSide(color: context.modeError),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  _getBorderRadius(screenWidth),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ] else ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: kGreen.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(
                        Icons.check_circle,
                        color: kGreen,
                        size: _getIconSize(screenWidth) - 4,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Task Completed',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: _getCaptionFontSize(screenWidth),
                          fontWeight: FontWeight.w600,
                          color: kGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskDetailsSheet(ProcessingTask task, double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_getBorderRadius(screenWidth)),
        ),
      ),
      padding: EdgeInsets.all(_getInputPaddingHorizontal(screenWidth)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.modeDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Task Details',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getSectionTitleFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Recipe Name', task.recipeName, screenWidth),
            _buildDetailRow('Assigned Staff', task.assignedStaff, screenWidth),
            _buildDetailRow('Status', _formatStatus(task.status), screenWidth),
            _buildDetailRow(
              'Batches',
              '${task.batchesCompleted}/${task.batchesRequested}',
              screenWidth,
            ),
            _buildDetailRow('Priority', task.priorityDisplay, screenWidth),
            _buildDetailRow(
              'Estimated Completion',
              _formatDateTime(task.estimatedCompletionTime),
              screenWidth,
            ),
            if (task.actualCompletionTime != null)
              _buildDetailRow(
                'Actual Completion',
                _formatDateTime(task.actualCompletionTime!),
                screenWidth,
              ),
            if (task.notes != null && task.notes!.isNotEmpty)
              _buildDetailRow('Notes', task.notes!, screenWidth),
            if (task.branch != null) ...[
              const SizedBox(height: 8),
              Text(
                'Branch Information',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getLabelFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Branch', task.branch!.name, screenWidth),
              _buildDetailRow('Location', task.branch!.city, screenWidth),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getCaptionFontSize(screenWidth),
                color: context.modeTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getCaptionFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, double screenWidth) {
    return Row(
      children: [
        AppIcon(
          icon,
          size: _getIconSize(screenWidth) - 4,
          color: context.modeTextSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getCaptionFontSize(screenWidth),
              color: context.modeTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, double screenWidth) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'COMPLETED':
        backgroundColor = kGreen.withValues(alpha: 0.1);
        textColor = kGreen;
        break;
      case 'IN_PROGRESS':
        backgroundColor = context.modeWarning.withValues(alpha: 0.1);
        textColor = context.modeWarning;
        break;
      case 'PENDING':
        backgroundColor = kPrimary.withValues(alpha: 0.1);
        textColor = kPrimary;
        break;
      case 'CANCELLED':
        backgroundColor = context.modeError.withValues(alpha: 0.1);
        textColor = context.modeError;
        break;
      default:
        backgroundColor = context.modeSurfaceAlt;
        textColor = context.modeTextMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _formatStatus(status),
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getCaptionFontSize(screenWidth),
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(
            Icons.inbox_outlined,
            size: 64,
            color: context.modeTextSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              fontWeight: FontWeight.w600,
              color: context.modeTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new task to get started',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getCaptionFontSize(screenWidth),
              color: context.modeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, double screenWidth) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_getInputPaddingHorizontal(screenWidth)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              Icons.error_outline,
              size: 64,
              color: context.modeError.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getCaptionFontSize(screenWidth),
                color: context.modeTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ProcessingTaskBloc>().add(
                  const LoadProcessingTasks(),
                );
              },
              icon: const AppIcon(Icons.refresh, size: 18),
              label: Text(
                'Retry',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getCaptionFontSize(screenWidth),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: context.modeTextInverse,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(screenWidth),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'ALL':
        return 'All';
      default:
        return status;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final date = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date at $time';
  }

  // Responsive sizing functions
  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
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

  double _getIconSize(double width) {
    if (width < 360) return 20;
    if (width < 600) return 22;
    return 24;
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
