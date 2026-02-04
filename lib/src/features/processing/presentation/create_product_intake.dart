import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/processing/bloc/employee_bloc/employee_bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/product_intake_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/product_intake_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/product_intake_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/product_intake_model.dart'
    hide InventoryItem;
import 'package:sandwich_ai/src/features/processing/data/repo/employee_repo.dart';

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

  // State variables
  String branchId = '';
  String organizationId = '';
  InventoryItem? _selectedItem;
  Employee? _selectedEmployee;
  ProductType _selectedProductType = ProductType.rawMaterial;
  Unit _selectedUnit = Unit.kg;
  bool _qualityStatus = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getBranchId();
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
        print('Loading inventory items for org: $orgId'); // Debug
        context.read<InventoryItemsBloc>().add(
          LoadInventoryItems(organizationId: orgId),
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
        decoration: const BoxDecoration(
          color: Colors.white,
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
                      icon: const Icon(Icons.close),
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
                    color: Colors.grey.shade600,
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
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kPrimary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
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
                              color: Colors.black87,
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
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: kPrimary, size: 20),
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
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: Colors.grey.shade700,
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
            color: Colors.black,
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
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: inputFontSize,
              color: const Color(0xFFBDBDBD),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
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

      final qtyReceived = int.tryParse(_qtyReceivedController.text);
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
        backgroundColor: Colors.red,
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
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
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
                                      color: kPrimary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
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
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      final qty = int.tryParse(value);
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
                                                color: kPrimary.withOpacity(
                                                  0.1,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
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
                                      color: kPrimary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
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
                    color: Colors.black54,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: kPrimary),
                              SizedBox(height: 16),
                              Text('Recording product intake...'),
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
        print('InventoryItemsBloc State: $state'); // Debug print

        if (state is InventoryItemsLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Inventory Item', labelFontSize),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kPrimary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Loading items...'),
                  ],
                ),
              ),
            ],
          );
        }

        if (state is InventoryItemsError) {
          print('InventoryItemsError: ${state.error}'); // Debug print
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Inventory Item', labelFontSize),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Failed to load items',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<InventoryItemsBloc>().add(
                          LoadInventoryItems(organizationId: organizationId),
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
          print(
            'InventoryItemsLoaded: ${state.items.length} items',
          ); // Debug print

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Inventory Item', labelFontSize),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedItem?.id,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Select an item',
                  hintStyle: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: inputFontSize,
                    color: const Color(0xFFBDBDBD),
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kPrimary, width: 2),
                  ),
                ),
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: inputFontSize,
                  color: Colors.black,
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF9E9E9E),
                ),
                items: state.items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.itemName,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: inputFontSize,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.category} • SKU: ${item.sku}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: inputFontSize - 2,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    final item = state.items.firstWhere((i) => i.id == value);
                    setState(() {
                      _selectedItem = item;
                      // Auto-set unit based on item's unit
                      _selectedUnit = UnitExtension.fromString(item.unit);
                    });
                    print('Selected item: ${item.itemName}'); // Debug print
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select an inventory item';
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
            _buildLabel('Inventory Item', labelFontSize),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Text('No items available'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductTypeDropdown(double inputFontSize) {
    return DropdownButtonFormField<ProductType>(
      initialValue: _selectedProductType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
      ),
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: inputFontSize,
        color: Colors.black,
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
      items: ProductType.values.map((type) {
        return DropdownMenuItem<ProductType>(
          value: type,
          child: Text(type.displayName),
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
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
      ),
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: inputFontSize,
        color: Colors.black,
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9E9E9E)),
      items: Unit.values.map((unit) {
        return DropdownMenuItem<Unit>(
          value: unit,
          child: Text(unit.displayName),
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
                color: _qualityStatus ? Colors.green.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _qualityStatus
                      ? Colors.green.shade600
                      : const Color(0xFFE0E0E0),
                  width: _qualityStatus ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: _qualityStatus ? Colors.green.shade600 : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quality Passed',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: inputFontSize,
                      color: _qualityStatus
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
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
                color: !_qualityStatus ? Colors.red.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: !_qualityStatus
                      ? Colors.red.shade600
                      : const Color(0xFFE0E0E0),
                  width: !_qualityStatus ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cancel,
                    color: !_qualityStatus ? Colors.red.shade600 : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quality Failed',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: inputFontSize,
                      color: !_qualityStatus
                          ? Colors.red.shade700
                          : Colors.grey.shade700,
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
        print('EmployeeBloc State: $state'); // Debug print

        // Load employees when branchId is available
        if (branchId.isNotEmpty && state is EmployeeInitial) {
          context.read<EmployeeBloc>().add(
            LoadEmployeesByDepartment(
              branchId: branchId,
              department: 'PROCUREMENT',
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kPrimary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Loading employees...'),
                  ],
                ),
              ),
            ],
          );
        }

        if (state is EmployeeError) {
          print('EmployeeError: ${state.error}'); // Debug print
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Received By (Employee)', labelFontSize),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Failed to load employees',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<EmployeeBloc>().add(
                          LoadEmployeesByDepartment(
                            branchId: branchId,
                            department: 'PROCUREMENT',
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
          print(
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
                    color: const Color(0xFFBDBDBD),
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kPrimary, width: 2),
                  ),
                ),
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: inputFontSize,
                  color: Colors.black,
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF9E9E9E),
                ),
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
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${employee.employeeId} • ${employee.role}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: inputFontSize - 2,
                            color: Colors.grey,
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
                    print(
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
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Text('No employees available'),
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
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: kPrimary.withOpacity(0.4),
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
