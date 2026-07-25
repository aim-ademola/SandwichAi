import 'dart:async';
import 'dart:io';

import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/branch_assignment_model.dart';

abstract class BranchAssignmentRepositoryInterface {
  Future<ApiResponse<ItemBranchAssignmentsResponse>> getItemBranchAssignments(
    String itemId,
  );
}

class BranchAssignmentRepository implements BranchAssignmentRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<ItemBranchAssignmentsResponse>> getItemBranchAssignments(
    String itemId,
  ) async {
    if (itemId.isEmpty) {
      return ApiResponse.errorMessage('Item ID cannot be empty.');
    }

    try {
      final response = await _apiClient
          .get('inventory-items/branch-assignment/$itemId/branches')
          .timeout(const Duration(seconds: 30));

      return response.when(
        success: (data) {
          final json = data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{'data': data};
          return ApiResponse.success(
            ItemBranchAssignmentsResponse.fromJson(json),
          );
        },
        error: (error) => ApiResponse.error(error),
      );
    } on SocketException {
      return ApiResponse.errorMessage(
        'No internet connection. Please check your network settings.',
      );
    } on TimeoutException {
      return ApiResponse.errorMessage('Connection timeout. Please try again.');
    } catch (e) {
      return ApiResponse.errorMessage(
        'Failed to load branch availability. Please try again.',
      );
    }
  }
}
