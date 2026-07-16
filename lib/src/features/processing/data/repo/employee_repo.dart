import 'package:sandwich_ai/src/core/data/repo/employee_lookup_repo.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
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

class EmployeeRepository extends EmployeeLookupRepository
    implements EmployeeRepositoryInterface {
  EmployeeRepository();
}
