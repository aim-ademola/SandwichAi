enum PurchaseOrderDraftStatus { draft, pendingApproval, approved }

extension PurchaseOrderDraftStatusX on PurchaseOrderDraftStatus {
  String get apiValue {
    switch (this) {
      case PurchaseOrderDraftStatus.draft:
        return 'DRAFT';
      case PurchaseOrderDraftStatus.pendingApproval:
        return 'PENDING_APPROVAL';
      case PurchaseOrderDraftStatus.approved:
        return 'APPROVED';
    }
  }

  static PurchaseOrderDraftStatus fromApiValue(String? value) {
    switch (value) {
      case 'PENDING_APPROVAL':
        return PurchaseOrderDraftStatus.pendingApproval;
      case 'APPROVED':
        return PurchaseOrderDraftStatus.approved;
      case 'DRAFT':
      default:
        return PurchaseOrderDraftStatus.draft;
    }
  }
}
