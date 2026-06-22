class OrderItemRequest {
  final String productId;
  final int quantityOrdered;
  final String? notes;

  const OrderItemRequest({
    required this.productId,
    required this.quantityOrdered,
    this.notes,
  });

  factory OrderItemRequest.fromJson(Map<String, dynamic> json) {
    return OrderItemRequest(
      productId: json['productId']?.toString() ?? '',
      quantityOrdered: _asInt(json['quantityOrdered'] ?? json['quantity']),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantityOrdered': quantityOrdered,
      if (notes != null) 'notes': notes,
    };
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
