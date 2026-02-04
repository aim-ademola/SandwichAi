import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/processing/data/model/processing_task_model.dart';

abstract class ProcessingTaskState extends Equatable {
  const ProcessingTaskState();

  @override
  List<Object?> get props => [];
}

class ProcessingTaskInitial extends ProcessingTaskState {
  const ProcessingTaskInitial();
}

class ProcessingTaskLoading extends ProcessingTaskState {
  const ProcessingTaskLoading();
}

class ProcessingTasksLoaded extends ProcessingTaskState {
  final List<ProcessingTask> tasks;
  final List<ProcessingTask> filteredTasks;
  final String? currentStatus;
  final String? currentAssignedStaff;

  const ProcessingTasksLoaded({
    required this.tasks,
    required this.filteredTasks,
    this.currentStatus,
    this.currentAssignedStaff,
  });

  ProcessingTasksLoaded copyWith({
    List<ProcessingTask>? tasks,
    List<ProcessingTask>? filteredTasks,
    String? currentStatus,
    String? currentAssignedStaff,
  }) {
    return ProcessingTasksLoaded(
      tasks: tasks ?? this.tasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      currentStatus: currentStatus ?? this.currentStatus,
      currentAssignedStaff: currentAssignedStaff ?? this.currentAssignedStaff,
    );
  }

  @override
  List<Object?> get props => [
    tasks,
    filteredTasks,
    currentStatus,
    currentAssignedStaff,
  ];
}

class ProcessingTaskSubmitting extends ProcessingTaskState {
  const ProcessingTaskSubmitting();
}

class ProcessingTaskSuccess extends ProcessingTaskState {
  final ProcessingTask task;
  final String message;

  const ProcessingTaskSuccess({required this.task, required this.message});

  @override
  List<Object?> get props => [task, message];
}

class ProcessingTaskDeleted extends ProcessingTaskState {
  final String message;

  const ProcessingTaskDeleted({required this.message});

  @override
  List<Object?> get props => [message];
}

enum ProcessingTaskErrorType { network, timeout, server, validation, general }

class ProcessingTaskError extends ProcessingTaskState {
  final String error;
  final ProcessingTaskErrorType errorType;

  const ProcessingTaskError({required this.error, required this.errorType});

  @override
  List<Object?> get props => [error, errorType];
}
