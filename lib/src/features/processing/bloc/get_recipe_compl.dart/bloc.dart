import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/processing/data/model/recipe_compliance_models.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/fetch_recipe_coml.dart';

// Events
abstract class RecipeComplianceHistoryEvent {
  const RecipeComplianceHistoryEvent();
}

class LoadRecipeComplianceHistory extends RecipeComplianceHistoryEvent {
  const LoadRecipeComplianceHistory();
}

class FilterByMenuItem extends RecipeComplianceHistoryEvent {
  final String? menuItemId;
  const FilterByMenuItem({this.menuItemId});
}

class FilterByStatus extends RecipeComplianceHistoryEvent {
  final String? status;
  const FilterByStatus({this.status});
}

class FilterByDateRange extends RecipeComplianceHistoryEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  const FilterByDateRange({this.startDate, this.endDate});
}

class RefreshRecipeComplianceHistory extends RecipeComplianceHistoryEvent {
  const RefreshRecipeComplianceHistory();
}

class ClearFilters extends RecipeComplianceHistoryEvent {
  const ClearFilters();
}

// States
abstract class RecipeComplianceHistoryState {
  const RecipeComplianceHistoryState();
}

class RecipeComplianceHistoryInitial extends RecipeComplianceHistoryState {
  const RecipeComplianceHistoryInitial();
}

class RecipeComplianceHistoryLoading extends RecipeComplianceHistoryState {
  const RecipeComplianceHistoryLoading();
}

class RecipeComplianceHistoryRefreshing extends RecipeComplianceHistoryState {
  final List<RecipeComplianceResponse> currentData;
  const RecipeComplianceHistoryRefreshing({required this.currentData});
}

class RecipeComplianceHistoryLoaded extends RecipeComplianceHistoryState {
  final List<RecipeComplianceResponse> allRecords;
  final List<RecipeComplianceResponse> filteredRecords;
  final String? selectedMenuItemId;
  final String? selectedStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, int> statusCounts;
  final double averageVariance;

  const RecipeComplianceHistoryLoaded({
    required this.allRecords,
    required this.filteredRecords,
    this.selectedMenuItemId,
    this.selectedStatus,
    this.startDate,
    this.endDate,
    required this.statusCounts,
    required this.averageVariance,
  });

  RecipeComplianceHistoryLoaded copyWith({
    List<RecipeComplianceResponse>? allRecords,
    List<RecipeComplianceResponse>? filteredRecords,
    String? selectedMenuItemId,
    String? selectedStatus,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, int>? statusCounts,
    double? averageVariance,
  }) {
    return RecipeComplianceHistoryLoaded(
      allRecords: allRecords ?? this.allRecords,
      filteredRecords: filteredRecords ?? this.filteredRecords,
      selectedMenuItemId: selectedMenuItemId ?? this.selectedMenuItemId,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      statusCounts: statusCounts ?? this.statusCounts,
      averageVariance: averageVariance ?? this.averageVariance,
    );
  }
}

class RecipeComplianceHistoryEmpty extends RecipeComplianceHistoryState {
  const RecipeComplianceHistoryEmpty();
}

enum RecipeComplianceHistoryErrorType {
  network,
  timeout,
  server,
  validation,
  general,
}

class RecipeComplianceHistoryError extends RecipeComplianceHistoryState {
  final String error;
  final RecipeComplianceHistoryErrorType errorType;

  const RecipeComplianceHistoryError({
    required this.error,
    required this.errorType,
  });
}

