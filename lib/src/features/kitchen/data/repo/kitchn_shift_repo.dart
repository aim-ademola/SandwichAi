import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/data/repo/employee_lookup_repo.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/model/product_intake_model.dart'
    as processing;
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
  final EmployeeLookupRepositoryInterface _employeeLookupRepository;

  KitchenShiftRepository({
    EmployeeLookupRepositoryInterface? employeeLookupRepository,
  }) : _employeeLookupRepository =
           employeeLookupRepository ?? EmployeeLookupRepository();

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
        queryParams['startDate'] = _formatDateParam(startDate);
      }

      if (endDate != null) {
        queryParams['endDate'] = _formatDateParam(endDate);
      }

      if (employeeId != null && employeeId.isNotEmpty) {
        queryParams['employeeId'] = employeeId;
      }

      final response = await _apiClient
          .get('kitchen/shifts', queryParameters: queryParams)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (body) {
          final shiftList = _extractList(body);
          if (shiftList == null) {
            return ApiResponse.errorMessage('Invalid response from server');
          }

          final shifts = shiftList
              .whereType<Map>()
              .map((e) => KitchenShift.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          return ApiResponse.success(shifts);
        },
        error: (error) => ApiResponse.error(error),
      );
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

      return response.when(
        success: (data) {
          final shiftJson = _extractObject(data);
          if (shiftJson == null) {
            return ApiResponse.errorMessage('Invalid response from server');
          }
          return ApiResponse.success(KitchenShift.fromJson(shiftJson));
        },
        error: (error) => ApiResponse.error(error),
      );
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

      return response.when(
        success: (data) {
          final shiftJson = _extractObject(data);
          if (shiftJson == null) {
            return ApiResponse.errorMessage('Invalid response from server');
          }
          return ApiResponse.success(KitchenShift.fromJson(shiftJson));
        },
        error: (error) => ApiResponse.error(error),
      );
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
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage(
        'Connection timeout. Please check your internet and try again.',
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  @override
  Future<ApiResponse<List<Employee>>> getKitchenEmployees({
    required String branchId,
  }) async {
    try {
      _validateBranchId(branchId);

      final response = await _employeeLookupRepository
          .getEmployeesByDepartment(
            branchId: branchId,
            department: 'KITCHEN',
            status: 'ACTIVE',
          );

      return response.when(
        success: (employeesResponse) => ApiResponse.success(
          employeesResponse.data.map(_toKitchenEmployee).toList(),
        ),
        error: (error) => ApiResponse.error(error),
      );
    } catch (e) {
      return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
    }
  }

  Employee _toKitchenEmployee(processing.Employee employee) {
    return Employee.fromJson({
      'id': employee.id,
      'employeeId': employee.employeeId,
      'firstName': employee.firstName,
      'lastName': employee.lastName,
      'email': employee.email,
      'phone': employee.phone,
      'address': employee.address,
      'dateOfBirth': employee.dateOfBirth.toIso8601String(),
      'role': employee.role,
      'department': employee.department,
      'isDepartmentManager': employee.isDepartmentManager,
      'status': employee.status.name.toUpperCase(),
      'hireDate': employee.hireDate.toIso8601String(),
      'terminationDate': employee.terminationDate?.toIso8601String(),
      'lastLogin': employee.lastLogin.toIso8601String(),
      'emergencyContactName': employee.emergencyContactName,
      'emergencyContactPhone': employee.emergencyContactPhone,
      'emergencyContactRelation': employee.emergencyContactRelation,
      'organizationId': employee.organizationId,
      'branchId': employee.branchId,
      'createdAt': employee.createdAt.toIso8601String(),
      'updatedAt': employee.updatedAt.toIso8601String(),
    });
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

  String _formatDateParam(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
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

  Map<String, dynamic>? _extractObject(dynamic body) {
    if (body is Map<String, dynamic>) {
      final nested = body['data'] ?? body['shift'];
      if (nested is Map<String, dynamic>) return nested;
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return body;
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return null;
  }

  List<dynamic>? _extractList(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return null;

    dynamic current = body;
    for (final key in const ['data', 'employees', 'items', 'results']) {
      if (current is Map && current[key] is List) {
        return current[key] as List;
      }
    }

    final data = body['data'];
    if (data is Map) {
      for (final key in const ['employees', 'items', 'results', 'data']) {
        if (data[key] is List) return data[key] as List;
      }
    }

    return null;
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
