import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_task_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_task_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/processing_task_model.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/processsing_task_repo.dart';

class ProcessingTaskBloc
    extends Bloc<ProcessingTaskEvent, ProcessingTaskState> {
  final ProcessingTaskRepositoryInterface _repository;
  String branchId = '';

  ProcessingTaskBloc({required ProcessingTaskRepositoryInterface repository})
    : _repository = repository,
      super(const ProcessingTaskInitial()) {
    _getBranchId();
    on<LoadProcessingTasks>(_onLoadProcessingTasks);
    on<CreateProcessingTask>(_onCreateProcessingTask);
    on<UpdateProcessingTask>(_onUpdateProcessingTask);
    on<DeleteProcessingTask>(_onDeleteProcessingTask);
    on<FilterProcessingTasks>(_onFilterProcessingTasks);
    on<ResetProcessingTask>(_onResetProcessingTask);
  }

  /// Get branch ID from cache
  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  /// Load processing tasks
  Future<void> _onLoadProcessingTasks(
    LoadProcessingTasks event,
    Emitter<ProcessingTaskState> emit,
  ) async {
    try {
      emit(const ProcessingTaskLoading());

      final response = await _repository.getProcessingTasks(
        branchId: branchId,
        assignedStaff: event.assignedStaff,
        status: event.status,
      );

      await response.when(
        success: (data) async {
          if (data.isEmpty) {
            emit(const ProcessingTasksLoaded(tasks: [], filteredTasks: []));
            return;
          }

          emit(
            ProcessingTasksLoaded(
              tasks: data,
              filteredTasks: data,
              currentStatus: event.status,
              currentAssignedStaff: event.assignedStaff,
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            ProcessingTaskError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const ProcessingTaskError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: ProcessingTaskErrorType.general,
        ),
      );
    }
  }

  /// Create processing task
  Future<void> _onCreateProcessingTask(
    CreateProcessingTask event,
    Emitter<ProcessingTaskState> emit,
  ) async {
    try {
      emit(const ProcessingTaskSubmitting());

      final response = await _repository.createProcessingTask(
        request: event.request,
      );

      await response.when(
        success: (data) async {
          emit(
            ProcessingTaskSuccess(
              task: data,
              message: 'Processing task created successfully!',
            ),
          );

          // Reload tasks after creation
          add(const LoadProcessingTasks());
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            ProcessingTaskError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const ProcessingTaskError(
          error: 'Failed to create processing task. Please try again.',
          errorType: ProcessingTaskErrorType.general,
        ),
      );
    }
  }

  /// Update processing task
  Future<void> _onUpdateProcessingTask(
    UpdateProcessingTask event,
    Emitter<ProcessingTaskState> emit,
  ) async {
    try {
      emit(const ProcessingTaskSubmitting());

      final response = await _repository.updateProcessingTask(
        taskId: event.taskId,
        request: event.request,
      );

      await response.when(
        success: (data) async {
          emit(
            ProcessingTaskSuccess(
              task: data,
              message: 'Processing task updated successfully!',
            ),
          );

          // Small delay to allow success message to be shown
          await Future.delayed(const Duration(milliseconds: 500));

          // Reload tasks after update
          add(const LoadProcessingTasks());
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            ProcessingTaskError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e) {
      emit(
        const ProcessingTaskError(
          error: 'Failed to update processing task. Please try again.',
          errorType: ProcessingTaskErrorType.general,
        ),
      );
    }
  }

  /// Delete processing task
  Future<void> _onDeleteProcessingTask(
    DeleteProcessingTask event,
    Emitter<ProcessingTaskState> emit,
  ) async {
    try {
      // Emit loading state for delete
      emit(const ProcessingTaskSubmitting());

      print('🗑️ BLoC: Starting delete for task ${event.taskId}');

      final response = await _repository.deleteProcessingTask(
        taskId: event.taskId,
      );

      print('🗑️ BLoC: Delete response received');

      await response.when(
        success: (_) async {
          print('✅ BLoC: Delete successful, emitting success state');

          emit(
            const ProcessingTaskDeleted(message: 'Task deleted successfully!'),
          );

          print('✅ BLoC: Success state emitted, waiting before reload');

          // Small delay before reloading
          await Future.delayed(const Duration(milliseconds: 500));

          print('🔄 BLoC: Triggering reload');

          // Reload tasks after deletion
          add(const LoadProcessingTasks());
        },
        error: (error) async {
          print('❌ BLoC: Delete error - $error');
          final errorType = _determineErrorType(error.toString());
          emit(
            ProcessingTaskError(error: error.toString(), errorType: errorType),
          );
        },
      );
    } catch (e, stackTrace) {
      print('❌ BLoC: Delete exception caught');
      print('   Error: $e');
      print('   Type: ${e.runtimeType}');
      print('   Stack trace:');
      print('   ${stackTrace.toString().split('\n').take(10).join('\n   ')}');

      emit(
        const ProcessingTaskError(
          error: 'Failed to delete processing task. Please try again.',
          errorType: ProcessingTaskErrorType.general,
        ),
      );
    }
  }

  /// Filter processing tasks
  void _onFilterProcessingTasks(
    FilterProcessingTasks event,
    Emitter<ProcessingTaskState> emit,
  ) {
    if (state is! ProcessingTasksLoaded) return;

    final currentState = state as ProcessingTasksLoaded;
    final filteredTasks = _filterTasks(
      currentState.tasks,
      event.status,
      event.assignedStaff,
    );

    emit(
      currentState.copyWith(
        filteredTasks: filteredTasks,
        currentStatus: event.status,
        currentAssignedStaff: event.assignedStaff,
      ),
    );
  }

  /// Reset to initial state
  void _onResetProcessingTask(
    ResetProcessingTask event,
    Emitter<ProcessingTaskState> emit,
  ) {
    emit(const ProcessingTaskInitial());
  }

  /// Filter tasks by status and assigned staff
  List<ProcessingTask> _filterTasks(
    List<ProcessingTask> tasks,
    String? status,
    String? assignedStaff,
  ) {
    var filtered = tasks;

    if (status != null && status.isNotEmpty && status != 'ALL') {
      filtered = filtered.where((task) => task.status == status).toList();
    }

    if (assignedStaff != null && assignedStaff.isNotEmpty) {
      filtered = filtered
          .where(
            (task) => task.assignedStaff.toLowerCase().contains(
              assignedStaff.toLowerCase(),
            ),
          )
          .toList();
    }

    return filtered;
  }

  /// Determine error type from error message
  ProcessingTaskErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return ProcessingTaskErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return ProcessingTaskErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return ProcessingTaskErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return ProcessingTaskErrorType.validation;
    }

    return ProcessingTaskErrorType.general;
  }
}
