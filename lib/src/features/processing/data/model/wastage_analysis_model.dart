class WastageAnalysisRequest {
  final String organizationId;
  final String branchId;
  final int daysBack;

  WastageAnalysisRequest({
    required this.organizationId,
    required this.branchId,
    this.daysBack = 30,
  });

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'branch_id': branchId,
      'days_back': daysBack,
    };
  }
}

class WastageAnalysisResponse {
  final int totalLogs;
  final int daysAnalyzed;
  final List<WastageAnomaly> anomalies;
  final List<WastagePattern> patterns;
  final List<HighRiskItem> highRiskItems;
  final FinancialImpact financialImpact;
  final List<String> recommendations;
  final DateTime generatedAt;

  WastageAnalysisResponse({
    required this.totalLogs,
    required this.daysAnalyzed,
    required this.anomalies,
    required this.patterns,
    required this.highRiskItems,
    required this.financialImpact,
    required this.recommendations,
    required this.generatedAt,
  });

  factory WastageAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return WastageAnalysisResponse(
      totalLogs: json['total_logs'] ?? 0,
      daysAnalyzed: json['days_analyzed'] ?? 0,
      anomalies:
          (json['anomalies'] as List<dynamic>?)
              ?.map((e) => WastageAnomaly.fromJson(e))
              .toList() ??
          [],
      patterns:
          (json['patterns'] as List<dynamic>?)
              ?.map((e) => WastagePattern.fromJson(e))
              .toList() ??
          [],
      highRiskItems:
          (json['high_risk_items'] as List<dynamic>?)
              ?.map((e) => HighRiskItem.fromJson(e))
              .toList() ??
          [],
      financialImpact: FinancialImpact.fromJson(json['financial_impact'] ?? {}),
      recommendations:
          (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_logs': totalLogs,
      'days_analyzed': daysAnalyzed,
      'anomalies': anomalies.map((e) => e.toJson()).toList(),
      'patterns': patterns.map((e) => e.toJson()).toList(),
      'high_risk_items': highRiskItems.map((e) => e.toJson()).toList(),
      'financial_impact': financialImpact.toJson(),
      'recommendations': recommendations,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

class WastageAnomaly {
  final String itemId;
  final String itemName;
  final double quantity;
  final String unit;
  final double valueLost;
  final String reason;
  final DateTime date;
  final double deviationScore;

  WastageAnomaly({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.valueLost,
    required this.reason,
    required this.date,
    required this.deviationScore,
  });

  factory WastageAnomaly.fromJson(Map<String, dynamic> json) {
    return WastageAnomaly(
      itemId: json['item_id'] ?? '',
      itemName: json['item_name'] ?? '',
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      unit: json['unit'] ?? '',
      valueLost: (json['value_lost'] ?? 0.0).toDouble(),
      reason: json['reason'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      deviationScore: (json['deviation_score'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'value_lost': valueLost,
      'reason': reason,
      'date': date.toIso8601String(),
      'deviation_score': deviationScore,
    };
  }
}

class WastagePattern {
  final String reason;
  final int occurrences;
  final double totalValueLost;

  WastagePattern({
    required this.reason,
    required this.occurrences,
    required this.totalValueLost,
  });

  factory WastagePattern.fromJson(Map<String, dynamic> json) {
    return WastagePattern(
      reason: json['reason'] ?? '',
      occurrences: json['occurrences'] ?? 0,
      totalValueLost: (json['total_value_lost'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      'occurrences': occurrences,
      'total_value_lost': totalValueLost,
    };
  }
}

class HighRiskItem {
  final String itemName;
  final String itemId;
  final int wasteFrequency;
  final double totalValueLost;
  final double avgQuantityPerIncident;
  final String unit;
  final String primaryReason;

  HighRiskItem({
    required this.itemName,
    required this.itemId,
    required this.wasteFrequency,
    required this.totalValueLost,
    required this.avgQuantityPerIncident,
    required this.unit,
    required this.primaryReason,
  });

  factory HighRiskItem.fromJson(Map<String, dynamic> json) {
    return HighRiskItem(
      itemName: json['item_name'] ?? '',
      itemId: json['item_id'] ?? '',
      wasteFrequency: json['waste_frequency'] ?? 0,
      totalValueLost: (json['total_value_lost'] ?? 0.0).toDouble(),
      avgQuantityPerIncident: (json['avg_quantity_per_incident'] ?? 0.0)
          .toDouble(),
      unit: json['unit'] ?? '',
      primaryReason: json['primary_reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_name': itemName,
      'item_id': itemId,
      'waste_frequency': wasteFrequency,
      'total_value_lost': totalValueLost,
      'avg_quantity_per_incident': avgQuantityPerIncident,
      'unit': unit,
      'primary_reason': primaryReason,
    };
  }
}

class FinancialImpact {
  final double totalValueLost;
  final double avgDailyLoss;
  final List<String> peakWastageItems;

  FinancialImpact({
    required this.totalValueLost,
    required this.avgDailyLoss,
    required this.peakWastageItems,
  });

  factory FinancialImpact.fromJson(Map<String, dynamic> json) {
    return FinancialImpact(
      totalValueLost: (json['total_value_lost'] ?? 0.0).toDouble(),
      avgDailyLoss: (json['avg_daily_loss'] ?? 0.0).toDouble(),
      peakWastageItems:
          (json['peak_wastage_items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_value_lost': totalValueLost,
      'avg_daily_loss': avgDailyLoss,
      'peak_wastage_items': peakWastageItems,
    };
  }
}
