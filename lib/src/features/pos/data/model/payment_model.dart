// Payment Request Models
class CashPaymentRequest {
  final double amount;
  final String customerName;
  final String branchId;
  final String? customerPhone;
  final String? customerEmail;
  final String? orderId;
  final String? description;
  final Map<String, dynamic>? metadata;

  CashPaymentRequest({
    required this.amount,
    required this.customerName,
    required this.branchId,
    this.customerPhone,
    this.customerEmail,
    this.orderId,
    this.description,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'customerName': customerName,
      'branchId': branchId,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerEmail != null) 'customerEmail': customerEmail,
      if (orderId != null) 'orderId': orderId,
      if (description != null) 'description': description,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

class BankTransferPaymentRequest {
  final double amount;
  final String customerName;
  final String branchId;
  final String bankReference;
  final String? senderAccountNumber;
  final String? senderBank;
  final String? customerPhone;
  final String? customerEmail;
  final String? orderId;
  final String? description;
  final Map<String, dynamic>? metadata;

  BankTransferPaymentRequest({
    required this.amount,
    required this.customerName,
    required this.branchId,
    required this.bankReference,
    this.senderAccountNumber,
    this.senderBank,
    this.customerPhone,
    this.customerEmail,
    this.orderId,
    this.description,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'customerName': customerName,
      'branchId': branchId,
      'bankReference': bankReference,
      if (senderAccountNumber != null)
        'senderAccountNumber': senderAccountNumber,
      if (senderBank != null) 'senderBank': senderBank,
      if (customerPhone != null) 'customerPhone': customerPhone,
      if (customerEmail != null) 'customerEmail': customerEmail,
      if (orderId != null) 'orderId': orderId,
      if (description != null) 'description': description,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

// Payment Response Models
class PaymentResponseModel {
  final bool success;
  final String message;
  final PaymentData data;

  PaymentResponseModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory PaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: PaymentData.fromJson(json['data'] ?? {}),
    );
  }
}

class PaymentData {
  final Payment payment;
  final Transaction transaction;
  final Receipt receipt;

  PaymentData({
    required this.payment,
    required this.transaction,
    required this.receipt,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      payment: Payment.fromJson(json['payment'] ?? {}),
      transaction: Transaction.fromJson(json['transaction'] ?? {}),
      receipt: Receipt.fromJson(json['receipt'] ?? {}),
    );
  }
}

class Payment {
  final String id;
  final String paymentId;
  final String reference;
  final String organizationId;
  final String branchId;
  final String walletId;
  final String? orderId;
  final String amount;
  final String? customerEmail;
  final String? customerPhone;
  final String customerName;
  final String status;
  final String paymentMethod;
  final String? description;
  final Map<String, dynamic>? metadata;
  final String? paidAt;
  final String createdAt;

  Payment({
    required this.id,
    required this.paymentId,
    required this.reference,
    required this.organizationId,
    required this.branchId,
    required this.walletId,
    this.orderId,
    required this.amount,
    this.customerEmail,
    this.customerPhone,
    required this.customerName,
    required this.status,
    required this.paymentMethod,
    this.description,
    this.metadata,
    this.paidAt,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      paymentId: json['paymentId'] ?? '',
      reference: json['reference'] ?? '',
      organizationId: json['organizationId'] ?? '',
      branchId: json['branchId'] ?? '',
      walletId: json['walletId'] ?? '',
      orderId: json['orderId'],
      amount: json['amount']?.toString() ?? '0',
      customerEmail: json['customerEmail'],
      customerPhone: json['customerPhone'],
      customerName: json['customerName'] ?? '',
      status: json['status'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      description: json['description'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      paidAt: json['paidAt'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class Transaction {
  final String id;
  final String transactionId;
  final String walletId;
  final String type;
  final String source;
  final String amount;
  final String balanceBefore;
  final String balanceAfter;
  final String reference;
  final String? description;
  final String createdAt;

  Transaction({
    required this.id,
    required this.transactionId,
    required this.walletId,
    required this.type,
    required this.source,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.reference,
    this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      transactionId: json['transactionId'] ?? '',
      walletId: json['walletId'] ?? '',
      type: json['type'] ?? '',
      source: json['source'] ?? '',
      amount: json['amount']?.toString() ?? '0',
      balanceBefore: json['balanceBefore']?.toString() ?? '0',
      balanceAfter: json['balanceAfter']?.toString() ?? '0',
      reference: json['reference'] ?? '',
      description: json['description'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class Receipt {
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

  Receipt({
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
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
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
    );
  }
}
