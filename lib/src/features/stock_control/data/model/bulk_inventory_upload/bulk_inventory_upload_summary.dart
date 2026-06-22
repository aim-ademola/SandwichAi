import 'package:sandwich_ai/src/features/stock_control/data/model/bulk_inventory_upload/value_parsers.dart';

class BulkInventoryUploadSummary {
  final int totalRows;
  final int validRows;
  final int invalidRows;
  final int createdRows;
  final int updatedRows;
  final int skippedRows;

  const BulkInventoryUploadSummary({
    required this.totalRows,
    required this.validRows,
    required this.invalidRows,
    required this.createdRows,
    required this.updatedRows,
    required this.skippedRows,
  });

  factory BulkInventoryUploadSummary.fromJson(Map<String, dynamic> json) {
    return BulkInventoryUploadSummary(
      totalRows: asInt(json['totalRows']),
      validRows: asInt(json['validRows']),
      invalidRows: asInt(json['invalidRows']),
      createdRows: asInt(json['createdRows']),
      updatedRows: asInt(json['updatedRows']),
      skippedRows: asInt(json['skippedRows']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRows': totalRows,
      'validRows': validRows,
      'invalidRows': invalidRows,
      'createdRows': createdRows,
      'updatedRows': updatedRows,
      'skippedRows': skippedRows,
    };
  }
}
