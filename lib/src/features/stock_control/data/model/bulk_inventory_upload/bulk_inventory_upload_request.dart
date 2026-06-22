import 'package:sandwich_ai/src/features/stock_control/data/model/bulk_inventory_upload/bulk_inventory_operation.dart';

class BulkInventoryUploadRequest {
  final String organizationId;
  final String uploadedBy;
  final BulkInventoryOperation operation;
  final bool skipInvalidRows;

  const BulkInventoryUploadRequest({
    required this.organizationId,
    required this.uploadedBy,
    this.operation = BulkInventoryOperation.upsert,
    this.skipInvalidRows = true,
  });

  Map<String, dynamic> toFields() {
    return {
      'organizationId': organizationId,
      'uploadedBy': uploadedBy,
      'operation': operation.apiValue,
      'skipInvalidRows': skipInvalidRows.toString(),
    };
  }
}
