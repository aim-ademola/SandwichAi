class OrderItemRequest {
  final String productId;
  final double quantityOrdered;
  final String? notes;

  const OrderItemRequest({
    required this.productId,
    required this.quantityOrdered,
    this.notes,
  });

  factory OrderItemRequest.fromJson(Map<String, dynamic> json) {
    return OrderItemRequest(
      productId: json['productId']?.toString() ?? '',
      quantityOrdered: _asDouble(json['quantityOrdered'] ?? json['quantity']),
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

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}
