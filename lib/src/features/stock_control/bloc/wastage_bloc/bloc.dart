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
    on<LoadWasteLogs>(_onLoadWasteLogs);
    on<CreateWasteLog>(_onCreateWasteLog);
    on<FilterByReason>(_onFilterByReason);
    on<FilterByDateRange>(_onFilterByDateRange);
    on<RefreshWasteLogs>(_onRefreshWasteLogs);
    _init();
  }

  // ── Init: resolve branchId first, then load ──────────────────────────
  Future<void> _init() async {
    branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    add(LoadWasteLogs(branchId: branchId));
  }

  // ── Load (core method everything delegates to) ────────────────────────
  Future<void> _onLoadWasteLogs(
    LoadWasteLogs event,
    Emitter<WasteLogsState> emit,
  ) async {
    try {
      emit(const WasteLogsLoading());

      final response = await _repository.getWasteLogs(
        branchId: branchId,
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
      emit(WasteLogsError(error: 'Unexpected error: $e'));
    }
  }

  // ── Filter by reason ──────────────────────────────────────────────────
  Future<void> _onFilterByReason(
    FilterByReason event,
    Emitter<WasteLogsState> emit,
  ) async {
    final current = state is WasteLogsLoaded ? state as WasteLogsLoaded : null;

    await _onLoadWasteLogs(
      LoadWasteLogs(
        branchId: branchId,
        reason: event.reason, // null = clear reason filter
        startDate: current?.startDate,
        endDate: current?.endDate,
      ),
      emit,
    );
  }

  // ── Filter by date range ──────────────────────────────────────────────
  Future<void> _onFilterByDateRange(
    FilterByDateRange event,
    Emitter<WasteLogsState> emit,
  ) async {
    final current = state is WasteLogsLoaded ? state as WasteLogsLoaded : null;

    await _onLoadWasteLogs(
      LoadWasteLogs(
        branchId: branchId,
        reason: current?.selectedReason,
        startDate: event.startDate, // null = clear date filter
        endDate: event.endDate,
      ),
      emit,
    );
  }

  // ── Refresh (clears all filters) ──────────────────────────────────────
  Future<void> _onRefreshWasteLogs(
    RefreshWasteLogs event,
    Emitter<WasteLogsState> emit,
  ) async {
    await _onLoadWasteLogs(
      LoadWasteLogs(branchId: branchId), // no filters = full reload
      emit,
    );
  }

  // ── Create ────────────────────────────────────────────────────────────
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
          add(LoadWasteLogs(branchId: branchId));
        },
        error: (error) async {
          emit(WasteLogCreateError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(WasteLogCreateError(error: 'Failed to create: $e'));
    }
  }
}
