// ─── Cash Record Request ──────────────────────────────────────────────────────
class CashPaymentRequest {
  final double amount;
  final String customerName;
  final String branchId;
  final String? customerPhone;
  final String? customerEmail;
  final String? orderId;
  final String? description;
  final String? sessionId;
  final Map<String, dynamic>? metadata;

  CashPaymentRequest({
    required this.amount,
    required this.customerName,
    required this.branchId,
    this.customerPhone,
    this.customerEmail,
    this.orderId,
    this.description,
    this.sessionId,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount.toInt(),
      'customerName': customerName,
      'branchId': branchId,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerEmail != null) 'customerEmail': customerEmail,
      if (orderId != null) 'orderId': orderId,
      if (description != null) 'description': description,
      if (sessionId != null) 'sessionId': sessionId,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

// ─── Online Payment Initialize Request ───────────────────────────────────────
class OnlinePaymentRequest {
  final double amount;
  final String email;
  final String customerName;
  final String branchId;
  final String? customerPhone;
  final String? orderId;
  final String? description;
  final String paymentMethod; // 'CARD' or 'BANK_TRANSFER'
  final String? sessionId;
  final Map<String, dynamic>? metadata;

  OnlinePaymentRequest({
    required this.amount,
    required this.email,
    required this.customerName,
    required this.branchId,
    this.customerPhone,
    this.orderId,
    this.description,
    this.paymentMethod = 'CARD',
    this.sessionId,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount.toInt(),
      'email': email,
      'customerName': customerName,
      'branchId': branchId,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (orderId != null) 'orderId': orderId,
      if (description != null) 'description': description,
      'paymentMethod': paymentMethod,
      if (sessionId != null) 'sessionId': sessionId,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

// ─── Cash Record Response ─────────────────────────────────────────────────────
class CashRecordResponseModel {
  final bool success;
  final String message;
  final CashTransactionData data;

  CashRecordResponseModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CashRecordResponseModel.fromJson(Map<String, dynamic> json) {
    return CashRecordResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: CashTransactionData.fromJson(json['data'] ?? {}),
    );
  }
}

class CashTransactionData {
  final CashTransaction transaction;

  CashTransactionData({required this.transaction});

  factory CashTransactionData.fromJson(Map<String, dynamic> json) {
    return CashTransactionData(
      transaction: CashTransaction.fromJson(json['transaction'] ?? {}),
    );
  }
}

class CashTransaction {
  final String id;
  final String transactionId;
  final String reference;
  final String organizationId;
  final String branchId;
  final String amount;
  final String transactionType;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? orderId;
  final String? description;
  final String receivedBy;
  final String status;
  final Map<String, dynamic>? metadata;
  final String createdAt;
  final String updatedAt;
  final CashBranch? branch;
  final CashReceiver? receiver;

  CashTransaction({
    required this.id,
    required this.transactionId,
    required this.reference,
    required this.organizationId,
    required this.branchId,
    required this.amount,
    required this.transactionType,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.orderId,
    this.description,
    required this.receivedBy,
    required this.status,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.branch,
    this.receiver,
  });

  factory CashTransaction.fromJson(Map<String, dynamic> json) {
    return CashTransaction(
      id: json['id'] ?? '',
      transactionId: json['transactionId'] ?? '',
      reference: json['reference'] ?? '',
      organizationId: json['organizationId'] ?? '',
      branchId: json['branchId'] ?? '',
      amount: json['amount']?.toString() ?? '0',
      transactionType: json['transactionType'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'],
      customerEmail: json['customerEmail'],
      orderId: json['orderId'],
      description: json['description'],
      receivedBy: json['receivedBy'] ?? '',
      status: json['status'] ?? '',
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      branch: json['branch'] != null
          ? CashBranch.fromJson(json['branch'])
          : null,
      receiver: json['receiver'] != null
          ? CashReceiver.fromJson(json['receiver'])
          : null,
    );
  }
}

class CashBranch {
  final String id;
  final String name;

  CashBranch({required this.id, required this.name});

  factory CashBranch.fromJson(Map<String, dynamic> json) {
    return CashBranch(id: json['id'] ?? '', name: json['name'] ?? '');
  }
}

class CashReceiver {
  final String id;
  final String firstName;
  final String lastName;

  CashReceiver({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory CashReceiver.fromJson(Map<String, dynamic> json) {
    return CashReceiver(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
    );
  }
}

// ─── Pending Cash Transactions List ──────────────────────────────────────────
class PendingCashListResponseModel {
  final bool success;
  final List<CashTransaction> data;

  PendingCashListResponseModel({required this.success, required this.data});

  factory PendingCashListResponseModel.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List<dynamic>? ?? [];
    return PendingCashListResponseModel(
      success: json['success'] ?? false,
      data: list.map((e) => CashTransaction.fromJson(e)).toList(),
    );
  }
}

// ─── Online Payment Initialize Response ──────────────────────────────────────
class OnlinePaymentInitResponseModel {
  final bool success;
  final String message;
  final OnlinePaymentInitData data;

  OnlinePaymentInitResponseModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory OnlinePaymentInitResponseModel.fromJson(Map<String, dynamic> json) {
    return OnlinePaymentInitResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: OnlinePaymentInitData.fromJson(json['data'] ?? {}),
    );
  }
}

class OnlinePaymentInitData {
  final String reference;
  final String authorizationUrl;
  final String accessCode;
  final double amount;
  final String expiresAt;

  OnlinePaymentInitData({
    required this.reference,
    required this.authorizationUrl,
    required this.accessCode,
    required this.amount,
    required this.expiresAt,
  });

  factory OnlinePaymentInitData.fromJson(Map<String, dynamic> json) {
    return OnlinePaymentInitData(
      reference: json['reference'] ?? '',
      authorizationUrl: json['authorizationUrl'] ?? '',
      accessCode: json['accessCode'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      expiresAt: json['expiresAt'] ?? '',
    );
  }
}

// ─── Online Payment Status Response ──────────────────────────────────────────
class OnlinePaymentStatusResponseModel {
  final bool success;
  final OnlinePaymentStatusData data;

  OnlinePaymentStatusResponseModel({required this.success, required this.data});

  factory OnlinePaymentStatusResponseModel.fromJson(Map<String, dynamic> json) {
    return OnlinePaymentStatusResponseModel(
      success: json['success'] ?? false,
      data: OnlinePaymentStatusData.fromJson(json['data'] ?? {}),
    );
  }
}

class OnlinePaymentStatusData {
  final String id;
  final String reference;
  final String status; // PENDING, COMPLETED, FAILED
  final String amount;
  final String paymentMethod;
  final String customerName;
  final String? paidAt;
  final String? failedAt;
  final String? failureReason;
  final String branchId;
  final Map<String, dynamic>? metadata;
  final OnlineReceipt? receipt;

  OnlinePaymentStatusData({
    required this.id,
    required this.reference,
    required this.status,
    required this.amount,
    required this.paymentMethod,
    required this.customerName,
    this.paidAt,
    this.failedAt,
    this.failureReason,
    required this.branchId,
    this.metadata,
    this.receipt,
  });

  factory OnlinePaymentStatusData.fromJson(Map<String, dynamic> json) {
    return OnlinePaymentStatusData(
      id: json['id'] ?? '',
      reference: json['reference'] ?? '',
      status: json['status'] ?? '',
      amount: json['amount']?.toString() ?? '0',
      paymentMethod: json['paymentMethod'] ?? '',
      customerName: json['customerName'] ?? '',
      paidAt: json['paidAt'],
      failedAt: json['failedAt'],
      failureReason: json['failureReason'],
      branchId: json['branchId'] ?? '',
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      receipt: json['receipt'] != null
          ? OnlineReceipt.fromJson(json['receipt'])
          : null,
    );
  }
}

class OnlineReceipt {
  final String id;
  final String receiptNumber;
  final String organizationId;
  final String branchId;
  final String? customerPaymentId;
  final String? transactionId;
  final String receiptType;
  final String amount;
  final String paymentMethod;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? description;
  final String issuedAt;
  final Map<String, dynamic>? metadata;
  final String createdAt;
  final OnlineBranch? branch;
  final OnlineOrganization? organization;

  OnlineReceipt({
    required this.id,
    required this.receiptNumber,
    required this.organizationId,
    required this.branchId,
    this.customerPaymentId,
    this.transactionId,
    required this.receiptType,
    required this.amount,
    required this.paymentMethod,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.description,
    required this.issuedAt,
    this.metadata,
    required this.createdAt,
    this.branch,
    this.organization,
  });

  factory OnlineReceipt.fromJson(Map<String, dynamic> json) {
    return OnlineReceipt(
      id: json['id'] ?? '',
      receiptNumber: json['receiptNumber'] ?? '',
      organizationId: json['organizationId'] ?? '',
      branchId: json['branchId'] ?? '',
      customerPaymentId: json['customerPaymentId'],
      transactionId: json['transactionId'],
      receiptType: json['receiptType'] ?? '',
      amount: json['amount']?.toString() ?? '0',
      paymentMethod: json['paymentMethod'] ?? '',
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'],
      customerPhone: json['customerPhone'],
      description: json['description'],
      issuedAt: json['issuedAt'] ?? '',
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      createdAt: json['createdAt'] ?? '',
      branch: json['branch'] != null
          ? OnlineBranch.fromJson(json['branch'])
          : null,
      organization: json['organization'] != null
          ? OnlineOrganization.fromJson(json['organization'])
          : null,
    );
  }
}

class OnlineBranch {
  final String name;
  final String address;

  OnlineBranch({required this.name, required this.address});

  factory OnlineBranch.fromJson(Map<String, dynamic> json) {
    return OnlineBranch(
      name: json['name'] ?? '',
      address: json['address'] ?? 'N/A',
    );
  }
}

class OnlineOrganization {
  final String name;

  OnlineOrganization({required this.name});

  factory OnlineOrganization.fromJson(Map<String, dynamic> json) {
    return OnlineOrganization(name: json['name'] ?? '');
  }
}
