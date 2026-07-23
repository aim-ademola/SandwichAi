import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/processing/bloc/employee_bloc/employee_bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/product_intake_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/product_intake_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/product_intake_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/product_intake_model.dart'
    hide InventoryItem;

import 'package:sandwich_ai/src/features/stock_control/data/repo/inventory_items_repo.dart';

class CreateProductIntakeScreen extends StatefulWidget {
  const CreateProductIntakeScreen({super.key});

  @override
  State<CreateProductIntakeScreen> createState() =>
      _CreateProductIntakeScreenState();
}

class _CreateProductIntakeScreenState extends State<CreateProductIntakeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _issuedByController = TextEditingController();
  final _stockBatchIdController = TextEditingController();
  final _qtyReceivedController = TextEditingController();
  final _notesController = TextEditingController();
  final _inventorySearchController = TextEditingController();
  Timer? _inventorySearchDebounce;

  // State variables
  String branchId = '';
  String organizationId = '';
  InventoryItem? _selectedItem;
  Employee? _selectedEmployee;
  ProductType _selectedProductType = ProductType.rawMaterial;
  Unit _selectedUnit = Unit.kg;
  bool _qualityStatus = true;
  bool _isInventoryPickerOpen = false;
  List<InventoryItem> _allInventoryItems = [];
  List<InventoryItem> _filteredInventoryItems = [];

  @override
  void initState() {
    super.initState();
    _inventorySearchController.addListener(_onInventorySearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getBranchId();
    });
  }

  void _onInventorySearchChanged() {
    final rawQuery = _inventorySearchController.text.trim();
    final query = rawQuery.toLowerCase();
    setState(() {
      _filteredInventoryItems = query.isEmpty
          ? _allInventoryItems
          : _allInventoryItems.where((item) {
              return item.itemName.toLowerCase().contains(query) ||
                  item.category.toLowerCase().contains(query) ||
                  item.sku.toLowerCase().contains(query);
            }).toList();
    });

    if (!_isInventoryPickerOpen || organizationId.isEmpty) return;

    _inventorySearchDebounce?.cancel();
    _inventorySearchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;

      context.read<InventoryItemsBloc>().add(
        LoadInventoryItems(
          organizationId: organizationId,
          page: 1,
          limit: 100,
          search: rawQuery,
        ),
      );
    });
  }

  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    final orgId = await AuthCacheHelper.instance.getOrgId() ?? '';

    if (mounted) {
      setState(() {
        branchId = id;
        organizationId = orgId;
      });

      // Load inventory items - context is now available after first frame
      if (orgId.isNotEmpty) {
        AppLogger.log('Loading inventory items for org: $orgId'); // Debug
        context.read<InventoryItemsBloc>().add(
          LoadInventoryItems(organizationId: orgId, page: 1, limit: 100),
        );
      }
    }
  }

  @override
  void dispose() {
    _issuedByController.dispose();
    _stockBatchIdController.dispose();
    _qtyReceivedController.dispose();
    _notesController.dispose();
    _inventorySearchDebounce?.cancel();
    _inventorySearchController.dispose();
    super.dispose();
  }

  void _showProductTypeHelp() {
    _showHelpBottomSheet(
      title: 'Product Type Guide',
      subtitle: 'Understanding different types of products in your inventory',
      items: [
        HelpItem(
          'Raw Material',
          'Unprocessed ingredients or materials that will be used in production. Examples: Fresh vegetables, raw meat, flour, sugar.',
          Icons.grass,
        ),
        HelpItem(
          'Semi-Processed',
          'Partially processed materials that require further preparation. Examples: Marinated meat, pre-cut vegetables, prepared dough.',
          Icons.settings,
        ),
        HelpItem(
          'Finished Product',
          'Ready-to-sell items that have completed all processing. Examples: Packaged meals, baked goods, bottled sauces.',
          Icons.check_circle,
        ),
      ],
      tip:
          'Tip: Correctly categorizing products helps track inventory flow from raw materials to finished products.',
    );
  }

  void _showQualityStatusHelp() {
    _showHelpBottomSheet(
      title: 'Quality Status',
      subtitle: 'Ensure products meet your quality standards',
      items: [
        HelpItem(
          'Quality Passed',
          'Product meets all quality criteria: proper packaging, correct temperature, no damage, meets specifications.',
          Icons.check_circle_outline,
        ),
        HelpItem(
          'Quality Failed',
          'Product has issues: damaged packaging, incorrect temperature, expired, doesn\'t meet specifications. These items should be quarantined.',
          Icons.warning_outlined,
        ),
      ],
      tip:
          'Tip: Always inspect deliveries carefully. Failed quality checks help track supplier reliability.',
    );
  }

  void _showUnitHelp() {
    _showHelpBottomSheet(
      title: 'Unit of Measurement',
      subtitle: 'Select the appropriate measurement unit',
      items: [
        HelpItem(
          'Weight Units (KG, G)',
          'Use for items measured by weight. KG for larger quantities, G for smaller amounts.',
          Icons.scale,
        ),
        HelpItem(
          'Volume Units (L, ML)',
          'Use for liquids and pourable items. L for larger volumes, ML for smaller amounts.',
          Icons.water_drop,
        ),
        HelpItem(
          'Count Units (PIECES, BAGS, CARTONS, BOTTLES)',
          'Use for discrete items. Choose the unit that matches how items are packaged or counted.',
          Icons.inventory_2,
        ),
      ],
      tip:
          'Tip: Match the unit to how your supplier provides the product for accurate inventory tracking.',
    );
  }

  void _showHelpBottomSheet({
    required String title,
    required String subtitle,
    required List<HelpItem> items,
    String? tip,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: AppIcon(
                        Icons.close,
                        color: context.modeTextPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: context.modeTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ...items.map(
                  (item) =>
                      _buildHelpItem(item.title, item.description, item.icon),
                ),
                if (tip != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        AppIcon(
                          Icons.lightbulb_outline,
                          color: kPrimary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tip,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 13,
                              color: context.modeTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.modeSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.modeBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppIcon(icon, color: kPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.modeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: context.modeTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text, double fontSize) {
    return Text(
      text,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: fontSize + 2,
        fontWeight: FontWeight.w700,
        color: kPrimary,
      ),
    );
  }

  Widget _buildLabel(String text, double fontSize, {bool showHelp = false}) {
    return Row(
      children: [
        Text(
          text,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: context.modeTextPrimary,
          ),
        ),
        if (showHelp) const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required double labelFontSize,
    required double inputFontSize,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, labelFontSize),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          maxLines: maxLines,
          cursorColor: kPrimary,
          validator: validator,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: inputFontSize,
            color: context.modeTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: inputFontSize,
              color: context.modeTextMuted,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: context.modeSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.modeBorder, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.modeBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.modeError, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.modeError, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedItem == null) {
        _showErrorSnackBar('Please select an inventory item');
        return;
      }

      if (_selectedEmployee == null) {
        _showErrorSnackBar(
          'Please select an employee who received the product',
        );
        return;
      }

      final qtyReceived = double.tryParse(_qtyReceivedController.text);
      if (qtyReceived == null || qtyReceived <= 0) {
        _showErrorSnackBar('Please enter a valid quantity');
        return;
      }

      final request = CreateProductIntakeRequest(
        branchId: branchId,
        issuedBy: _issuedByController.text,
        stockBatchId: _stockBatchIdController.text,
        productName: _selectedItem!.itemName,
        productType: _selectedProductType,
        itemId: _selectedItem!.id,
        qtyReceived: qtyReceived,
        unit: _selectedUnit,
        qualityStatus: _qualityStatus,
        receivedBy: _selectedEmployee!.id,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      context.read<ProductIntakeBloc>().add(
        CreateProductIntake(request: request),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.modeError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.modeSuccess.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                Icons.check_circle,
                color: context.modeSuccess,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Success!'),
          ],
        ),
        content: Text(
          'Product intake has been recorded successfully.',
          style: WorkSansAppTextStyles.medium.copyWith(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ProductIntakeBloc>().add(ResetProductIntakeState());
              _resetForm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Create Another',
              style: WorkSansAppTextStyles.medium.copyWith(color: kWhite),
            ),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedItem = null;
      _selectedEmployee = null;
      _selectedProductType = ProductType.rawMaterial;
      _selectedUnit = Unit.kg;
      _qualityStatus = true;
      _isInventoryPickerOpen = false;
      _inventorySearchController.clear();
      _issuedByController.clear();
      _stockBatchIdController.clear();
      _qtyReceivedController.clear();
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProductIntakeBloc, ProductIntakeState>(
          listener: (context, state) {
            if (state is ProductIntakeCreated) {
              _showSuccessDialog();
            } else if (state is ProductIntakeError) {
              String message = 'Failed to create product intake';
              switch (state.errorType) {
                case ProductIntakeErrorType.network:
                  message =
                      'Network error. Please check your internet connection.';
                  break;
                case ProductIntakeErrorType.timeout:
                  message = 'Request timed out. Please try again.';
                  break;
                case ProductIntakeErrorType.server:
                  message = 'Server error. Please try again later.';
                  break;
                case ProductIntakeErrorType.validation:
                  message = state.error;
                  break;
                case ProductIntakeErrorType.general:
                  message = state.error;
                  break;
              }
              _showErrorSnackBar(message);
            }
          },
        ),
        BlocListener<InventoryItemsBloc, InventoryItemsState>(
          listener: (context, state) {
            if (state is InventoryItemsLoaded) {
              final query = _inventorySearchController.text
                  .trim()
                  .toLowerCase();
              setState(() {
                _allInventoryItems = state.items;
                _filteredInventoryItems = query.isEmpty
                    ? state.items
                    : state.items.where((item) {
                        return item.itemName.toLowerCase().contains(query) ||
                            item.category.toLowerCase().contains(query) ||
                            item.sku.toLowerCase().contains(query);
                      }).toList();
              });
            } else if (state is InventoryItemsError) {
              _showErrorSnackBar(
                'Failed to load inventory items: ${state.error}',
              );
            }
          },
        ),
      ],
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<ProductIntakeBloc, ProductIntakeState>(
      builder: (context, productIntakeState) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = _getHorizontalPadding(
              constraints.maxWidth,
            );
            final maxContentWidth = _getMaxContentWidth(constraints.maxWidth);
            final inputFontSize = _getInputFontSize(constraints.maxWidth);
            final labelFontSize = _getLabelFontSize(constraints.maxWidth);
            final buttonFontSize = _getButtonFontSize(constraints.maxWidth);

            return Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),

                            // Basic Information Section
                            _buildSectionHeader(
                              'Basic Information',
                              labelFontSize,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _issuedByController,
                              label: 'Issued By / Batch Reference',
                              labelFontSize: labelFontSize,
                              inputFontSize: inputFontSize,
                              hintText: 'e.g., Batch SC2201',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter batch reference';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _stockBatchIdController,
                              label: 'Stock Batch ID',
                              labelFontSize: labelFontSize,
                              inputFontSize: inputFontSize,
                              hintText: 'e.g., batch_123456',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter stock batch ID';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Product Details Section
                            _buildSectionHeader(
                              'Product Details',
                              labelFontSize,
                            ),
                            const SizedBox(height: 16),

                            // Inventory Item Dropdown
                            _buildInventoryItemDropdown(
                              labelFontSize,
                              inputFontSize,
                            ),
                            const SizedBox(height: 16),

                            // Product Type Dropdown with Help
                            Row(
                              children: [
                                _buildLabel('Product Type', labelFontSize),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: _showProductTypeHelp,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: kPrimary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const AppIcon(
                                      Icons.help_outline,
                                      size: 16,
                                      color: kPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildProductTypeDropdown(inputFontSize),
                            const SizedBox(height: 16),

                            // Quantity and Unit Row
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    controller: _qtyReceivedController,
                                    label: 'Quantity Received',
                                    labelFontSize: labelFontSize,
                                    inputFontSize: inputFontSize,
                                    hintText: '0',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      final qty = double.tryParse(value);
                                      if (qty == null || qty <= 0) {
                                        return 'Invalid quantity';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _buildLabel('Unit', labelFontSize),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: _showUnitHelp,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: kPrimary.withValues(
                                                  alpha: 0.1,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const AppIcon(
                                                Icons.help_outline,
                                                size: 16,
                                                color: kPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      _buildUnitDropdown(inputFontSize),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Quality & Receiving Section
                            _buildSectionHeader(
                              'Quality & Receiving',
                              labelFontSize,
                            ),
                            const SizedBox(height: 16),

                            // Quality Status with Help
                            Row(
                              children: [
                                _buildLabel('Quality Status', labelFontSize),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: _showQualityStatusHelp,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: kPrimary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const AppIcon(
                                      Icons.help_outline,
                                      size: 16,
                                      color: kPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildQualityStatusToggle(inputFontSize),
                            const SizedBox(height: 16),

                            // Employee Dropdown
                            _buildEmployeeDropdown(
                              labelFontSize,
                              inputFontSize,
                            ),
                            const SizedBox(height: 16),

                            // Notes
                            _buildTextField(
                              controller: _notesController,
                              label: 'Notes (Optional)',
                              labelFontSize: labelFontSize,
                              inputFontSize: inputFontSize,
                              hintText: 'e.g., Good quality, properly packaged',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 32),

                            // Submit Button
                            _buildSubmitButton(
                              buttonFontSize,
                              constraints.maxWidth,
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Loading Overlay
                if (productIntakeState is ProductIntakeCreating)
                  Container(
                    color: context.modeTextPrimary.withValues(alpha: 0.54),
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: kPrimary),
                              const SizedBox(height: 16),
                              Text(
                                'Recording product intake...',
                                style: TextStyle(
                                  color: context.modeTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInventoryItemDropdown(
    double labelFontSize,
    double inputFontSize,
  ) {
    return BlocBuilder<InventoryItemsBloc, InventoryItemsState>(
      builder: (context, state) {
        AppLogger.log('InventoryItemsBloc State: $state'); // Debug print

        if (state is InventoryItemsLoading) {
          if (_isInventoryPickerOpen && _allInventoryItems.isNotEmpty) {
            return _buildInventoryPicker(labelFontSize, inputFontSize);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Inventory Item', labelFontSize),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.modeSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.modeBorder),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading items...',
                      style: TextStyle(color: context.modeTextPrimary),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (state is InventoryItemsError) {
          AppLogger.log('InventoryItemsError: ${state.error}'); // Debug print
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Inventory Item', labelFontSize),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.modeError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.modeError.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    AppIcon(Icons.error_outline, color: context.modeError),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Failed to load items',
                        style: TextStyle(color: context.modeError),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<InventoryItemsBloc>().add(
                          LoadInventoryItems(
                            organizationId: organizationId,
                            page: 1,
                            limit: 100,
                          ),
                        );
                      },
                      child: Text('Retry', style: TextStyle(color: kPrimary)),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (state is InventoryItemsLoaded) {
          AppLogger.log(
            'InventoryItemsLoaded: ${state.items.length} items',
          ); // Debug print

          return _buildInventoryPicker(labelFontSize, inputFontSize);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Inventory Item', labelFontSize),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.modeSurfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.modeBorder),
              ),
              child: Text(
                'No items available',
                style: TextStyle(color: context.modeTextSecondary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInventoryPicker(double labelFontSize, double inputFontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Inventory Item', labelFontSize),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            setState(() {
              _isInventoryPickerOpen = !_isInventoryPickerOpen;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.modeBorder),
            ),
            child: Row(
              children: [
                const AppIcon(Icons.inventory_2_outlined, color: kPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedItem?.itemName ?? 'Search and select an item',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: inputFontSize,
                      color: _selectedItem == null
                          ? context.modeTextMuted
                          : context.modeTextPrimary,
                    ),
                  ),
                ),
                AppIcon(
                  _isInventoryPickerOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: context.modeTextMuted,
                ),
              ],
            ),
          ),
        ),
        if (_isInventoryPickerOpen) ...[
          const SizedBox(height: 8),
          _buildInventorySearchDropdown(inputFontSize),
        ],
      ],
    );
  }

  Widget _buildInventorySearchDropdown(double inputFontSize) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _inventorySearchController,
              autofocus: true,
              cursorColor: kPrimary,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: inputFontSize,
                color: context.modeTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Type to search...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: inputFontSize,
                  color: context.modeTextMuted,
                ),
                prefixIcon: AppIconSlot(
                  Icons.search,
                  color: context.modeTextMuted,
                ),
                suffixIcon: _inventorySearchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const AppIcon(Icons.clear),
                        onPressed: _inventorySearchController.clear,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.modeBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kPrimary, width: 1.5),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: context.modeDivider),
          Expanded(
            child: _filteredInventoryItems.isEmpty
                ? Center(
                    child: Text(
                      'No items found',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: inputFontSize,
                        color: context.modeTextMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredInventoryItems.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _filteredInventoryItems.length) {
                        final inventoryState = context
                            .read<InventoryItemsBloc>()
                            .state;
                        if (inventoryState is InventoryItemsLoaded &&
                            inventoryState.hasMore &&
                            !inventoryState.isLoadingMore) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.read<InventoryItemsBloc>().add(
                              LoadMoreInventoryItems(
                                organizationId: organizationId,
                              ),
                            );
                          });
                        }

                        if (inventoryState is InventoryItemsLoaded &&
                            inventoryState.isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final item = _filteredInventoryItems[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedItem = item;
                            _selectedUnit = UnitExtension.fromString(item.unit);
                            _isInventoryPickerOpen = false;
                            _inventorySearchController.clear();
                          });
                          AppLogger.log('Selected item: ${item.itemName}');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: inputFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: context.modeTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.category} - SKU: ${item.sku}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: inputFontSize - 2,
                                  color: context.modeTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTypeDropdown(double inputFontSize) {
    return DropdownButtonFormField<ProductType>(
      initialValue: _selectedProductType,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: context.modeSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.modeBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.modeBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
      ),
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: inputFontSize,
        color: context.modeTextPrimary,
      ),
      icon: AppIcon(Icons.keyboard_arrow_down, color: context.modeTextMuted),
      items: ProductType.values.map((type) {
        return DropdownMenuItem<ProductType>(
          value: type,
          child: Text(
            type.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedProductType = value;
          });
        }
      },
    );
  }

  Widget _buildUnitDropdown(double inputFontSize) {
    return DropdownButtonFormField<Unit>(
      initialValue: _selectedUnit,
      isExpanded: true,
      menuMaxHeight: 320,
      decoration: InputDecoration(
        filled: true,
        fillColor: context.modeSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.modeBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.modeBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
      ),
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: inputFontSize,
        color: context.modeTextPrimary,
      ),
      icon: AppIcon(
        Icons.keyboard_arrow_down,
        color: context.modeTextMuted,
        size: 20,
      ),
      selectedItemBuilder: (context) {
        return Unit.values.map((unit) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              unit.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: inputFontSize,
                color: context.modeTextPrimary,
              ),
            ),
          );
        }).toList();
      },
      items: Unit.values.map((unit) {
        return DropdownMenuItem<Unit>(
          value: unit,
          child: Text(
            unit.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: inputFontSize,
              color: context.modeTextPrimary,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedUnit = value;
          });
        }
      },
    );
  }

  Widget _buildQualityStatusToggle(double inputFontSize) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                _qualityStatus = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _qualityStatus
                    ? context.modeSuccess.withValues(alpha: 0.1)
                    : context.modeSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _qualityStatus
                      ? context.modeSuccess
                      : context.modeBorder,
                  width: _qualityStatus ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    Icons.check_circle,
                    color: _qualityStatus
                        ? context.modeSuccess
                        : context.modeTextMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quality Passed',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: inputFontSize,
                      color: _qualityStatus
                          ? context.modeSuccess
                          : context.modeTextSecondary,
                      fontWeight: _qualityStatus
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                _qualityStatus = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: !_qualityStatus
                    ? context.modeError.withValues(alpha: 0.1)
                    : context.modeSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: !_qualityStatus
                      ? context.modeError
                      : context.modeBorder,
                  width: !_qualityStatus ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    Icons.cancel,
                    color: !_qualityStatus
                        ? context.modeError
                        : context.modeTextMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quality Failed',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: inputFontSize,
                      color: !_qualityStatus
                          ? context.modeError
                          : context.modeTextSecondary,
                      fontWeight: !_qualityStatus
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeDropdown(double labelFontSize, double inputFontSize) {
    return BlocBuilder<EmployeeBloc, EmployeeState>(
      builder: (context, state) {
        AppLogger.log('EmployeeBloc State: $state'); // Debug print

        // Load employees when branchId is available
        if (branchId.isNotEmpty && state is EmployeeInitial) {
          context.read<EmployeeBloc>().add(
            LoadEmployeesByDepartment(
              branchId: branchId,
              department: 'PROCESSING',
              status: 'ACTIVE',
            ),
          );
        }

        if (state is EmployeeLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Received By (Employee)', labelFontSize),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.modeSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.modeBorder),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading employees...',
                      style: TextStyle(color: context.modeTextPrimary),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (state is EmployeeError) {
          AppLogger.log('EmployeeError: ${state.error}'); // Debug print
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Received By (Employee)', labelFontSize),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.modeError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.modeError.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    AppIcon(Icons.error_outline, color: context.modeError),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Failed to load employees',
                        style: TextStyle(color: context.modeError),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<EmployeeBloc>().add(
                          LoadEmployeesByDepartment(
                            branchId: branchId,
                            department: 'PROCESSING',
                            status: 'ACTIVE',
                          ),
                        );
                      },
                      child: Text('Retry', style: TextStyle(color: kPrimary)),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (state is EmployeeLoaded) {
          AppLogger.log(
            'EmployeeLoaded: ${state.employees.length} employees',
          ); // Debug print

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Received By (Employee)', labelFontSize),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedEmployee?.id,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Select employee',
                  hintStyle: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: inputFontSize,
                    color: context.modeTextMuted,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: context.modeSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.modeBorder, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.modeBorder, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kPrimary, width: 2),
                  ),
                ),
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: inputFontSize,
                  color: context.modeTextPrimary,
                ),
                icon: AppIcon(
                  Icons.keyboard_arrow_down,
                  color: context.modeTextMuted,
                ),
                selectedItemBuilder: (context) {
                  return state.employees.map((employee) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        employee.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: inputFontSize,
                          color: context.modeTextPrimary,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: state.employees.map((employee) {
                  return DropdownMenuItem<String>(
                    value: employee.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          employee.fullName,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: inputFontSize,
                            color: context.modeTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${employee.employeeId} • ${employee.role}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: inputFontSize - 2,
                            color: context.modeTextMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    final employee = state.employees.firstWhere(
                      (e) => e.id == value,
                    );
                    setState(() {
                      _selectedEmployee = employee;
                    });
                    AppLogger.log(
                      'Selected employee: ${employee.fullName}',
                    ); // Debug print
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select an employee';
                  }
                  return null;
                },
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Received By (Employee)', labelFontSize),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.modeSurfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.modeBorder),
              ),
              child: Text(
                'No employees available',
                style: TextStyle(color: context.modeTextSecondary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubmitButton(double fontSize, double screenWidth) {
    return SizedBox(
      height: _getSubmitButtonHeight(screenWidth),
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: context.modeTextInverse,
          elevation: 2,
          shadowColor: kPrimary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Submit Product Intake',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: kWhite,
          ),
        ),
      ),
    );
  }

  // Responsive sizing functions
  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 32;
    return 48;
  }

  double _getMaxContentWidth(double width) {
    if (width < 600) return double.infinity;
    if (width < 900) return 600;
    return 800;
  }

  double _getLabelFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getInputFontSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }

  double _getButtonFontSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }

  double _getSubmitButtonHeight(double width) {
    if (width < 360) return 48;
    if (width < 600) return 52;
    return 60;
  }
}

// Helper class for help items
class HelpItem {
  final String title;
  final String description;
  final IconData icon;

  HelpItem(this.title, this.description, this.icon);
}
