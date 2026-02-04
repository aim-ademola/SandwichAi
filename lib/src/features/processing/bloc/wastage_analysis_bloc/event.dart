import 'package:equatable/equatable.dart';

abstract class WastageAnalysisEvent extends Equatable {
  const WastageAnalysisEvent();

  @override
  List<Object?> get props => [];
}

class LoadWastageAnalysis extends WastageAnalysisEvent {
  final int daysBack;

  const LoadWastageAnalysis({this.daysBack = 30});

  @override
  List<Object?> get props => [daysBack];
}

class RefreshWastageAnalysis extends WastageAnalysisEvent {
  final int daysBack;

  const RefreshWastageAnalysis({this.daysBack = 30});

  @override
  List<Object?> get props => [daysBack];
}

class UpdateAnalysisPeriod extends WastageAnalysisEvent {
  final int daysBack;

  const UpdateAnalysisPeriod({required this.daysBack});

  @override
  List<Object?> get props => [daysBack];
}
