import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/add_branch_stock_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/add_branch_stock_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/add_branch_stock.dart';

class AddBranchStockBloc extends Bloc<BranchStockEvent, BranchStockState> {
  final AddBranchStockRepositoryInterface _repository;

  AddBranchStockBloc({required AddBranchStockRepositoryInterface repository})
    : _repository = repository,
      super(const BranchStockInitial()) {
    on<CreateBranchStock>(_onCreateBranchStock);
    on<UpdateBranchStock>(_onUpdateBranchStock);
    on<DeleteBranchStock>(_onDeleteBranchStock);
    on<AdjustBranchStock>(_onAdjustBranchStock);
    on<ValidateCurrentStock>(_onValidateCurrentStock);
    on<ValidateReorderLevel>(_onValidateReorderLevel);
    on<ValidateMaxLevel>(_onValidateMaxLevel);
    on<ValidateUnitCost>(_onValidateUnitCost);
    on<ValidateExpiryDate>(_onValidateExpiryDate);
    on<ValidateAdjustmentQuantity>(_onValidateAdjustmentQuantity);
    on<ResetBranchStockState>(_onResetBranchStockState);
  }

  /// Handles creating branch stock
  Future<void> _onCreateBranchStock(
    CreateBranchStock event,
    Emitter<BranchStockState> emit,
  ) async {
    try {
      final validationErrors = _validateAllFields(event.request);

      if (validationErrors.values.any((error) => error != null)) {
        emit(
          BranchStockValidation(
            currentStockError: validationErrors['currentStock'],
            reorderLevelError: validationErrors['reorderLevel'],
            maxLevelError: validationErrors['maxLevel'],
            unitCostError: validationErrors['unitCost'],
            expiryDateError: validationErrors['expiryDate'],
          ),
        );
        return;
      }

      emit(const BranchStockLoading());

      final response = await _repository.createBranchStock(event.request);

      await response.when(
        success: (data) async {
          if (!data.isValid) {
            emit(
              const BranchStockError(
                error: 'Invalid response received. Please try again.',
                errorType: BranchStockErrorType.validation,
              ),
            );
            return;
          }

          emit(
            BranchStockSuccess(
              response: data,
              message: data.message.isNotEmpty
                  ? data.message
                  : 'Stock item added successfully',
              isUpdate: false,
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(BranchStockError(error: error.toString(), errorType: errorType));
        },
      );
    } catch (e) {
      emit(
        const BranchStockError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: BranchStockErrorType.general,
        ),
      );
    }
  }

  /// Handles updating branch stock
  Future<void> _onUpdateBranchStock(
    UpdateBranchStock event,
    Emitter<BranchStockState> emit,
  ) async {
    try {
      final validationErrors = _validateAllFields(event.request);

      if (validationErrors.values.any((error) => error != null)) {
        emit(
          BranchStockValidation(
            currentStockError: validationErrors['currentStock'],
            reorderLevelError: validationErrors['reorderLevel'],
            maxLevelError: validationErrors['maxLevel'],
            unitCostError: validationErrors['unitCost'],
            expiryDateError: validationErrors['expiryDate'],
          ),
        );
        return;
      }

      emit(const BranchStockLoading());

      final response = await _repository.updateBranchStock(
        event.stockId,
        event.request,
      );

      await response.when(
        success: (data) async {
          if (!data.isValid) {
            emit(
              const BranchStockError(
                error: 'Invalid response received. Please try again.',
                errorType: BranchStockErrorType.validation,
              ),
            );
            return;
          }

          emit(
            BranchStockSuccess(
              response: data,
              message: data.message.isNotEmpty
                  ? data.message
                  : 'Stock item updated successfully',
              isUpdate: true,
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(BranchStockError(error: error.toString(), errorType: errorType));
        },
      );
    } catch (e) {
      emit(
        const BranchStockError(
          error: 'An unexpected error occurred. Please try again.',
          errorType: BranchStockErrorType.general,
        ),
      );
    }
  }

  /// Handles deleting branch stock
  Future<void> _onDeleteBranchStock(
    DeleteBranchStock event,
    Emitter<BranchStockState> emit,
  ) async {
    try {
      emit(const BranchStockLoading());

      final response = await _repository.deleteBranchStock(event.stockId);

      await response.when(
        success: (data) async {
          emit(
            BranchStockSuccess(
              message: 'Stock item "${event.itemName}" deleted successfully',
              isDelete: true,
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(BranchStockError(error: error.toString(), errorType: errorType));
        },
      );
    } catch (e) {
      emit(
        const BranchStockError(
          error: 'Failed to delete stock item. Please try again.',
          errorType: BranchStockErrorType.general,
        ),
      );
    }
  }

  /// Handles adjusting branch stock
  Future<void> _onAdjustBranchStock(
    AdjustBranchStock event,
    Emitter<BranchStockState> emit,
  ) async {
    try {
      final quantityError = _validateAdjustmentQuantity(
        event.request.quantity.toString(),
      );

      if (quantityError != null) {
        emit(BranchStockValidation(adjustmentQuantityError: quantityError));
        return;
      }

      emit(const BranchStockLoading());

      final response = await _repository.adjustBranchStock(
        event.stockId,
        event.request,
      );

      await response.when(
        success: (data) async {
          if (!data.isValid) {
            emit(
              const BranchStockError(
                error: 'Invalid response received. Please try again.',
                errorType: BranchStockErrorType.validation,
              ),
            );
            return;
          }

          emit(
            BranchStockSuccess(
              adjustmentResponse: data,
              message: data.message.isNotEmpty
                  ? data.message
                  : 'Stock adjusted successfully',
              isAdjustment: true,
            ),
          );
        },
        error: (error) async {
          final errorType = _determineErrorType(error.toString());
          emit(BranchStockError(error: error.toString(), errorType: errorType));
        },
      );
    } catch (e) {
      emit(
        const BranchStockError(
          error: 'Failed to adjust stock. Please try again.',
          errorType: BranchStockErrorType.general,
        ),
      );
    }
  }

  /// Validates current stock field
  void _onValidateCurrentStock(
    ValidateCurrentStock event,
    Emitter<BranchStockState> emit,
  ) {
    if (state is! BranchStockInitial) return;

    final currentState = state as BranchStockInitial;
    final error = _validateCurrentStock(event.value);

    emit(
      currentState.copyWith(
        currentStockError: error,
        clearCurrentStockError: error == null,
      ),
    );
  }

  /// Validates reorder level field
  void _onValidateReorderLevel(
    ValidateReorderLevel event,
    Emitter<BranchStockState> emit,
  ) {
    if (state is! BranchStockInitial) return;

    final currentState = state as BranchStockInitial;
    final error = _validateReorderLevel(event.value);

    emit(
      currentState.copyWith(
        reorderLevelError: error,
        clearReorderLevelError: error == null,
      ),
    );
  }

  /// Validates max level field
  void _onValidateMaxLevel(
    ValidateMaxLevel event,
    Emitter<BranchStockState> emit,
  ) {
    if (state is! BranchStockInitial) return;

    final currentState = state as BranchStockInitial;
    final error = _validateMaxLevel(event.value);

    emit(
      currentState.copyWith(
        maxLevelError: error,
        clearMaxLevelError: error == null,
      ),
    );
  }

  /// Validates unit cost field
  void _onValidateUnitCost(
    ValidateUnitCost event,
    Emitter<BranchStockState> emit,
  ) {
    if (state is! BranchStockInitial) return;

    final currentState = state as BranchStockInitial;
    final error = _validateUnitCost(event.value);

    emit(
      currentState.copyWith(
        unitCostError: error,
        clearUnitCostError: error == null,
      ),
    );
  }

  /// Validates expiry date field
  void _onValidateExpiryDate(
    ValidateExpiryDate event,
    Emitter<BranchStockState> emit,
  ) {
    if (state is! BranchStockInitial) return;

    final currentState = state as BranchStockInitial;
    final error = _validateExpiryDate(event.value);

    emit(
      currentState.copyWith(
        expiryDateError: error,
        clearExpiryDateError: error == null,
      ),
    );
  }

  /// Validates adjustment quantity field
  void _onValidateAdjustmentQuantity(
    ValidateAdjustmentQuantity event,
    Emitter<BranchStockState> emit,
  ) {
    if (state is! BranchStockInitial) return;

    final currentState = state as BranchStockInitial;
    final error = _validateAdjustmentQuantity(event.value);

    emit(
      currentState.copyWith(
        adjustmentQuantityError: error,
        clearAdjustmentQuantityError: error == null,
      ),
    );
  }

  /// Resets state
  void _onResetBranchStockState(
    ResetBranchStockState event,
    Emitter<BranchStockState> emit,
  ) {
    emit(const BranchStockInitial());
  }

  /// Validate all fields at once
  Map<String, String?> _validateAllFields(dynamic request) {
    return {
      'currentStock': _validateCurrentStock(request.currentStock.toString()),
      'reorderLevel': _validateReorderLevel(request.reorderLevel.toString()),
      'maxLevel': _validateMaxLevel(request.maxLevel.toString()),
      'unitCost': _validateUnitCost(request.unitCost.toString()),
      'expiryDate': _validateExpiryDate(request.expiryDate),
    };
  }

  /// Current stock validation
  String? _validateCurrentStock(String value) {
    if (value.isEmpty) return 'Current stock is required';
    final stock = int.tryParse(value);
    if (stock == null) return 'Please enter a valid number';
    if (stock < 0) return 'Stock cannot be negative';
    return null;
  }

  /// Reorder level validation
  String? _validateReorderLevel(String value) {
    if (value.isEmpty) return 'Reorder level is required';
    final level = int.tryParse(value);
    if (level == null) return 'Please enter a valid number';
    if (level < 0) return 'Reorder level cannot be negative';
    return null;
  }

  /// Max level validation
  String? _validateMaxLevel(String value) {
    if (value.isEmpty) return 'Max level is required';
    final level = int.tryParse(value);
    if (level == null) return 'Please enter a valid number';
    if (level <= 0) return 'Max level must be greater than zero';
    return null;
  }

  /// Unit cost validation
  String? _validateUnitCost(String value) {
    if (value.isEmpty) return 'Unit cost is required';
    final cost = double.tryParse(value);
    if (cost == null) return 'Please enter a valid amount';
    if (cost < 0) return 'Unit cost cannot be negative';
    return null;
  }

  /// Expiry date validation
  String? _validateExpiryDate(String value) {
    if (value.isEmpty) return 'Expiry date is required';
    try {
      final date = DateTime.parse(value);
      if (date.isBefore(DateTime.now())) {
        return 'Expiry date must be in the future';
      }
    } catch (e) {
      return 'Invalid date format';
    }
    return null;
  }

  /// Adjustment quantity validation
  String? _validateAdjustmentQuantity(String value) {
    if (value.isEmpty) return 'Quantity is required';
    final quantity = int.tryParse(value);
    if (quantity == null) return 'Please enter a valid number';
    if (quantity <= 0) return 'Quantity must be greater than zero';
    return null;
  }

  /// Determines error type from error message
  BranchStockErrorType _determineErrorType(String error) {
    final lowercaseError = error.toLowerCase();

    if (lowercaseError.contains('network') ||
        lowercaseError.contains('connection') ||
        lowercaseError.contains('internet')) {
      return BranchStockErrorType.network;
    }

    if (lowercaseError.contains('timeout')) {
      return BranchStockErrorType.timeout;
    }

    if (lowercaseError.contains('invalid') ||
        lowercaseError.contains('validation') ||
        lowercaseError.contains('format')) {
      return BranchStockErrorType.validation;
    }

    if (lowercaseError.contains('server') ||
        lowercaseError.contains('500') ||
        lowercaseError.contains('503')) {
      return BranchStockErrorType.server;
    }

    return BranchStockErrorType.general;
  }
}
