import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';

import 'package:sandwich_ai/src/features/stock_control/bloc/wastage_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/wastage_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/wastage_log_repo.dart';

class WasteLogsBloc extends Bloc<WasteLogsEvent, WasteLogsState> {
  final WasteLogsRepositoryInterface _repository;
  String branchId = '';

  WasteLogsBloc({required WasteLogsRepositoryInterface repository})
    : _repository = repository,
      super(const WasteLogsInitial()) {
    _getBranchId();
    on<LoadWasteLogs>(_onLoadWasteLogs);
    on<CreateWasteLog>(_onCreateWasteLog);
    on<FilterByReason>(_onFilterByReason);
    on<FilterByDateRange>(_onFilterByDateRange);
    on<RefreshWasteLogs>(_onRefreshWasteLogs);
  }

  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    branchId = id;
  }

  Future<void> _onLoadWasteLogs(
    LoadWasteLogs event,
    Emitter<WasteLogsState> emit,
  ) async {
    try {
      emit(const WasteLogsLoading());

      final response = await _repository.getWasteLogs(
        branchId: branchId.isNotEmpty ? branchId : event.branchId,
        reason: event.reason,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      await response.when(
        success: (data) async {
          if (!data.isValid) {
            emit(const WasteLogsEmpty());
            return;
          }

          emit(
            WasteLogsLoaded(
              response: data,
              selectedReason: event.reason,
              startDate: event.startDate,
              endDate: event.endDate,
            ),
          );
        },
        error: (error) async {
          emit(WasteLogsError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        WasteLogsError(error: 'An unexpected error occurred: ${e.toString()}'),
      );
    }
  }

  Future<void> _onCreateWasteLog(
    CreateWasteLog event,
    Emitter<WasteLogsState> emit,
  ) async {
    try {
      emit(const WasteLogCreating());

      final response = await _repository.createWasteLog(event.request);

      await response.when(
        success: (data) async {
          emit(WasteLogCreated(item: data));

          // Reload waste logs
          add(LoadWasteLogs(branchId: branchId));
        },
        error: (error) async {
          emit(WasteLogCreateError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        WasteLogCreateError(
          error: 'Failed to create waste log: ${e.toString()}',
        ),
      );
    }
  }

  void _onFilterByReason(FilterByReason event, Emitter<WasteLogsState> emit) {
    if (state is! WasteLogsLoaded) return;

    final currentState = state as WasteLogsLoaded;

    add(
      LoadWasteLogs(
        branchId: branchId,
        reason: event.reason,
        startDate: currentState.startDate,
        endDate: currentState.endDate,
      ),
    );
  }

  void _onFilterByDateRange(
    FilterByDateRange event,
    Emitter<WasteLogsState> emit,
  ) {
    if (state is! WasteLogsLoaded) return;

    final currentState = state as WasteLogsLoaded;

    add(
      LoadWasteLogs(
        branchId: branchId,
        reason: currentState.selectedReason,
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );
  }

  Future<void> _onRefreshWasteLogs(
    RefreshWasteLogs event,
    Emitter<WasteLogsState> emit,
  ) async {
    String? reason;
    String? startDate;
    String? endDate;

    if (state is WasteLogsLoaded) {
      final currentState = state as WasteLogsLoaded;
      reason = currentState.selectedReason;
      startDate = currentState.startDate;
      endDate = currentState.endDate;
    }

    add(
      LoadWasteLogs(
        branchId: branchId,
        reason: reason,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }
}
