import 'package:sandwich_ai/src/features/procurement/data/model/supplier_stat_model.dart';

enum SupplierStatsErrorType { network, timeout, server, validation, general }

abstract class SupplierStatsState {
  const SupplierStatsState();
}

class SupplierStatsInitial extends SupplierStatsState {
  const SupplierStatsInitial();
}

class SupplierStatsLoading extends SupplierStatsState {
  const SupplierStatsLoading();
}

class SupplierStatsLoaded extends SupplierStatsState {
  final SupplierStats stats;

  const SupplierStatsLoaded({required this.stats});

  @override
  String toString() => 'SupplierStatsLoaded(stats: $stats)';
}

class SupplierStatsError extends SupplierStatsState {
  final String error;
  final SupplierStatsErrorType errorType;

  const SupplierStatsError({
    required this.error,
    this.errorType = SupplierStatsErrorType.general,
  });

  @override
  String toString() =>
      'SupplierStatsError(error: $error, errorType: $errorType)';
}
