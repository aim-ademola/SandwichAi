class TaxConfiguration {
  final String id;
  final String taxCode;
  final String taxName;
  final String taxType;
  final String taxRateType;
  final double taxRate;
  final String? salesTaxAccountId;
  final String? purchaseTaxAccountId;
  final bool isDefault;
  final bool applyToSales;
  final bool applyToPurchases;
  final bool isInclusive;
  final bool isActive;
  final String? effectiveFrom;
  final String? effectiveTo;
  final String? description;
  final String createdAt;
  final String updatedAt;

  const TaxConfiguration({
    required this.id,
    required this.taxCode,
    required this.taxName,
    required this.taxType,
    required this.taxRateType,
    required this.taxRate,
    this.salesTaxAccountId,
    this.purchaseTaxAccountId,
    required this.isDefault,
    required this.applyToSales,
    required this.applyToPurchases,
    required this.isInclusive,
    required this.isActive,
    this.effectiveFrom,
    this.effectiveTo,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaxConfiguration.fromJson(Map<String, dynamic> json) {
    return TaxConfiguration(
      id: json['id'] as String,
      taxCode: json['taxCode'] as String,
      taxName: json['taxName'] as String,
      taxType: json['taxType'] as String,
      taxRateType: json['taxRateType'] as String,
      taxRate: (json['taxRate'] as num).toDouble(),
      salesTaxAccountId: json['salesTaxAccountId'] as String?,
      purchaseTaxAccountId: json['purchaseTaxAccountId'] as String?,
      isDefault: json['isDefault'] as bool,
      applyToSales: json['applyToSales'] as bool,
      applyToPurchases: json['applyToPurchases'] as bool,
      isInclusive: json['isInclusive'] as bool,
      isActive: json['isActive'] as bool,
      effectiveFrom: json['effectiveFrom'] as String?,
      effectiveTo: json['effectiveTo'] as String?,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taxCode': taxCode,
      'taxName': taxName,
      'taxType': taxType,
      'taxRateType': taxRateType,
      'taxRate': taxRate,
      'salesTaxAccountId': salesTaxAccountId,
      'purchaseTaxAccountId': purchaseTaxAccountId,
      'isDefault': isDefault,
      'applyToSales': applyToSales,
      'applyToPurchases': applyToPurchases,
      'isInclusive': isInclusive,
      'isActive': isActive,
      'effectiveFrom': effectiveFrom,
      'effectiveTo': effectiveTo,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isApplicableToSales {
    if (!isActive || !applyToSales) return false;

    final now = DateTime.now();

    if (effectiveFrom != null) {
      final from = DateTime.tryParse(effectiveFrom!);
      if (from != null && now.isBefore(from)) return false;
    }

    if (effectiveTo != null) {
      final to = DateTime.tryParse(effectiveTo!);
      if (to != null && now.isAfter(to)) return false;
    }

    return true;
  }

  double calculateTaxAmount(double subtotal) {
    if (isInclusive) return 0.0;

    switch (taxRateType.toUpperCase()) {
      case 'PERCENTAGE':
        return subtotal * (taxRate / 100);
      case 'FLAT':
      case 'FIXED':
        return taxRate;
      default:
        return subtotal * (taxRate / 100);
    }
  }

  /// Inclusive tax amount extracted from the subtotal (for display purposes).
  double extractInclusiveTaxAmount(double subtotalWithTax) {
    if (!isInclusive) return 0.0;
    // Reverse calculation: tax = subtotal * rate / (100 + rate)
    return subtotalWithTax * taxRate / (100 + taxRate);
  }
}
