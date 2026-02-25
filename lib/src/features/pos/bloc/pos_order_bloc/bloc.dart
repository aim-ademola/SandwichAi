import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_order_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/service/printer_service.dart';
import 'package:sandwich_ai/src/features/pos/helpers/printer_config_helper.dart'
    show PrinterCacheExtension;

class PosOrderBloc extends Bloc<PosOrderEvent, PosOrderState> {
  final PosOrderRepositoryInterface _repository;
  final PrinterService _printerService;
  String branchId = '';
  String employeeId = '';

  PosOrderBloc({
    required PosOrderRepositoryInterface repository,
    PrinterService? printerService,
  }) : _repository = repository,
       _printerService = printerService ?? PrinterService(),
       super(const PosOrderInitial()) {
    _initializeIds();
    _loadSavedPrinters();

    on<CreatePosOrder>(_onCreatePosOrder);
    on<ResetPosOrderState>(_onResetPosOrderState);
  }

  void _initializeIds() async {
    branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    employeeId = await AuthCacheHelper.instance.getEmpID() ?? '';
  }

  /// Load saved printer configurations from cache
  Future<void> _loadSavedPrinters() async {
    try {
      final savedPrinters = await _loadPrinterConfigs();
      if (savedPrinters != null && savedPrinters.isNotEmpty) {
        _printerService.clearPrinters();
        for (final config in savedPrinters) {
          _printerService.addPrinter(config);
        }
        AppLogger.log('Loaded ${savedPrinters.length} saved printers');
      }
    } catch (e) {
      AppLogger.log('Error loading saved printers: $e');
    }
  }

  /// Load printer configurations from cache
  Future<List<PrinterConfig>?> _loadPrinterConfigs() async {
    try {
      // You can use your existing cache helper or shared preferences
      // Example using a hypothetical cache method:
      final printerData = await AuthCacheHelper.instance.getPrinterConfigs();

      return printerData
          .map((json) => PrinterConfig.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.log('Error loading printer configs: $e');
    }
    return null;
  }

  Future<void> _onCreatePosOrder(
    CreatePosOrder event,
    Emitter<PosOrderState> emit,
  ) async {
    try {
      emit(const PosOrderCreating());

      // Ensure IDs are loaded
      if (branchId.isEmpty) {
        branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
      }
      if (employeeId.isEmpty) {
        employeeId = await AuthCacheHelper.instance.getEmpID() ?? '';
      }

      // Validate required fields
      if (branchId.isEmpty) {
        emit(
          const PosOrderError(
            error: 'Branch ID not found. Please login again.',
          ),
        );
        return;
      }

      if (employeeId.isEmpty) {
        emit(
          const PosOrderError(
            error: 'Employee ID not found. Please login again.',
          ),
        );
        return;
      }

      if (event.items.isEmpty) {
        emit(const PosOrderError(error: 'Cannot create order with no items.'));
        return;
      }

      final response = await _repository.createPosOrder(
        branchId: branchId,
        orderType: event.orderType,
        tableNumber: event.tableNumber,
        customerName: event.customerName,
        customerPhone: event.customerPhone,
        items: event.items,
        discount: event.discount,
        specialInstructions: event.specialInstructions,
        takenBy: employeeId,
      );

      await response.when(
        success: (order) async {
          emit(PosOrderCreated(order: order));

          // Print to kitchen printers (supports all connection types)
          await _printOrderToKitchen(order);
        },
        error: (error) async {
          emit(PosOrderError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(
        PosOrderError(error: 'An unexpected error occurred: ${e.toString()}'),
      );
    }
  }

  /// Print order to all configured kitchen printers
  /// Supports Network, Bluetooth, USB, and Serial printers
  Future<void> _printOrderToKitchen(dynamic order) async {
    if (_printerService.printers.isEmpty) {
      AppLogger.log('No printers configured - skipping print');
      return;
    }

    try {
      AppLogger.log(
        'Printing to ${_printerService.printers.length} kitchen printer(s)',
      );

      final printResults = await _printerService.printOrderToKitchen(order);

      // Categorize results by connection type
      final resultsByType = <String, List<String>>{};

      for (final printer in _printerService.printers) {
        final success = printResults[printer.name] ?? false;
        final typeLabel = _getConnectionTypeLabel(printer.connectionType);

        if (!resultsByType.containsKey(typeLabel)) {
          resultsByType[typeLabel] = [];
        }

        resultsByType[typeLabel]!.add(
          '${printer.name}: ${success ? "✓" : "✗"}',
        );
      }

      // Log detailed results
      for (final entry in resultsByType.entries) {
        AppLogger.log('${entry.key} Printers:');
        for (final result in entry.value) {
          AppLogger.log('  $result');
        }
      }

      // Check for failures
      final failedPrinters = printResults.entries
          .where((e) => !e.value)
          .map((e) => e.key)
          .toList();

      final successfulPrinters = printResults.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      if (failedPrinters.isNotEmpty) {
        AppLogger.log('Failed to print to: ${failedPrinters.join(", ")}');

        if (successfulPrinters.isEmpty) {
          // All printers failed - this is critical
          AppLogger.log('CRITICAL: All printers failed!');
          // You could emit a warning state or show a notification
        } else {
          // Some printers succeeded
          AppLogger.log(
            'Successfully printed to: ${successfulPrinters.join(", ")}',
          );
        }
      } else {
        AppLogger.log(
          'Successfully printed to all ${printResults.length} printer(s)',
        );
      }
    } catch (e) {
      AppLogger.log('Error printing order: $e');
      // Don't fail the order creation if printing fails
      // But log it for monitoring
    }
  }

  String _getConnectionTypeLabel(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.network:
        return 'Network';
      case PrinterConnectionType.bluetooth:
        return 'Bluetooth';
      case PrinterConnectionType.usb:
        return 'USB';
      case PrinterConnectionType.serial:
        return 'Serial';
    }
  }

  void _onResetPosOrderState(
    ResetPosOrderState event,
    Emitter<PosOrderState> emit,
  ) {
    emit(const PosOrderInitial());
  }

  @override
  Future<void> close() {
    // Cleanup if needed
    return super.close();
  }
}
