import 'package:sandwich_ai/src/features/stock_control/data/model/bulk_inventory_upload/bulk_inventory_row_error.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/bulk_inventory_upload/bulk_inventory_upload_summary.dart';

class BulkInventoryUploadResponse {
  final String uploadId;
  final String status;
  final BulkInventoryUploadSummary summary;
  final List<BulkInventoryRowError> rowErrors;
  final Map<String, dynamic> rawData;

  const BulkInventoryUploadResponse({
    required this.uploadId,
    required this.status,
    required this.summary,
    required this.rowErrors,
    required this.rawData,
  });

  factory BulkInventoryUploadResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return BulkInventoryUploadResponse(
      uploadId: data['uploadId']?.toString() ?? data['id']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      summary: BulkInventoryUploadSummary.fromJson(
        (data['summary'] as Map?)?.cast<String, dynamic>() ?? data,
      ),
      rowErrors: ((data['rowErrors'] ?? data['errors']) as List? ?? [])
          .whereType<Map>()
          .map(
            (error) =>
                BulkInventoryRowError.fromJson(error.cast<String, dynamic>()),
          )
          .toList(),
      rawData: data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uploadId': uploadId,
      'status': status,
      'summary': summary.toJson(),
      'rowErrors': rowErrors.map((error) => error.toJson()).toList(),
      'rawData': rawData,
    };
  }

  bool get hasErrors => rowErrors.isNotEmpty || summary.invalidRows > 0;
}
