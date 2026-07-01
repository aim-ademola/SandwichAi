class DashboardSummaryModel {
  final double todaysSales;
  final int totalOrders;
  final int completedOrders;
  final int pendingOrdersCount;
  final int activeOrders;
  final double avgOrderValue;
  final double customerSatisfaction;
  final int complaintsToday;
  final List<SalesFunnelStageModel> salesFunnel;

  DashboardSummaryModel({
    required this.todaysSales,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrdersCount,
    required this.activeOrders,
    required this.avgOrderValue,
    required this.customerSatisfaction,
    required this.complaintsToday,
    required this.salesFunnel,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final root = _readMap(json['data']) ?? json;
    final metrics =
        _readMap(root['metrics']) ??
        _readMap(root['summary']) ??
        _readMap(root['kpis']) ??
        root;

    final totalOrders = _readInt(
      metrics['totalOrders'] ??
          metrics['orders'] ??
          metrics['orderCount'] ??
          metrics['total_order_count'],
    );
    final completedOrders = _readInt(
      metrics['completedOrders'] ??
          metrics['completed'] ??
          metrics['completedOrderCount'] ??
          metrics['paidOrders'],
    );
    final pendingOrders = _readInt(
      metrics['pendingOrders'] ??
          metrics['pending'] ??
          metrics['pendingOrderCount'] ??
          metrics['unpaidOrders'],
    );
    final activeOrders = _readInt(
      metrics['activeOrders'] ??
          metrics['active'] ??
          metrics['ongoingOrders'] ??
          metrics['liveOrders'],
    );
    final todaysSales = _readDouble(
      metrics['todaysSales'] ??
          metrics['todaySales'] ??
          metrics['totalRevenue'] ??
          metrics['revenue'] ??
          metrics['sales'] ??
          metrics['grossSales'],
    );
    final avgOrderValue = _readDouble(
      metrics['avgOrderValue'] ??
          metrics['averageOrderValue'] ??
          metrics['average_order_value'],
    );
    final funnel = _readSalesFunnel(root, metrics);

    return DashboardSummaryModel(
      todaysSales: todaysSales,
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      pendingOrdersCount: pendingOrders > 0
          ? pendingOrders
          : (totalOrders - completedOrders).clamp(0, totalOrders),
      activeOrders: activeOrders,
      avgOrderValue: avgOrderValue > 0
          ? avgOrderValue
          : (totalOrders == 0 ? 0 : todaysSales / totalOrders),
      customerSatisfaction: _readDouble(
        metrics['customerSatisfaction'] ??
            metrics['satisfaction'] ??
            metrics['customer_satisfaction'],
      ),
      complaintsToday: _readInt(
        metrics['complaintsToday'] ??
            metrics['complaints'] ??
            metrics['complaintCount'],
      ),
      salesFunnel: funnel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todaysSales': todaysSales,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'pendingOrders': pendingOrdersCount,
      'activeOrders': activeOrders,
      'avgOrderValue': avgOrderValue,
      'customerSatisfaction': customerSatisfaction,
      'complaintsToday': complaintsToday,
      'salesFunnel': salesFunnel.map((stage) => stage.toJson()).toList(),
    };
  }

  String get formattedSales => _formatMoney(todaysSales);
  String get formattedAvgOrder => _formatMoney(avgOrderValue);
  String get formattedSatisfaction =>
      '${customerSatisfaction.toStringAsFixed(1)}%';
  int get pendingOrders => pendingOrdersCount;

  List<SalesFunnelStageModel> get funnelOrFallback {
    if (salesFunnel.isNotEmpty) return salesFunnel;

    return [
      SalesFunnelStageModel(label: 'Orders', value: totalOrders.toDouble()),
      SalesFunnelStageModel(label: 'Active', value: activeOrders.toDouble()),
      SalesFunnelStageModel(
        label: 'Pending Pay',
        value: pendingOrdersCount.toDouble(),
      ),
      SalesFunnelStageModel(
        label: 'Completed',
        value: completedOrders.toDouble(),
      ),
    ].where((stage) => stage.value > 0).toList();
  }

  DashboardSummaryModel copyWith({
    double? todaysSales,
    int? totalOrders,
    int? completedOrders,
    int? pendingOrdersCount,
    int? activeOrders,
    double? avgOrderValue,
    double? customerSatisfaction,
    int? complaintsToday,
    List<SalesFunnelStageModel>? salesFunnel,
  }) {
    return DashboardSummaryModel(
      todaysSales: todaysSales ?? this.todaysSales,
      totalOrders: totalOrders ?? this.totalOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      pendingOrdersCount: pendingOrdersCount ?? this.pendingOrdersCount,
      activeOrders: activeOrders ?? this.activeOrders,
      avgOrderValue: avgOrderValue ?? this.avgOrderValue,
      customerSatisfaction: customerSatisfaction ?? this.customerSatisfaction,
      complaintsToday: complaintsToday ?? this.complaintsToday,
      salesFunnel: salesFunnel ?? this.salesFunnel,
    );
  }
}

class SalesFunnelStageModel {
  final String label;
  final double value;

  const SalesFunnelStageModel({required this.label, required this.value});

  factory SalesFunnelStageModel.fromJson(Map<String, dynamic> json) {
    return SalesFunnelStageModel(
      label:
          (json['label'] ??
                  json['name'] ??
                  json['stage'] ??
                  json['status'] ??
                  'Stage')
              .toString(),
      value: _readDouble(
        json['value'] ?? json['count'] ?? json['total'] ?? json['orders'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}

List<SalesFunnelStageModel> _readSalesFunnel(
  Map<String, dynamic> root,
  Map<String, dynamic> metrics,
) {
  final value =
      root['salesFunnel'] ??
      root['sales_funnel'] ??
      root['funnel'] ??
      root['conversionFunnel'] ??
      metrics['salesFunnel'] ??
      metrics['sales_funnel'] ??
      metrics['funnel'];

  if (value is List) {
    return value
        .whereType<Map>()
        .map((entry) => SalesFunnelStageModel.fromJson(entry.cast()))
        .where((stage) => stage.value >= 0)
        .toList();
  }

  final map = _readMap(value);
  if (map == null) return const [];

  return map.entries
      .map(
        (entry) => SalesFunnelStageModel(
          label: _formatLabel(entry.key),
          value: _readDouble(entry.value),
        ),
      )
      .where((stage) => stage.value >= 0)
      .toList();
}

Map<String, dynamic>? _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.replaceAll(',', '')) ?? 0;
  return 0;
}

double _readDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) {
    final sanitized = value.replaceAll(RegExp(r'[^0-9\.-]'), '');
    return double.tryParse(sanitized) ?? 0;
  }
  return 0;
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(
    value.truncateToDouble() == value ? 0 : 2,
  );
  final parts = fixed.split('.');
  final whole = parts.first;
  final buffer = StringBuffer();

  for (var i = 0; i < whole.length; i++) {
    final fromEnd = whole.length - i;
    buffer.write(whole[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write(',');
    }
  }

  return '\u20A6$buffer${parts.length > 1 ? '.${parts.last}' : ''}';
}

String _formatLabel(String value) {
  return value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
