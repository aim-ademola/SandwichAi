import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_performance_model.dart';

enum ProcurementPerformanceStatus { initial, loading, loaded, empty, error }

class ProcurementPerformanceState extends Equatable {
  final ProcurementPerformanceStatus performanceStatus;
  final ProcurementPerformanceStatus rankingsStatus;
  final ProcurementPerformanceResponse? performance;
  final ProcurementPerformanceRankingsResponse? rankings;
  final String? performanceError;
  final String? rankingsError;

  const ProcurementPerformanceState({
    this.performanceStatus = ProcurementPerformanceStatus.initial,
    this.rankingsStatus = ProcurementPerformanceStatus.initial,
    this.performance,
    this.rankings,
    this.performanceError,
    this.rankingsError,
  });

  ProcurementPerformanceState copyWith({
    ProcurementPerformanceStatus? performanceStatus,
    ProcurementPerformanceStatus? rankingsStatus,
    ProcurementPerformanceResponse? performance,
    ProcurementPerformanceRankingsResponse? rankings,
    String? performanceError,
    String? rankingsError,
    bool clearPerformanceError = false,
    bool clearRankingsError = false,
  }) {
    return ProcurementPerformanceState(
      performanceStatus: performanceStatus ?? this.performanceStatus,
      rankingsStatus: rankingsStatus ?? this.rankingsStatus,
      performance: performance ?? this.performance,
      rankings: rankings ?? this.rankings,
      performanceError: clearPerformanceError
          ? null
          : (performanceError ?? this.performanceError),
      rankingsError: clearRankingsError
          ? null
          : (rankingsError ?? this.rankingsError),
    );
  }

  @override
  List<Object?> get props => [
    performanceStatus,
    rankingsStatus,
    performance,
    rankings,
    performanceError,
    rankingsError,
  ];
}
