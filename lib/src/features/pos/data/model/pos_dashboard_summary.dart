class DashboardSummaryModel {
  final double todaysSales;
  final int totalOrders;
  final int completedOrders;
  final double avgOrderValue;
  final double customerSatisfaction;
  final int complaintsToday;

  DashboardSummaryModel({
    required this.todaysSales,
    required this.totalOrders,
    required this.completedOrders,
    required this.avgOrderValue,
    required this.customerSatisfaction,
    required this.complaintsToday,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      todaysSales: (json['todaysSales'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      completedOrders: json['completedOrders'] ?? 0,
      avgOrderValue: (json['avgOrderValue'] ?? 0).toDouble(),
      customerSatisfaction: (json['customerSatisfaction'] ?? 0).toDouble(),
      complaintsToday: json['complaintsToday'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todaysSales': todaysSales,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'avgOrderValue': avgOrderValue,
      'customerSatisfaction': customerSatisfaction,
      'complaintsToday': complaintsToday,
    };
  }

  // Helper getters for formatted display
  String get formattedSales => '₦${todaysSales.toStringAsFixed(0)}';
  String get formattedAvgOrder => '₦${avgOrderValue.toStringAsFixed(0)}';

  String get formattedSatisfaction =>
      '${customerSatisfaction.toStringAsFixed(1)}%';
  int get pendingOrders => totalOrders - completedOrders;

  DashboardSummaryModel copyWith({
    double? todaysSales,
    int? totalOrders,
    int? completedOrders,
    double? avgOrderValue,
    double? customerSatisfaction,
    int? complaintsToday,
  }) {
    return DashboardSummaryModel(
      todaysSales: todaysSales ?? this.todaysSales,
      totalOrders: totalOrders ?? this.totalOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      avgOrderValue: avgOrderValue ?? this.avgOrderValue,
      customerSatisfaction: customerSatisfaction ?? this.customerSatisfaction,
      complaintsToday: complaintsToday ?? this.complaintsToday,
    );
  }
}
