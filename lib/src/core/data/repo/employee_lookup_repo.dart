import 'dart:async';
import 'dart:io';

import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/base_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/model/product_intake_model.dart';

abstract class EmployeeLookupRepositoryInterface {
  Future<ApiResponse<EmployeesResponse>> getEmployeesByDepartment({
    required String branchId,
    required String department,
    String? role,
    String? status,
    String? search,
  });
}

class EmployeeLookupRepository extends BaseRepository
    implements EmployeeLookupRepositoryInterface {
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
      if (branchId.isEmpty) {
        return ApiResponse.errorMessage('Branch ID cannot be empty.');
      }
      if (department.isEmpty) {
        return ApiResponse.errorMessage('Department cannot be empty.');
      }

      final queryParameters = <String, dynamic>{};
      if (role != null && role.isNotEmpty) queryParameters['role'] = role;
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
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
            final json = data is Map
                ? Map<String, dynamic>.from(data)
                : <String, dynamic>{};
            return ApiResponse.success(EmployeesResponse.fromJson(json));
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
