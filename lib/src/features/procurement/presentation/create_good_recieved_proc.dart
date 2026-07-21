import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_good_recieved_model.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/goods_received_advanced_cubit/goods_received_advanced_cubit.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/goods_received_advanced_cubit/goods_received_advanced_state.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/good_received_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/good_received_bloc/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/good_received_bloc/state.dart'
    show
        GoodsReceivedState,
        InventoryItemsLoaded,
        GoodsReceivedSuccess,
        GoodsReceivedError,
        GoodsReceivedSubmitting;
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/state.dart';

class CreateGoodsReceivedScreen extends StatefulWidget {
  const CreateGoodsReceivedScreen({super.key});

  @override
  State<CreateGoodsReceivedScreen> createState() =>
      _CreateGoodsReceivedScreenState();
}

class _CreateGoodsReceivedScreenState extends State<CreateGoodsReceivedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNoController = TextEditingController();
  final _poNumberController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _qualityNotesController = TextEditingController();

  List<InventoryItem> _allItems = [];
  List<SelectedItem> _selectedItems = [];
  String _branchId = '';
  String _inspectedBy = '';
  String? _selectedSupplierId;
  String? _selectedSupplierName;

  Future<void> _loadPoPrefill() async {
    final poId = _poNumberController.text.trim();
    if (poId.isEmpty) {
      _showSnackBar('Enter a PO number first', isError: true);
      return;
    }
    await context.read<GoodsReceivedAdvancedCubit>().loadPoPrefill(poId);
    if (!mounted) return;
    final state = context.read<GoodsReceivedAdvancedCubit>().state;
    final prefill = state.prefill;
    if (prefill == null) {
      _showSnackBar(
        state.prefillError ?? 'Unable to prefill PO',
        isError: true,
      );
      return;
    }

    setState(() {
      _selectedSupplierName = prefill.supplierName;
      _poNumberController.text = prefill.poNumber.isEmpty
          ? poId
          : prefill.poNumber;
      for (final item in _selectedItems) {
        item.dispose();
      }
      _selectedItems = prefill.items.map((receivedItem) {
        final selected = SelectedItem();
        final match = _allItems.where((item) => item.id == receivedItem.itemId);
        selected.inventoryItem = match.isNotEmpty
            ? match.first
            : InventoryItem(
                id: receivedItem.itemId,
                name: receivedItem.itemName,
                category: '',
                unit: '',
                description: '',
                sku: '',
              );
        selected.orderedQty = receivedItem.orderedQty;
        selected.receivedQty = receivedItem.receivedQty;
        selected.orderedQtyController.text = receivedItem.orderedQty.toString();
        selected.receivedQtyController.text = receivedItem.receivedQty
            .toString();
        selected.qualityCheck = receivedItem.qualityCheck;
        selected.qcStatus = receivedItem.qcStatus.isEmpty
            ? 'PASSED'
            : receivedItem.qcStatus;
        selected.qcNote = receivedItem.qcNote;
        selected.expiryDate = receivedItem.expiryDate == null
            ? null
            : DateTime.tryParse(receivedItem.expiryDate!);
        return selected;
      }).toList();
    });
    _showSnackBar('Purchase order prefilled');
  }

  Future<void> _markPoComplete() async {
    final poId = _poNumberController.text.trim();
    if (poId.isEmpty) {
      _showSnackBar('Enter a PO number first', isError: true);
      return;
    }
    final ok = await context
        .read<GoodsReceivedAdvancedCubit>()
        .markPurchaseOrderComplete(poId);
    if (!mounted) return;
    _showSnackBar(
      ok ? 'Purchase order marked complete' : 'Failed to mark PO complete',
      isError: !ok,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    _inspectedBy = await AuthCacheHelper.instance.getEmpID() ?? '';

    if (mounted) {
      context.read<SupplierBloc>().add(LoadSuppliers());
      context.read<GoodsReceivedBloc>().add(
        LoadInventoryItems(organizationId: ''),
      );
    }
  }

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _poNumberController.dispose();
    _receivedByController.dispose();
    _qualityNotesController.dispose();
    for (var item in _selectedItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _showSupplierHelp() {
    _showHelpBottomSheet(
      title: 'Supplier Selection',
      subtitle: 'Choose the supplier who delivered these goods',
      items: [
        HelpItem(
          'Select Supplier',
          'Search and select the supplier from your approved supplier list. Make sure the supplier matches your purchase order.',
          Icons.business,
        ),
        HelpItem(
          'Verify Supplier',
          'Always verify that the supplier name matches the invoice and delivery documentation.',
          Icons.verified,
        ),
        HelpItem(
          'New Supplier',
          'If the supplier is not in the list, you need to add them to your supplier database first.',
          Icons.add_business,
        ),
      ],
      tip:
          'Tip: Double-check the supplier name against your PO and invoice to ensure accurate record keeping.',
    );
  }

  void _showInvoiceHelp() {
    _showHelpBottomSheet(
      title: 'Invoice & PO Information',
      subtitle: 'Document reference numbers for this delivery',
      items: [
        HelpItem(
          'Invoice Number',
          'Enter the exact invoice number from the supplier\'s invoice. This is crucial for payment processing and audit trails.',
          Icons.receipt_long,
        ),
        HelpItem(
          'PO Number',
          'Reference your Purchase Order number. This links the delivery to your original order for tracking and verification.',
          Icons.description,
        ),
        HelpItem(
          'Match Documents',
          'Ensure the invoice number and PO number match the physical documents you received with the delivery.',
          Icons.check_circle,
        ),
      ],
      tip:
          'Tip: Keep physical copies of invoices and POs together with this goods receipt for easy reference.',
    );
  }

  void _showQualityCheckHelp() {
    _showHelpBottomSheet(
      title: 'Quality Control',
      subtitle: 'Inspect and verify the quality of received goods',
      items: [
        HelpItem(
          'Visual Inspection',
          'Check for any visible damage, defects, or quality issues. Look for proper packaging and labeling.',
          Icons.visibility,
        ),
        HelpItem(
          'Quality Status',
          'Mark as "Passed" if items meet quality standards, or "Failed" if there are issues that need to be reported.',
          Icons.check_circle_outline,
        ),
        HelpItem(
          'QC Notes',
          'Document any observations, defects, or special conditions. Be specific - this helps with supplier discussions and returns.',
          Icons.note_alt,
        ),
        HelpItem(
          'Expiry Dates',
          'For perishable items, always check and record expiry dates. Reject items with insufficient shelf life.',
          Icons.calendar_today,
        ),
      ],
      tip:
          'Tip: Take photos of damaged goods or quality issues for documentation and supplier claims.',
    );
  }

  void _showQuantityHelp() {
    _showHelpBottomSheet(
      title: 'Quantity Verification',
      subtitle: 'Record ordered vs. received quantities accurately',
      items: [
        HelpItem(
          'Ordered Quantity',
          'Enter the quantity that was originally ordered according to your Purchase Order.',
          Icons.shopping_cart,
        ),
        HelpItem(
          'Received Quantity',
          'Count and enter the actual quantity delivered. This may differ from the ordered amount.',
          Icons.inventory_2,
        ),
        HelpItem(
          'Quantity Variance',
          'If received quantity differs from ordered quantity, document the reason in the notes. Common reasons: partial delivery, supplier shortage, damaged items.',
          Icons.warning_amber,
        ),
      ],
      tip:
          'Tip: Always physically count items - don\'t rely solely on the delivery note. Discrepancies should be noted immediately.',
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
          borderRadius: const BorderRadius.only(
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
                          color: context.modePrimary,
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
                      color: context.modePrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.modePrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        AppIcon(
                          Icons.lightbulb_outline,
                          color: context.modePrimary,
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
                color: context.modePrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppIcon(icon, color: context.modePrimary, size: 20),
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

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    if (_selectedSupplierName == null || _selectedSupplierName!.isEmpty) {
      _showSnackBar('Please select a supplier', isError: true);
      return;
    }

    if (_selectedItems.isEmpty) {
      _showSnackBar('Please add at least one item', isError: true);
      return;
    }

    for (var item in _selectedItems) {
      if (!item.validate()) {
        _showSnackBar('Please complete all item details', isError: true);
        return;
      }
    }

    final items = _selectedItems.map((item) {
      return GoodsReceivedItem(
        itemId: item.inventoryItem?.id ?? '',
        itemName: item.inventoryItem?.name ?? '',
        orderedQty: item.orderedQty ?? 0,
        receivedQty: item.receivedQty ?? 0,
        qualityCheck: item.qualityCheck ?? false,
        qcStatus: item.qcStatus ?? '',
        qcNote: item.qcNote,
        expiryDate: item.expiryDate != null
            ? DateTime.utc(
                item.expiryDate!.year,
                item.expiryDate!.month,
                item.expiryDate!.day,
              ).toIso8601String()
            : null,
      );
    }).toList();

    final request = CreateGoodsReceivedRequest(
      branchId: _branchId,
      supplierName: _selectedSupplierName!,
      invoiceNo: _invoiceNoController.text.trim(),
      poNumber: _poNumberController.text.trim(),
      receivedBy: _receivedByController.text.trim(),
      inspectedBy: _inspectedBy,
      qualityNotes: _qualityNotesController.text.trim(),
      items: items,
    );

    context.read<GoodsReceivedBloc>().add(
      CreateGoodsReceived(request: request),
    );
  }

  Widget _buildPoActions(double screenWidth) {
    return BlocBuilder<GoodsReceivedAdvancedCubit, GoodsReceivedAdvancedState>(
      builder: (context, state) {
        final isLoading =
            state.prefillStatus == GoodsReceivedAdvancedStatus.loading;
        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: isLoading ? null : _loadPoPrefill,
              icon: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.modePrimary,
                      ),
                    )
                  : const AppIcon(Icons.download_done_outlined, size: 18),
              label: Text(
                isLoading ? 'Loading PO...' : 'Prefill from PO',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getCaptionFontSize(screenWidth) + 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.modePrimary,
                side: BorderSide(color: context.modePrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: isLoading ? null : _markPoComplete,
              icon: const AppIcon(Icons.task_alt, size: 18),
              label: Text(
                'Mark PO Complete',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getCaptionFontSize(screenWidth) + 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.modeSuccess,
                disabledForegroundColor: context.modeTextSecondary,
                side: BorderSide(color: context.modeSuccess),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPoDeliveryStatus() {
    return BlocBuilder<GoodsReceivedAdvancedCubit, GoodsReceivedAdvancedState>(
      builder: (context, state) {
        final status = state.deliveryStatus;
        final error = state.prefillError;

        if (status == null && error == null) {
          return const SizedBox.shrink();
        }

        if (status == null && error != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              error,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 12,
                color: context.modeError,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final isComplete = status!.isComplete;
        final statusColor = isComplete
            ? context.modeSuccess
            : context.modeWarning;

        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon(
                    isComplete
                        ? Icons.check_circle_outline
                        : Icons.local_shipping_outlined,
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status.deliveryStatus.isEmpty
                          ? (isComplete ? 'Complete' : 'In progress')
                          : status.deliveryStatus,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildPoStatusMetric('Ordered', status.orderedQty),
                  _buildPoStatusMetric('Received', status.receivedQty),
                  _buildPoStatusMetric('Pending', status.pendingQty),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPoStatusMetric(String label, double value) {
    return Text(
      '$label: ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}',
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: 12,
        color: context.modeTextPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: WorkSansAppTextStyles.medium.copyWith(
            color: context.modeTextInverse,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError ? context.modeError : context.modeSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GoodsReceivedBloc, GoodsReceivedState>(
          listener: (context, state) {
            if (state is InventoryItemsLoaded) {
              setState(() {
                _allItems = state.items;
              });
            } else if (state is GoodsReceivedSuccess) {
              _showSnackBar(state.message);
              _resetForm();
            } else if (state is GoodsReceivedError) {
              _showSnackBar(state.error, isError: true);
            }
          },
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          return SingleChildScrollView(
            padding: EdgeInsets.all(_getPadding(screenWidth)),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildSectionTitle('Supplier Information', screenWidth),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _showSupplierHelp,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.modePrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: AppIcon(
                            Icons.help_outline,
                            size: 16,
                            color: context.modePrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _getSpacing(screenWidth)),
                  _buildSupplierDropdown(screenWidth),
                  SizedBox(height: _getFieldSpacing(screenWidth)),
                  Row(
                    children: [
                      _buildSectionTitle('Invoice & PO Details', screenWidth),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _showInvoiceHelp,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.modePrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: AppIcon(
                            Icons.help_outline,
                            size: 16,
                            color: context.modePrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _getSpacing(screenWidth)),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _invoiceNoController,
                          label: 'Invoice Number',
                          hint: 'INV-XXXX',
                          screenWidth: screenWidth,
                          icon: Icons.receipt_long,
                        ),
                      ),
                      SizedBox(width: _getFieldSpacing(screenWidth)),
                      Expanded(
                        child: _buildTextField(
                          controller: _poNumberController,
                          label: 'PO Number',
                          hint: 'PO-XXXX',
                          screenWidth: screenWidth,
                          icon: Icons.description,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _getSpacing(screenWidth)),
                  _buildPoActions(screenWidth),
                  _buildPoDeliveryStatus(),
                  SizedBox(height: _getFieldSpacing(screenWidth)),
                  _buildTextField(
                    controller: _receivedByController,
                    label: 'Received By',
                    hint: 'Name of receiver',
                    screenWidth: screenWidth,
                    icon: Icons.person,
                  ),
                  SizedBox(height: _getSectionSpacing(screenWidth)),

                  Row(
                    children: [
                      _buildSectionTitle('Items', screenWidth),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _showQuantityHelp,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.modePrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: AppIcon(
                            Icons.help_outline,
                            size: 16,
                            color: context.modePrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: _getSpacing(screenWidth)),
                  ..._selectedItems.asMap().entries.map((entry) {
                    return _buildItemCard(entry.key, entry.value, screenWidth);
                  }),
                  SizedBox(height: _getSpacing(screenWidth)),
                  _buildAddItemButton(screenWidth, _selectedItems),
                  SizedBox(height: _getSectionSpacing(screenWidth)),

                  Row(
                    children: [
                      _buildSectionTitle('Quality Notes', screenWidth),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _showQualityCheckHelp,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.modePrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: AppIcon(
                            Icons.help_outline,
                            size: 16,
                            color: context.modePrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _getSpacing(screenWidth)),
                  _buildTextField(
                    controller: _qualityNotesController,
                    label: 'Quality Notes',
                    hint: 'Enter overall quality notes',
                    screenWidth: screenWidth,
                    icon: Icons.note,
                    maxLines: 3,
                  ),
                  SizedBox(height: _getSectionSpacing(screenWidth)),
                  _buildSubmitButton(screenWidth),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSupplierDropdown(double screenWidth) {
    return BlocBuilder<SupplierBloc, SupplierState>(
      builder: (context, state) {
        if (state is SupplierLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supplier *',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getLabelFontSize(screenWidth),
                  fontWeight: FontWeight.w500,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.modeSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.modeBorder),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.modePrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading suppliers...',
                      style: TextStyle(color: context.modeTextSecondary),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (state is SupplierError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supplier *',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getLabelFontSize(screenWidth),
                  fontWeight: FontWeight.w500,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.modeError.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.modeError.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  children: [
                    AppIcon(Icons.error_outline, color: context.modeError),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Failed to load suppliers',
                        style: TextStyle(color: context.modeError),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<SupplierBloc>().add(LoadSuppliers());
                      },
                      child: Text(
                        'Retry',
                        style: TextStyle(color: context.modePrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (state is SupplierListLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supplier *',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getLabelFontSize(screenWidth),
                  fontWeight: FontWeight.w500,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () =>
                    _showSearchableSupplierDialog(state.suppliers, screenWidth),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.modeSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedSupplierId != null
                          ? context.modePrimary
                          : context.modeBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      AppIcon(
                        Icons.business,
                        color: context.modePrimary,
                        size: _getIconSize(screenWidth),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedSupplierName ?? 'Select a supplier',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getInputFontSize(screenWidth),
                            color: _selectedSupplierName != null
                                ? context.modeTextPrimary
                                : context.modeTextSecondary,
                          ),
                        ),
                      ),
                      AppIcon(
                        Icons.arrow_drop_down,
                        color: context.modePrimary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showSearchableSupplierDialog(
    List<dynamic> suppliers,
    double screenWidth,
  ) {
    final TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredSuppliers = suppliers.where((supplier) {
            final searchTerm = searchController.text.toLowerCase();
            return supplier.businessName.toLowerCase().contains(searchTerm);
          }).toList();

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Select Supplier',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: context.modePrimary,
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
                        const SizedBox(height: 12),
                        TextField(
                          controller: searchController,
                          autofocus: true,
                          onChanged: (value) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search suppliers...',
                            prefixIcon: AppIcon(
                              Icons.search,
                              color: context.modePrimary,
                            ),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: AppIcon(
                                      Icons.clear,
                                      color: context.modeTextMuted,
                                    ),
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: context.modeSurfaceAlt,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: filteredSuppliers.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppIcon(
                                    Icons.search_off,
                                    size: 64,
                                    color: context.modeTextMuted,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No suppliers found',
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: 16,
                                          color: context.modeTextSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredSuppliers.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final supplier = filteredSuppliers[index];
                              final isSelected =
                                  _selectedSupplierId == supplier.id;

                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: context.modePrimary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: AppIcon(
                                    Icons.business,
                                    color: context.modePrimary,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  supplier.businessName,
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: context.modeTextPrimary,
                                  ),
                                ),
                                trailing: isSelected
                                    ? AppIcon(
                                        Icons.check_circle,
                                        color: context.modePrimary,
                                      )
                                    : null,
                                selected: isSelected,
                                selectedTileColor: context.modePrimary
                                    .withValues(alpha: 0.05),
                                onTap: () {
                                  this.setState(() {
                                    _selectedSupplierId = supplier.id;
                                    _selectedSupplierName =
                                        supplier.businessName;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, double screenWidth) {
    return Text(
      title,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: _getTitleFontSize(screenWidth),
        fontWeight: FontWeight.w600,
        color: context.modeTextPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required double screenWidth,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w500,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          cursorColor: context.modePrimary,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth),
            color: context.modeTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              color: context.modeTextSecondary,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: icon != null
                ? AppIcon(
                    icon,
                    color: context.modePrimary,
                    size: _getIconSize(screenWidth),
                  )
                : null,
            filled: true,
            fillColor: context.modeSurface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.modeBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.modeBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.modePrimary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildItemCard(int index, SelectedItem item, double screenWidth) {
    return Container(
      margin: EdgeInsets.only(bottom: _getSpacing(screenWidth)),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modePrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item ${index + 1}',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getLabelFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: context.modePrimary,
                ),
              ),
              if (_selectedItems.length > 1)
                IconButton(
                  icon: AppIcon(
                    Icons.close,
                    size: 20,
                    color: context.modeError,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedItems[index].dispose(); // ADD THIS
                      _selectedItems.removeAt(index);
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Item Dropdown
          _buildItemDropdown(item, screenWidth),
          const SizedBox(height: 16),

          // Quantity Row
          // REPLACE the quantity Row in _buildItemCard:
          Row(
            children: [
              Expanded(
                child: _buildQuantityField(
                  label: 'Ordered Qty',
                  hint: '0',
                  screenWidth: screenWidth,
                  controller: item.orderedQtyController, // ADD
                  onChanged: (value) {
                    setState(() {
                      item.orderedQty = double.tryParse(value);
                    });
                  },
                ),
              ),
              SizedBox(width: _getFieldSpacing(screenWidth)),
              Expanded(
                child: _buildQuantityField(
                  label: 'Received Qty',
                  hint: '0',
                  screenWidth: screenWidth,
                  controller: item.receivedQtyController, // ADD
                  onChanged: (value) {
                    setState(() {
                      item.receivedQty = double.tryParse(value);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quality Check Section
          Row(
            children: [
              Text(
                'Quality Check',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getLabelFontSize(screenWidth),
                  fontWeight: FontWeight.w500,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RadioGroup<bool>(
                  groupValue: item.qualityCheck,
                  onChanged: (value) {
                    setState(() {
                      item.qualityCheck = value;
                      if (value == true) {
                        item.qcStatus = 'PASSED';
                      } else if (value == false) {
                        item.qcStatus = 'FAILED';
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: Text(
                            'Passed',
                            style: TextStyle(color: context.modeTextPrimary),
                          ),
                          value: true,
                          activeColor: context.modePrimary,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: Text(
                            'Failed',
                            style: TextStyle(color: context.modeTextPrimary),
                          ),
                          value: false,
                          activeColor: context.modeError,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // QC Note
          _buildQCNoteField(item, screenWidth),
          const SizedBox(height: 16),

          // Expiry Date
          _buildExpiryDateField(item, screenWidth),
        ],
      ),
    );
  }

  Widget _buildItemDropdown(SelectedItem item, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item *',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w500,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showSearchableItemDialog(item, screenWidth),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.inventoryItem != null
                    ? context.modePrimary
                    : context.modeBorder,
              ),
            ),
            child: Row(
              children: [
                AppIcon(
                  Icons.inventory_2,
                  color: context.modePrimary,
                  size: _getIconSize(screenWidth),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.inventoryItem?.name ?? 'Select an item',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getInputFontSize(screenWidth),
                      color: item.inventoryItem != null
                          ? context.modeTextPrimary
                          : context.modeTextSecondary,
                    ),
                  ),
                ),
                AppIcon(
                  Icons.arrow_drop_down,
                  color: context.modePrimary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchableItemDialog(SelectedItem item, double screenWidth) {
    final TextEditingController searchController = TextEditingController();

    // Check if items are loaded
    if (_allItems.isEmpty) {
      _showSnackBar('Loading items, please wait...', isError: false);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredItems = _allItems.where((invItem) {
            final searchTerm = searchController.text.toLowerCase();
            return invItem.name.toLowerCase().contains(searchTerm);
          }).toList();

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Select Item',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: context.modePrimary,
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
                        const SizedBox(height: 12),
                        TextField(
                          controller: searchController,
                          autofocus: true,
                          onChanged: (value) => setDialogState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search items...',
                            prefixIcon: AppIcon(
                              Icons.search,
                              color: context.modePrimary,
                            ),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: AppIcon(
                                      Icons.clear,
                                      color: context.modeTextMuted,
                                    ),
                                    onPressed: () {
                                      searchController.clear();
                                      setDialogState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: context.modeSurfaceAlt,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppIcon(
                                    Icons.search_off,
                                    size: 64,
                                    color: context.modeTextMuted,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchController.text.isEmpty
                                        ? 'No items available'
                                        : 'No items found',
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: 16,
                                          color: context.modeTextSecondary,
                                        ),
                                  ),
                                  if (searchController.text.isEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Total items: ${_allItems.length}',
                                      style: WorkSansAppTextStyles.medium
                                          .copyWith(
                                            fontSize: 14,
                                            color: context.modeTextMuted,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredItems.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final invItem = filteredItems[index];
                              final isSelected =
                                  item.inventoryItem?.id == invItem.id;

                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: context.modePrimary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: AppIcon(
                                    Icons.inventory_2,
                                    color: context.modePrimary,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  invItem.name,
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: context.modeTextPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  '${invItem.category} â€¢ ${invItem.unit} â€¢ SKU: ${invItem.sku}',
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 12,
                                    color: context.modeTextSecondary,
                                  ),
                                ),

                                trailing: isSelected
                                    ? AppIcon(
                                        Icons.check_circle,
                                        color: context.modePrimary,
                                      )
                                    : null,
                                selected: isSelected,
                                selectedTileColor: context.modePrimary
                                    .withValues(alpha: 0.05),
                                onTap: () {
                                  setState(() {
                                    item.inventoryItem = invItem;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuantityField({
    required String label,
    required String hint,
    required double screenWidth,
    required TextEditingController controller, // ADD
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w500,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller, // ADD
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          onChanged: onChanged,
          cursorColor: context.modePrimary,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth),
            color: context.modeTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              color: context.modeTextSecondary,
            ),
            filled: true,
            fillColor: context.modeSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.modeBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.modeBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.modePrimary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQCNoteField(SelectedItem item, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QC Note',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w500,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: 2,
          onChanged: (value) {
            setState(() {
              item.qcNote = value;
            });
          },
          cursorColor: context.modePrimary,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth),
            color: context.modeTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Enter quality check notes',
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              color: context.modeTextSecondary,
            ),
            filled: true,
            fillColor: context.modeSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.modeBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.modeBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.modePrimary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryDateField(SelectedItem item, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expiry Date (Optional)',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w500,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate:
                  item.expiryDate ??
                  DateTime.now().add(const Duration(days: 90)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: context.modePrimary,
                      onPrimary: context.modeTextInverse,
                      onSurface: context.modeTextPrimary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                item.expiryDate = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.modeBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.expiryDate != null
                      ? DateFormat('MMM dd, yyyy').format(item.expiryDate!)
                      : 'Select expiry date',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getInputFontSize(screenWidth),
                    color: item.expiryDate != null
                        ? context.modeTextPrimary
                        : context.modeTextSecondary,
                  ),
                ),
                AppIcon(
                  Icons.calendar_today,
                  color: context.modePrimary,
                  size: _getIconSize(screenWidth),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddItemButton(
    double screenWidth,
    List<SelectedItem> selectedItems,
  ) {
    return SizedBox(
      height: _getButtonHeight(screenWidth),
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            selectedItems.add(SelectedItem());
          });
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: context.modePrimary,
          backgroundColor: context.modePrimary.withValues(alpha: 0.1),
          side: BorderSide(color: context.modePrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const AppIcon(Icons.add_circle_outline, size: 20),
        label: Text(
          selectedItems.isEmpty ? 'Add an Item' : ' Add Another Item',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(double screenWidth) {
    return BlocBuilder<GoodsReceivedBloc, GoodsReceivedState>(
      builder: (context, state) {
        final isSubmitting = state is GoodsReceivedSubmitting;

        return SizedBox(
          width: double.infinity,
          height: _getButtonHeight(screenWidth),
          child: ElevatedButton(
            onPressed: isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.modePrimary,
              foregroundColor: context.modeTextInverse,
              disabledBackgroundColor: context.modeSurfaceMuted,
              elevation: 2,
              shadowColor: context.modePrimary.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.modeTextInverse,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Submitting...',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: _getInputFontSize(screenWidth),
                          fontWeight: FontWeight.w600,
                          color: context.modeTextInverse,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Submit Goods Received',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getInputFontSize(screenWidth),
                      fontWeight: FontWeight.w600,
                      color: context.modeTextInverse,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _resetForm() {
    _invoiceNoController.clear();
    _poNumberController.clear();
    _receivedByController.clear();
    _qualityNotesController.clear();
    setState(() {
      _selectedSupplierId = null;
      _selectedSupplierName = null;
      _selectedItems = [];
    });
  }

  // Responsive sizing helper methods
  double _getPadding(double screenWidth) {
    if (screenWidth < 360) return 16;
    if (screenWidth < 600) return 20;
    return 24;
  }

  double _getSpacing(double screenWidth) {
    if (screenWidth < 360) return 12;
    if (screenWidth < 600) return 16;
    return 20;
  }

  double _getFieldSpacing(double screenWidth) {
    if (screenWidth < 360) return 12;
    return 16;
  }

  double _getSectionSpacing(double screenWidth) {
    if (screenWidth < 360) return 20;
    if (screenWidth < 600) return 24;
    return 32;
  }

  double _getTitleFontSize(double screenWidth) {
    if (screenWidth < 360) return 16;
    if (screenWidth < 600) return 18;
    return 20;
  }

  double _getLabelFontSize(double screenWidth) {
    if (screenWidth < 360) return 13;
    if (screenWidth < 600) return 14;
    return 15;
  }

  double _getInputFontSize(double screenWidth) {
    if (screenWidth < 360) return 14;
    if (screenWidth < 600) return 15;
    return 16;
  }

  double _getCaptionFontSize(double screenWidth) {
    if (screenWidth < 360) return 11;
    if (screenWidth < 600) return 12;
    return 13;
  }

  double _getIconSize(double screenWidth) {
    if (screenWidth < 360) return 18;
    if (screenWidth < 600) return 20;
    return 22;
  }

  double _getButtonHeight(double screenWidth) {
    if (screenWidth < 360) return 48;
    if (screenWidth < 600) return 52;
    return 56;
  }
}

// Helper class for HelpItem
class HelpItem {
  final String title;
  final String description;
  final IconData icon;

  HelpItem(this.title, this.description, this.icon);
}

// Helper class for SelectedItem
class SelectedItem {
  InventoryItem? inventoryItem;
  double? orderedQty;
  double? receivedQty;
  bool? qualityCheck;
  String? qcStatus;
  String? qcNote;
  DateTime? expiryDate;

  // Add these
  final TextEditingController orderedQtyController = TextEditingController();
  final TextEditingController receivedQtyController = TextEditingController();

  void dispose() {
    orderedQtyController.dispose();
    receivedQtyController.dispose();
  }

  bool validate() {
    final ordered = double.tryParse(orderedQtyController.text.trim());
    final received = double.tryParse(receivedQtyController.text.trim());
    return inventoryItem != null &&
        ordered != null &&
        ordered > 0 &&
        received != null &&
        received >= 0 &&
        qualityCheck != null &&
        qcStatus != null;
  }
}
