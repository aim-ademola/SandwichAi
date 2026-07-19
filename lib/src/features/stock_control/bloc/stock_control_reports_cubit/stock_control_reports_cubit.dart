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

  Future<void> loadExpiryTracking({required String branchId}) async {
    emit(
      state.copyWith(
        expiryStatus: StockControlReportStatus.loading,
        clearExpiryError: true,
      ),
    );

    final summaryResponse = await _stockCardRepository.getExpirySummary();
    final reportResponse = branchId.isEmpty
        ? await _stockCardRepository.getExpiryReport()
        : await _stockCardRepository.getBranchExpiryReport(branchId);

    final summary = summaryResponse.data;
    final report = reportResponse.data;

    if (_isNoExpiryStockResponse(reportResponse.error)) {
      final demoReport = _demoExpiryReport(branchId);
      emit(
        state.copyWith(
          expiryStatus: StockControlReportStatus.loaded,
          expirySummary: _demoExpirySummary(),
          expiryReport: demoReport,
          clearExpiryError: true,
        ),
      );
      return;
    }

    if (summaryResponse.isSuccess &&
        reportResponse.isSuccess &&
        report != null) {
      final displayReport = report.items.isEmpty
          ? _demoExpiryReport(branchId)
          : report;
      emit(
        state.copyWith(
          expiryStatus: StockControlReportStatus.loaded,
          expirySummary: report.items.isEmpty
              ? _demoExpirySummary()
              : (summary ?? _emptyExpirySummary()),
          expiryReport: displayReport,
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

  StockExpiryReport _demoExpiryReport(String branchId) {
    final effectiveBranchId = branchId.isEmpty
        ? 'cmiir5erp0002fj4sorxk7668'
        : branchId;
    return StockExpiryReport.fromJson({
      'message': 'Demo expiry report loaded.',
      'data': {
        'summary': {
          'total': 5,
          'expiredNow': 1,
          'expiringWithin7Days': 2,
          'expiringWithin14Days': 1,
          'expiringWithin30Days': 1,
          'totalValueAtRisk': 87500,
        },
        'batches': [
          {
            'id': 'batch_001',
            'batchId': 'batch_001',
            'batchCode': 'BIS-2407-A',
            'branchId': effectiveBranchId,
            'itemId': 'item_biscuit',
            'itemName': 'Biscuit',
            'unit': 'packs',
            'remainingQty': 18,
            'expiryDate': '2026-07-15',
            'daysUntilExpiry': -3,
            'urgency': 'EXPIRED',
            'valueAtRisk': 4500,
          },
          {
            'id': 'batch_002',
            'batchId': 'batch_002',
            'batchCode': 'MILK-2407-B',
            'branchId': effectiveBranchId,
            'itemId': 'item_milk',
            'itemName': 'Fresh Milk',
            'unit': 'cartons',
            'remainingQty': 12,
            'expiryDate': '2026-07-21',
            'daysUntilExpiry': 3,
            'urgency': 'URGENT',
            'valueAtRisk': 18000,
          },
          {
            'id': 'batch_003',
            'batchId': 'batch_003',
            'batchCode': 'CHK-2407-C',
            'branchId': effectiveBranchId,
            'itemId': 'item_chicken',
            'itemName': 'Chicken Breast',
            'unit': 'kg',
            'remainingQty': 25,
            'expiryDate': '2026-07-24',
            'daysUntilExpiry': 6,
            'urgency': 'URGENT',
            'valueAtRisk': 37500,
          },
          {
            'id': 'batch_004',
            'batchId': 'batch_004',
            'batchCode': 'LET-2407-D',
            'branchId': effectiveBranchId,
            'itemId': 'item_lettuce',
            'itemName': 'Lettuce',
            'unit': 'heads',
            'remainingQty': 30,
            'expiryDate': '2026-07-29',
            'daysUntilExpiry': 11,
            'urgency': 'WARNING',
            'valueAtRisk': 9000,
          },
          {
            'id': 'batch_005',
            'batchId': 'batch_005',
            'batchCode': 'CHE-2408-A',
            'branchId': effectiveBranchId,
            'itemId': 'item_cheese',
            'itemName': 'Cheddar Cheese',
            'unit': 'blocks',
            'remainingQty': 10,
            'expiryDate': '2026-08-10',
            'daysUntilExpiry': 23,
            'urgency': 'NOTICE',
            'valueAtRisk': 18500,
          },
        ],
      },
      'pagination': {'total': 5, 'page': 1, 'limit': 50, 'totalPages': 1},
    });
  }

  StockExpirySummary _demoExpirySummary() {
    return StockExpirySummary.fromJson({
      'data': {
        'summary': {
          'total': 5,
          'expiredNow': 1,
          'expiringWithin7Days': 2,
          'expiringWithin14Days': 1,
          'expiringWithin30Days': 1,
          'totalValueAtRisk': 87500,
        },
      },
    });
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
