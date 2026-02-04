// bloc/processing_task_bloc/event.dart

import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/processing/data/model/processing_task_model.dart';

abstract class ProcessingTaskEvent extends Equatable {
  const ProcessingTaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadProcessingTasks extends ProcessingTaskEvent {
  final String? assignedStaff;
  final String? status;

  const LoadProcessingTasks({this.assignedStaff, this.status});

  @override
  List<Object?> get props => [assignedStaff, status];
}

class CreateProcessingTask extends ProcessingTaskEvent {
  final CreateProcessingTaskRequest request;

  const CreateProcessingTask({required this.request});

  @override
  List<Object?> get props => [request];
}

class UpdateProcessingTask extends ProcessingTaskEvent {
  final String taskId;
  final UpdateProcessingTaskRequest request;

  const UpdateProcessingTask({required this.taskId, required this.request});

  @override
  List<Object?> get props => [taskId, request];
}

class DeleteProcessingTask extends ProcessingTaskEvent {
  final String taskId;

  const DeleteProcessingTask({required this.taskId});

  @override
  List<Object?> get props => [taskId];
}

class FilterProcessingTasks extends ProcessingTaskEvent {
  final String? status;
  final String? assignedStaff;

  const FilterProcessingTasks({this.status, this.assignedStaff});

  @override
  List<Object?> get props => [status, assignedStaff];
}

class ResetProcessingTask extends ProcessingTaskEvent {
  const ResetProcessingTask();
}
