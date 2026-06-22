import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/bulk_inventory_upload_model.dart';

abstract class BulkInventoryUploadRepositoryInterface {
  Future<ApiResponse<BulkInventoryUploadResponse>> uploadInventoryFile({
    required File file,
    required BulkInventoryUploadRequest request,
    ProgressCallback? onSendProgress,
  });
}

class BulkInventoryUploadRepository
    implements BulkInventoryUploadRepositoryInterface {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<ApiResponse<BulkInventoryUploadResponse>> uploadInventoryFile({
    required File file,
    required BulkInventoryUploadRequest request,
    ProgressCallback? onSendProgress,
  }) async {
    final extension = file.path.split('.').last.toLowerCase();
    if (!['csv', 'xls', 'xlsx'].contains(extension)) {
      return ApiResponse.errorMessage(
        'Invalid file type. Please upload a CSV or Excel file.',
      );
    }

    final formData = FormData.fromMap({
      ...request.toFields(),
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'inventory.$extension',
      ),
    });

    return _apiClient.uploadFile<BulkInventoryUploadResponse>(
      'inventory-items/bulk-upload',
      formData,
      onSendProgress: onSendProgress,
      fromJson: (json) => BulkInventoryUploadResponse.fromJson(
        (json as Map).cast<String, dynamic>(),
      ),
    );
  }
}
