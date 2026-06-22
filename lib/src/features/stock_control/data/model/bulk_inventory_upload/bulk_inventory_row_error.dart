import 'package:sandwich_ai/src/features/stock_control/data/model/bulk_inventory_upload/value_parsers.dart';

class BulkInventoryRowError {
  final int rowNumber;
  final String field;
  final String message;
  final String? value;

  const BulkInventoryRowError({
    required this.rowNumber,
    required this.field,
    required this.message,
    this.value,
  });

  factory BulkInventoryRowError.fromJson(Map<String, dynamic> json) {
    return BulkInventoryRowError(
      rowNumber: asInt(json['rowNumber'] ?? json['row']),
      field: json['field']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      value: json['value']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rowNumber': rowNumber,
      'field': field,
      'message': message,
      if (value != null) 'value': value,
    };
  }
}
