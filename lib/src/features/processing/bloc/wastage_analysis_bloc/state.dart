import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/processing/data/model/wastage_analysis_model.dart';

enum WastageAnalysisErrorType {
  network,
  timeout,
  notFound,
  server,
  validation,
  general,
}

abstract class WastageAnalysisState extends Equatable {
  const WastageAnalysisState();

  @override
  List<Object?> get props => [];
}

class WastageAnalysisInitial extends WastageAnalysisState {
  const WastageAnalysisInitial();
}

class WastageAnalysisLoading extends WastageAnalysisState {
  const WastageAnalysisLoading();
}

class WastageAnalysisRefreshing extends WastageAnalysisState {
  final WastageAnalysisResponse currentData;

  const WastageAnalysisRefreshing({required this.currentData});

  @override
  List<Object?> get props => [currentData];
}

class WastageAnalysisLoaded extends WastageAnalysisState {
  final WastageAnalysisResponse analysis;
  final int daysBack;

  const WastageAnalysisLoaded({required this.analysis, required this.daysBack});

  @override
  List<Object?> get props => [analysis, daysBack];

  WastageAnalysisLoaded copyWith({
    WastageAnalysisResponse? analysis,
    int? daysBack,
  }) {
    return WastageAnalysisLoaded(
      analysis: analysis ?? this.analysis,
      daysBack: daysBack ?? this.daysBack,
    );
  }
}

class WastageAnalysisEmpty extends WastageAnalysisState {
  final int daysBack;

  const WastageAnalysisEmpty({required this.daysBack});

  @override
  List<Object?> get props => [daysBack];
}

class WastageAnalysisError extends WastageAnalysisState {
  final String error;
  final WastageAnalysisErrorType errorType;

  const WastageAnalysisError({
    required this.error,
    this.errorType = WastageAnalysisErrorType.general,
  });

  @override
  List<Object?> get props => [error, errorType];
}
