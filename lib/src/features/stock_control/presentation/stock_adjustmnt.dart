import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/add_branch_stock_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/add_branch_stock_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/add_branch_stock.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final String stockId;
  final String itemName;
  final num currentStock;
  final String unit;
  final String performedBy;

  const StockAdjustmentDialog({
    super.key,
    required this.stockId,
    required this.itemName,
    required this.currentStock,
    required this.unit,
    required this.performedBy,
  });

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedType = 'ADD';
  double _calculatedStock = 0;

  @override
  void initState() {
    super.initState();
    _calculatedStock = widget.currentStock.toDouble();
    _quantityController.addListener(_updateCalculatedStock);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateCalculatedStock() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    setState(() {
      switch (_selectedType) {
        case 'ADD':
          _calculatedStock = widget.currentStock + quantity;
          break;
        case 'SUBTRACT':
          _calculatedStock = widget.currentStock - quantity;
          break;
        case 'SET':
          _calculatedStock = quantity;
          break;
      }
    });
  }

  void _handleAdjustment() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;

    if (quantity <= 0) {
      _showErrorSnackBar('Please enter a valid quantity');
      return;
    }

    if (_selectedType == 'SUBTRACT' && quantity > widget.currentStock) {
      _showErrorSnackBar('Cannot subtract more than current stock');
      return;
    }

    final request = StockAdjustmentRequest(
      type: _selectedType,
      quantity: quantity,
      note: _noteController.text.trim().isEmpty
          ? 'Stock adjustment via mobile app'
          : _noteController.text.trim(),
      performedBy: widget.performedBy,
    );

    context.read<AddBranchStockBloc>().add(
      AdjustBranchStock(stockId: widget.stockId, request: request),
    );

    Navigator.of(context).pop(true);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.modeError,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.modePrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppIcon(
                      Icons.tune_rounded,
                      color: context.modePrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adjust Stock',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: context.modeTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.itemName,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            color: context.modeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Current Stock Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.modeSurfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.modeBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Stock',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: context.modeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.currentStock} ${widget.unit}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: context.modeTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Adjustment Type
              Text(
                'Adjustment Type',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      'ADD',
                      Icons.add,
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton(
                      'SUBTRACT',
                      Icons.remove,
                      const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton(
                      'SET',
                      Icons.edit,
                      context.modePrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quantity Input
              Text(
                _selectedType == 'SET' ? 'New Quantity' : 'Quantity',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  color: context.modeTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: _selectedType == 'SET'
                      ? 'Enter new stock level'
                      : 'Enter quantity',
                  hintStyle: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: context.modeTextSecondary,
                  ),
                  suffixText: widget.unit,
                  suffixStyle: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextSecondary,
                  ),
                  filled: true,
                  fillColor: context.modeSurfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.modeBorder, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.modeBorder, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.modePrimary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Calculated Stock Preview
              if (_quantityController.text.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _calculatedStock < 0
                        ? const Color(0xFFFFEBEE)
                        : context.modePrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _calculatedStock < 0
                          ? const Color(0xFFEF4444)
                          : context.modePrimary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'New Stock Level',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _calculatedStock < 0
                              ? const Color(0xFFEF4444)
                              : context.modePrimary,
                        ),
                      ),
                      Text(
                        '$_calculatedStock ${widget.unit}',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _calculatedStock < 0
                              ? const Color(0xFFEF4444)
                              : context.modePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_quantityController.text.isNotEmpty)
                const SizedBox(height: 20),

              // Note Input
              Text(
                'Note (Optional)',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: context.modeTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a note about this adjustment...',
                  hintStyle: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: context.modeTextSecondary,
                  ),
                  filled: true,
                  fillColor: context.modeSurfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.modeBorder, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.modeBorder, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.modePrimary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: context.modeTextSecondary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.modeTextPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleAdjustment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.modePrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.modeTextInverse,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _updateCalculatedStock();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : context.modeSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : context.modeBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon,
              color: isSelected ? context.modeTextInverse : color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              type,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? context.modeTextInverse : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
