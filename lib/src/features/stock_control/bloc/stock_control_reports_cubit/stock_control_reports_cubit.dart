import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_control_reports_cubit/stock_control_reports_state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/stock_card_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/add_branch_stock.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/reorder_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/stock_card_repo.dart';

class StockControlReportsCubit extends Cubit<StockControlReportsState> {
  final StockCardRepositoryInterface _stockCardRepository;
  final AddBranchStockRepositoryInterface _branchStockRepository;
  final ReorderRepositoryInterface _reorderRepository;

  StockControlReportsCubit({
    required StockCardRepositoryInterface stockCardRepository,
    required AddBranchStockRepositoryInterface branchStockRepository,
    required ReorderRepositoryInterface reorderRepository,
  }) : _stockCardRepository = stockCardRepository,
       _branchStockRepository = branchStockRepository,
       _reorderRepository = reorderRepository,
       super(const StockControlReportsState());

  Future<void> loadExpiryTracking({
    required String branchId,
    int? withinDays,
    bool includeExpired = false,
  }) async {
    emit(
      state.copyWith(
        expiryStatus: StockControlReportStatus.loading,
        clearExpiryError: true,
      ),
    );

    final summaryResponse = await _stockCardRepository.getExpirySummary(
      branchId: branchId,
    );
    final reportResponse = branchId.isEmpty
        ? await _stockCardRepository.getExpiryReport(
            withinDays: withinDays,
            includeExpired: includeExpired,
          )
        : await _stockCardRepository.getBranchExpiryReport(
            branchId,
            withinDays: withinDays,
            includeExpired: includeExpired,
          );

    final summary = summaryResponse.data;
    final report = reportResponse.data;

    if (_isNoExpiryStockResponse(reportResponse.error)) {
      emit(
        state.copyWith(
          expiryStatus: StockControlReportStatus.empty,
          expirySummary: summary ?? _emptyExpirySummary(),
          clearExpiryError: true,
        ),
      );
      return;
    }

    if (summaryResponse.isSuccess &&
        reportResponse.isSuccess &&
        report != null) {
      emit(
        state.copyWith(
          expiryStatus: report.items.isEmpty
              ? StockControlReportStatus.empty
              : StockControlReportStatus.loaded,
          expirySummary: summary ?? _emptyExpirySummary(),
          expiryReport: report,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        expiryStatus: StockControlReportStatus.error,
        expiryError:
            reportResponse.error?.toString() ??
            summaryResponse.error?.toString() ??
            'Failed to load expiry tracking.',
      ),
    );
  }

  bool _isNoExpiryStockResponse(NetworkException? error) {
    if (error == null) return false;
    final message = error.message.toLowerCase();
    return error.statusCode == 404 &&
        (message.contains('stock record not found') ||
            message.contains('not found'));
  }

  StockExpirySummary _emptyExpirySummary() {
    return const StockExpirySummary(
      expired: 0,
      expiringSoon: 0,
      expiringThisWeek: 0,
      expiringThisMonth: 0,
      raw: {},
    );
  }

  Future<void> loadLockedStock() async {
    emit(
      state.copyWith(
        lockedStatus: StockControlReportStatus.loading,
        clearLockedError: true,
      ),
    );

    final response = await _branchStockRepository.getLockedStock();
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            lockedStatus: data.items.isEmpty
                ? StockControlReportStatus.empty
                : StockControlReportStatus.loaded,
            lockedStock: data,
          ),
        );
      },
      error: (error) {
        emit(
          state.copyWith(
            lockedStatus: StockControlReportStatus.error,
            lockedError: error.toString(),
          ),
        );
      },
    );
  }

  Future<void> loadNegativeStockReport() async {
    emit(
      state.copyWith(
        negativeStatus: StockControlReportStatus.loading,
        clearNegativeError: true,
      ),
    );

    final response = await _branchStockRepository.getNegativeStockReport();
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            negativeStatus: data.items.isEmpty
                ? StockControlReportStatus.empty
                : StockControlReportStatus.loaded,
            negativeStockReport: data,
          ),
        );
      },
      error: (error) {
        emit(
          state.copyWith(
            negativeStatus: StockControlReportStatus.error,
            negativeError: error.toString(),
          ),
        );
      },
    );
  }

  Future<void> loadReorderReport(String branchId) async {
    emit(
      state.copyWith(
        reorderStatus: StockControlReportStatus.loading,
        clearReorderError: true,
      ),
    );

    final response = await _reorderRepository.getReorderReport(branchId);
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            reorderStatus: data.items.isEmpty
                ? StockControlReportStatus.empty
                : StockControlReportStatus.loaded,
            reorderReport: data,
          ),
        );
      },
      error: (error) {
        emit(
          state.copyWith(
            reorderStatus: StockControlReportStatus.error,
            reorderError: error.toString(),
          ),
        );
      },
    );
  }

  Future<bool> acknowledgeReorder(String branchStockId) async {
    final response = await _reorderRepository.acknowledgeReorder(branchStockId);
    if (!response.isSuccess) return false;
    emit(state.copyWith(clearReorderError: true));
    return true;
  }

  Future<void> loadMovementTrends({String? branchId}) async {
    emit(
      state.copyWith(
        movementStatus: StockControlReportStatus.loading,
        clearMovementError: true,
      ),
    );

    final response = await _stockCardRepository.getMovementTrends(
      branchId: branchId,
    );
    response.when(
      success: (data) {
        emit(
          state.copyWith(
            movementStatus: data.trends.isEmpty
                ? StockControlReportStatus.empty
                : StockControlReportStatus.loaded,
            movementTrends: data,
          ),
        );
      },
      error: (error) {
        emit(
          state.copyWith(
            movementStatus: StockControlReportStatus.error,
            movementError: error.toString(),
          ),
        );
      },
    );
  }
}
