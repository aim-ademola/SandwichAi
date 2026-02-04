import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base-repo.dart';
import 'package:sandwich_ai/src/features/kitchen/data/model/kitchen_shift_model.dart';

abstract class KitchenShiftRepositoryInterface {
  Future<ApiResponse<List<KitchenShift>>> getKitchenShifts({
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
  });

  Future<ApiResponse<KitchenShift>> createKitchenShift({
    required CreateKitchenShiftRequest request,
  });

  Future<ApiResponse<KitchenShift>> updateKitchenShift({
    required String shiftId,
    required UpdateKitchenShiftRequest request,
  });

  Future<ApiResponse<void>> deleteKitchenShift({required String shiftId});

  Future<ApiResponse<List<Employee>>> getKitchenEmployees({
    required String branchId,
  });
}

class KitchenShiftRepository extends BaseRepository
    implements KitchenShiftRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<List<KitchenShift>>> getKitchenShifts({
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
  }) async {
    try {
      _validateBranchId(branchId);

      final queryParams = <String, dynamic>{'branchId': branchId};

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }

      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      if (employeeId != null && employeeId.isNotEmpty) {
        queryParams['employeeId'] = employeeId;
      }

      final listResponse = await handleListResponse<KitchenShift>(
        _apiClient
            .get('kitchen/shifts', queryParameters: queryParams)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Request timed out. Please try again.');
              },
            )
            .then((response) => ApiResponse.success(response.data)),
        (json) => KitchenShift.fromJson(json),
      );

      return listResponse;
    } on SocketException catch (e) {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
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
  Future<ApiResponse<KitchenShift>> createKitchenShift({
    required CreateKitchenShiftRequest request,
  }) async {
    try {
      _validateBranchId(request.branchId);
      _validateEmployeeId(request.employeeId);
      _validateShiftTimes(request.startTime, request.endTime);

      final response = await _apiClient
          .post('kitchen/shifts', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Invalid response from server');
      }

      return ApiResponse.success(KitchenShift.fromJson(response.data));
    } on SocketException catch (e) {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
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
  Future<ApiResponse<KitchenShift>> updateKitchenShift({
    required String shiftId,
    required UpdateKitchenShiftRequest request,
  }) async {
    try {
      if (shiftId.isEmpty) {
        throw FormatException('Shift ID cannot be empty');
      }

      if (request.startTime != null && request.endTime != null) {
        _validateShiftTimes(request.startTime!, request.endTime!);
      }

      final response = await _apiClient
          .patch('kitchen/shifts/$shiftId', data: request.toJson())
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      if (response.data == null) {
        return ApiResponse.errorMessage('Invalid response from server');
      }

      return ApiResponse.success(KitchenShift.fromJson(response.data));
    } on SocketException catch (e) {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
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
  Future<ApiResponse<void>> deleteKitchenShift({
    required String shiftId,
  }) async {
    try {
      if (shiftId.isEmpty) {
        throw FormatException('Shift ID cannot be empty');
      }

      await _apiClient
          .delete('kitchen/shifts/$shiftId')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return ApiResponse.success(null);
    } on SocketException catch (e) {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException catch (e) {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  @override
  Future<ApiResponse<List<Employee>>> getKitchenEmployees({
    required String branchId,
  }) async {
    try {
      _validateBranchId(branchId);

      final response = await _apiClient
          .get(
            'Employees/branches/$branchId/departments/KITCHEN/employees',
            queryParameters: {'status': 'ACTIVE', 'page': 1, 'limit': 100},
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      final body = response.data;

      if (body == null || body['data'] == null) {
        return ApiResponse.errorMessage('Invalid response from server');
      }

      final employees = (body['data'] as List)
          .map((e) => Employee.fromJson(e))
          .toList();

      return ApiResponse.success(employees);
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  void _validateBranchId(String branchId) {
    if (branchId.isEmpty) {
      throw FormatException('Branch ID cannot be empty');
    }
  }

  void _validateEmployeeId(String employeeId) {
    if (employeeId.isEmpty) {
      throw FormatException('Employee ID cannot be empty');
    }
  }

  void _validateShiftTimes(String startTime, String endTime) {
    try {
      final start = DateTime.parse('1970-01-01 $startTime');
      final end = DateTime.parse('1970-01-01 $endTime');

      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        throw FormatException('End time must be after start time');
      }
    } catch (e) {
      throw FormatException('Invalid time format');
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
      return 'Shift not found.';
    }

    if (lowercaseError.contains('409') || lowercaseError.contains('conflict')) {
      return 'Shift conflict detected. Employee may already have a shift during this time.';
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

    return 'Failed to process shift. Please try again later.';
  }
}
