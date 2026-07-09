// data/repo/employee_repo.dart

import 'dart:async';
import 'dart:io';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/model/product_intake_model.dart';

abstract class EmployeeRepositoryInterface {
  Future<ApiResponse<EmployeesResponse>> getEmployeesByDepartment({
    required String branchId,
    required String department,
    String? role,
    String? status,
    String? search,
  });
}

class EmployeeRepository extends BaseRepository
    implements EmployeeRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<EmployeesResponse>> getEmployeesByDepartment({
    required String branchId,
    required String department,
    String? role,
    String? status,
    String? search,
  }) async {
    try {
      // Build query parameters
      final queryParameters = <String, dynamic>{};
      if (role != null) queryParameters['role'] = role;
      if (status != null) queryParameters['status'] = status;
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _apiClient
          .get(
            'Employees/branches/$branchId/departments/$department/employees',
            queryParameters: queryParameters.isNotEmpty
                ? queryParameters
                : null,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out. Please try again.');
            },
          );

      return response.when(
        success: (data) {
          try {
            final employeesResponse = EmployeesResponse.fromJson(
              data as Map<String, dynamic>,
            );
            return ApiResponse.success(employeesResponse);
          } catch (e) {
            return ApiResponse.error(
              NetworkException.formatException('Failed to parse employees: $e'),
            );
          }
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
    } catch (e) {
      return ApiResponse.errorMessage(
        'Failed to load employees. Please try again later.',
      );
    }
  }
}
