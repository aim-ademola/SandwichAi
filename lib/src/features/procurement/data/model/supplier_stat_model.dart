class SupplierStats {
  final int totalSuppliers;
  final int activeSuppliers;
  final int pendingSuppliers;
  final int verifiedSuppliers;
  final double averageRating;

  const SupplierStats({
    required this.totalSuppliers,
    required this.activeSuppliers,
    required this.pendingSuppliers,
    required this.verifiedSuppliers,
    required this.averageRating,
  });

  factory SupplierStats.fromJson(Map<String, dynamic> json) {
    return SupplierStats(
      totalSuppliers: json['totalSuppliers'] as int? ?? 0,
      activeSuppliers: json['activeSuppliers'] as int? ?? 0,
      pendingSuppliers: json['pendingSuppliers'] as int? ?? 0,
      verifiedSuppliers: json['verifiedSuppliers'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSuppliers': totalSuppliers,
      'activeSuppliers': activeSuppliers,
      'pendingSuppliers': pendingSuppliers,
      'verifiedSuppliers': verifiedSuppliers,
      'averageRating': averageRating,
    };
  }

  // Empty state for initial/loading
  static const empty = SupplierStats(
    totalSuppliers: 0,
    activeSuppliers: 0,
    pendingSuppliers: 0,
    verifiedSuppliers: 0,
    averageRating: 0.0,
  );

  // Calculate on-time delivery percentage based on active vs total
  double get onTimeDeliveryPercentage {
    if (totalSuppliers == 0) return 0.0;
    return (activeSuppliers / totalSuppliers) * 100;
  }

  @override
  String toString() {
    return 'SupplierStats(totalSuppliers: $totalSuppliers, activeSuppliers: $activeSuppliers, '
        'pendingSuppliers: $pendingSuppliers, verifiedSuppliers: $verifiedSuppliers, '
        'averageRating: $averageRating)';
  }
}