// BLoC
class RecipeComplianceHistoryBloc
    extends Bloc<RecipeComplianceHistoryEvent, RecipeComplianceHistoryState> {
  final RecipeComplianceHistoryRepositoryInterface _repository;
  String branchId = '';

  RecipeComplianceHistoryBloc({
    required RecipeComplianceHistoryRepositoryInterface repository,
  }) : _repository = repository,
       super(const RecipeComplianceHistoryInitial()) {
    _getBranchId();
    on<LoadRecipeComplianceHistory>(_onLoadRecipeComplianceHistory);
    on<FilterByMenuItem>(_onFilterByMenuItem);
    on<FilterByStatus>(_onFilterByStatus);
    on<FilterByDateRange>(_onFilterByDateRange);
    on<RefreshRecipeComplianceHistory>(_onRefreshRecipeComplianceHistory);
    on<ClearFilters>(_onClearFilters);
  }

  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  Future<void> _onLoadRecipeComplianceHistory(
    LoadRecipeComplianceHistory event,
    Emitter<RecipeComplianceHistoryState> emit,
  ) async {
    try {
      emit(const RecipeComplianceHistoryLoading());

      final response = await _repository.getRecipeComplianceHistory(
        branchId: branchId,
      );

      await response.when(
        success: (records) async {
          if (records.isEmpty) {
            emit(const RecipeComplianceHistoryEmpty());
            return;
          }

          final statusCounts = _calculateStatusCounts(records);
          final averageVariance = _calculateAverageVariance(records);

          emit(
            RecipeComplianceHistoryLoaded(
              allRecords: records,
              filteredRecords: records,
              statusCounts: statusCounts,
              averageVariance: averageVariance,
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(
            RecipeComplianceHistoryError(
              error: error.toString(),
              errorType: errorType,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        const RecipeComplianceHistoryError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: RecipeComplianceHistoryErrorType.general,
        ),
      );
    }
  }

  void _onFilterByMenuItem(
    FilterByMenuItem event,
    Emitter<RecipeComplianceHistoryState> emit,
  ) {
    if (state is! RecipeComplianceHistoryLoaded) return;

    final currentState = state as RecipeComplianceHistoryLoaded;
    final filtered = _applyFilters(
      currentState.allRecords,
      menuItemId: event.menuItemId,
      status: currentState.selectedStatus,
      startDate: currentState.startDate,
      endDate: currentState.endDate,
    );

    emit(
      currentState.copyWith(
        selectedMenuItemId: event.menuItemId,
        filteredRecords: filtered,
      ),
    );
  }

  void _onFilterByStatus(
    FilterByStatus event,
    Emitter<RecipeComplianceHistoryState> emit,
  ) {
    if (state is! RecipeComplianceHistoryLoaded) return;

    final currentState = state as RecipeComplianceHistoryLoaded;
    final filtered = _applyFilters(
      currentState.allRecords,
      menuItemId: currentState.selectedMenuItemId,
      status: event.status,
      startDate: currentState.startDate,
      endDate: currentState.endDate,
    );

    emit(
      currentState.copyWith(
        selectedStatus: event.status,
        filteredRecords: filtered,
      ),
    );
  }

  void _onFilterByDateRange(
    FilterByDateRange event,
    Emitter<RecipeComplianceHistoryState> emit,
  ) {
    if (state is! RecipeComplianceHistoryLoaded) return;

    final currentState = state as RecipeComplianceHistoryLoaded;
    final filtered = _applyFilters(
      currentState.allRecords,
      menuItemId: currentState.selectedMenuItemId,
      status: currentState.selectedStatus,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    emit(
      currentState.copyWith(
        startDate: event.startDate,
        endDate: event.endDate,
        filteredRecords: filtered,
      ),
    );
  }

  Future<void> _onRefreshRecipeComplianceHistory(
    RefreshRecipeComplianceHistory event,
    Emitter<RecipeComplianceHistoryState> emit,
  ) async {
    if (state is! RecipeComplianceHistoryLoaded) {
      add(const LoadRecipeComplianceHistory());
      return;
    }

    final currentState = state as RecipeComplianceHistoryLoaded;
    emit(
      RecipeComplianceHistoryRefreshing(currentData: currentState.allRecords),
    );

    final response = await _repository.getRecipeComplianceHistory(
      branchId: branchId,
      menuItemId: currentState.selectedMenuItemId,
      startDate: currentState.startDate,
      endDate: currentState.endDate,
    );

    await response.when(
      success: (records) async {
        if (records.isEmpty) {
          emit(const RecipeComplianceHistoryEmpty());
          return;
        }

        final filtered = _applyFilters(
          records,
          menuItemId: currentState.selectedMenuItemId,
          status: currentState.selectedStatus,
          startDate: currentState.startDate,
          endDate: currentState.endDate,
        );

        final statusCounts = _calculateStatusCounts(records);
        final averageVariance = _calculateAverageVariance(records);

        emit(
          RecipeComplianceHistoryLoaded(
            allRecords: records,
            filteredRecords: filtered,
            selectedMenuItemId: currentState.selectedMenuItemId,
            selectedStatus: currentState.selectedStatus,
            startDate: currentState.startDate,
            endDate: currentState.endDate,
            statusCounts: statusCounts,
            averageVariance: averageVariance,
          ),
        );
      },
      error: (error) async {
        final errorType = _determineErrorType(error.toString());
        emit(
          RecipeComplianceHistoryError(
            error: error.toString(),
            errorType: errorType,
          ),
        );
      },
    );
  }

  void _onClearFilters(
    ClearFilters event,
    Emitter<RecipeComplianceHistoryState> emit,
  ) {
    if (state is! RecipeComplianceHistoryLoaded) return;

    final currentState = state as RecipeComplianceHistoryLoaded;
    emit(
      currentState.copyWith(
        selectedMenuItemId: null,
        selectedStatus: null,
        startDate: null,
        endDate: null,
        filteredRecords: currentState.allRecords,
      ),
    );
  }

  List<RecipeComplianceResponse> _applyFilters(
    List<RecipeComplianceResponse> records, {
    String? menuItemId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var filtered = records;

    if (menuItemId != null && menuItemId.isNotEmpty) {
      filtered = filtered.where((r) => r.menuItemId == menuItemId).toList();
    }

    if (status != null && status.isNotEmpty) {
      filtered = filtered.where((r) => r.status == status).toList();
    }

    if (startDate != null) {
      filtered = filtered.where((r) {
        final checkDate = DateTime.parse(r.checkDate);
        return checkDate.isAfter(startDate) ||
            checkDate.isAtSameMomentAs(startDate);
      }).toList();
    }

    if (endDate != null) {
      filtered = filtered.where((r) {
        final checkDate = DateTime.parse(r.checkDate);
        return checkDate.isBefore(endDate) ||
            checkDate.isAtSameMomentAs(endDate);
      }).toList();
    }

    return filtered;
  }

  Map<String, int> _calculateStatusCounts(
    List<RecipeComplianceResponse> records,
  ) {
    final counts = <String, int>{};
    for (var record in records) {
      counts[record.status] = (counts[record.status] ?? 0) + 1;
    }
    return counts;
  }

  double _calculateAverageVariance(List<RecipeComplianceResponse> records) {
    if (records.isEmpty) return 0;

    final total = records.fold<double>(
      0,
      (sum, record) =>
          sum + (double.tryParse(record.variancePercent) ?? 0).abs(),
    );
    return total / records.length;
  }

  RecipeComplianceHistoryErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return RecipeComplianceHistoryErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return RecipeComplianceHistoryErrorType.timeout;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return RecipeComplianceHistoryErrorType.server;
    }

    if (lowercaseError.contains('format') ||
        lowercaseError.contains('validation')) {
      return RecipeComplianceHistoryErrorType.validation;
    }

    return RecipeComplianceHistoryErrorType.general;
  }
}
