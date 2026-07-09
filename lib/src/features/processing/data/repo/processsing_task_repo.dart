import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/model/processing_task_model.dart';

abstract class ProcessingTaskRepositoryInterface {
  Future<ApiResponse<List<ProcessingTask>>> getProcessingTasks({
    required String branchId,
    String? assignedStaff,
    String? status,
  });

  Future<ApiResponse<ProcessingTask>> createProcessingTask({
    required CreateProcessingTaskRequest request,
  });

  Future<ApiResponse<ProcessingTask>> updateProcessingTask({
    required String taskId,
    required UpdateProcessingTaskRequest request,
  });

  Future<ApiResponse<bool>> deleteProcessingTask({required String taskId});
}

class ProcessingTaskRepository extends BaseRepository
    implements ProcessingTaskRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<List<ProcessingTask>>> getProcessingTasks({
    required String branchId,
    String? assignedStaff,
    String? status,
  }) async {
    try {
      _validateBranchId(branchId);

      final queryParams = <String, dynamic>{'branchId': branchId};

      if (assignedStaff != null && assignedStaff.isNotEmpty) {
        queryParams['assignedStaff'] = assignedStaff;
      }

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final listResponse = await handleListResponse<ProcessingTask>(
        _apiClient
            .get('processing/tasks', queryParameters: queryParams)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Request timed out. Please try again.');
              },
            )
            .then((response) => ApiResponse.success(response.data)),
        (json) => ProcessingTask.fromJson(json),
      );

      return listResponse;
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<ProcessingTask>> createProcessingTask({
    required CreateProcessingTaskRequest request,
  }) async {
    try {
      _validateBranchId(request.branchId);
      _validateRecipeId(request.recipeId);
      _validateMenuItemId(request.menuItemId);
      _validateAssignedStaff(request.assignedStaff);
      _validateBatchesRequested(request.batchesRequested);
      _validatePriority(request.priority);

      final response = await _apiClient
          .post('processing/tasks', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Invalid response from server');
      }

      return ApiResponse.success(ProcessingTask.fromJson(response.data));
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<ProcessingTask>> updateProcessingTask({
    required String taskId,
    required UpdateProcessingTaskRequest request,
  }) async {
    try {
      if (taskId.isEmpty) {
        throw FormatException('Task ID cannot be empty');
      }

      if (request.batchesCompleted != null) {
        _validateBatchesCompleted(request.batchesCompleted!);
      }

      final response = await _apiClient
          .patch('processing/tasks/$taskId', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Invalid response from server');
      }

      return ApiResponse.success(ProcessingTask.fromJson(response.data));
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      return ApiResponse.errorMessage(e.message);
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<bool>> deleteProcessingTask({
    required String taskId,
  }) async {
    try {
      if (taskId.isEmpty) {
        throw FormatException('Task ID cannot be empty');
      }

      AppLogger.log('🗑️ Repository: Starting delete for task: $taskId');

      final response = await _apiClient
          .delete('processing/tasks/$taskId')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              AppLogger.log(' Repository: Delete timed out');
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      AppLogger.log(' Repository: Delete completed');
      AppLogger.log('   Data: ${response.data}');

      // Return true instead of null to avoid null check error in ApiResponse.when()
      return ApiResponse.success(true);
    } on SocketException catch (e) {
      AppLogger.log(' Repository: SocketException - $e');
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      AppLogger.log(' Repository: TimeoutException - $e');
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } on FormatException catch (e) {
      AppLogger.log(' Repository: FormatException - ${e.message}');
      return ApiResponse.errorMessage(e.message);
    } catch (e, stackTrace) {
      AppLogger.log(' Repository: Unexpected exception');
      AppLogger.log('   Error: $e');
      AppLogger.log('   Type: ${e.runtimeType}');
      AppLogger.log(
        '   Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}',
      );
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  // Validation methods
  void _validateBranchId(String branchId) {
    if (branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }
  }

  void _validateRecipeId(String recipeId) {
    if (recipeId.isEmpty) {
      throw FormatException('Recipe ID cannot be empty');
    }
  }

  void _validateMenuItemId(String menuItemId) {
    if (menuItemId.isEmpty) {
      throw FormatException('Menu Item ID cannot be empty');
    }
  }

  void _validateAssignedStaff(String assignedStaff) {
    if (assignedStaff.isEmpty) {
      throw FormatException('Assigned staff cannot be empty');
    }
  }

  void _validateBatchesRequested(int batchesRequested) {
    if (batchesRequested <= 0) {
      throw FormatException('Batches requested must be greater than 0');
    }
  }

  void _validateBatchesCompleted(int batchesCompleted) {
    if (batchesCompleted < 0) {
      throw FormatException('Batches completed cannot be negative');
    }
  }

  void _validatePriority(int priority) {
    if (priority < 1 || priority > 3) {
      throw FormatException('Priority must be between 1 and 3');
    }
  }

  String _parseErrorMessage(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('401') ||
        lowercaseError.contains('unauthorized')) {
      return 'Unauthorized access. Please login again.';
    }

    if (lowercaseError.contains('403') ||
        lowercaseError.contains('forbidden')) {
      return 'Access denied. Please contact support.';
    }

    if (lowercaseError.contains('404') ||
        lowercaseError.contains('not found')) {
      return 'Task not found.';
    }

    if (lowercaseError.contains('409') || lowercaseError.contains('conflict')) {
      return 'Task conflict detected. Please check task details.';
    }

    if (lowercaseError.contains('500') ||
        lowercaseError.contains('internal server')) {
      return 'Server error. Please try again later.';
    }

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection')) {
      return 'Network error. Please check your connection.';
    }

    if (lowercaseError.contains('timeout')) {
      return 'Request timeout. Please try again.';
    }

    return 'Failed to process task. Please try again later.';
  }
}
