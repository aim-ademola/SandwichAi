enum BulkInventoryOperation { create, update, upsert }

extension BulkInventoryOperationX on BulkInventoryOperation {
  String get apiValue {
    switch (this) {
      case BulkInventoryOperation.create:
        return 'create';
      case BulkInventoryOperation.update:
        return 'update';
      case BulkInventoryOperation.upsert:
        return 'upsert';
    }
  }
}
