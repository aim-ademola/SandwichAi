import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_draft_model.dart'
    show OrderItemRequest;
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/porchase_order_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/porchase_order_blocs/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/porchase_order_blocs/state.dart';

import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/state.dart';
import 'package:intl/intl.dart';

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _poNumberController = TextEditingController();
  final _orderDateController = TextEditingController();
  final _noteController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _deliveryCityController = TextEditingController();
  final _deliveryStateController = TextEditingController();
  final _deliveryInstructionsController = TextEditingController();
  final _customPaymentTermController = TextEditingController();

  String? _selectedSupplierId;
  String? _selectedSupplierName;
  String _selectedPriority = 'NORMAL';
  String _selectedPaymentTerm = 'NET_30';
  DateTime _expectedDeliveryDate = DateTime.now().add(const Duration(days: 7));

  final List<String> _priorities = ['NORMAL', 'HIGH', 'URGENT'];
  final List<String> _paymentTerms = [
    'NET_7',
    'NET_15',
    'NET_30',
    'NET_60',
    'NET_90',
    'ADVANCE_50',
    'IMMEDIATE',
    'CUSTOM',
  ];

  // Line items with product selection
  final List<OrderLineItem> _lineItems = [OrderLineItem()];

  // Track if products are currently being loaded
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _poNumberController.text = 'Auto-generated';
    _orderDateController.text = DateFormat('MM/dd/yyyy').format(DateTime.now());

    // Load suppliers
    context.read<SupplierBloc>().add(LoadSuppliers());
  }

  @override
  void dispose() {
    _poNumberController.dispose();
    _orderDateController.dispose();
    _noteController.dispose();
    _deliveryAddressController.dispose();
    _deliveryCityController.dispose();
    _deliveryStateController.dispose();
    _deliveryInstructionsController.dispose();
    _customPaymentTermController.dispose();
    for (var item in _lineItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add(OrderLineItem());
    });
  }

  void _removeLineItem(int index) {
    if (_lineItems.length > 1) {
      setState(() {
        _lineItems[index].dispose();
        _lineItems.removeAt(index);
      });
    }
  }

  Future<void> _selectDeliveryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expectedDeliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: context.modePrimary,
              onPrimary: context.modeTextInverse,
              onSurface: context.modeTextPrimary,
              surface: context.modeSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _expectedDeliveryDate = picked;
      });
    }
  }

  void _loadSupplierProducts(String supplierId) {
    setState(() {
      _isLoadingProducts = true;
    });
    context.read<SupplierBloc>().add(
      LoadSupplierProducts(supplierId: supplierId),
    );
  }

  void _showPaymentTermsHelp() {
    _showHelpBottomSheet(
      title: 'Payment Terms Guide',
      subtitle:
          'Understanding payment terms helps you manage cash flow effectively',
      items: [
        HelpItem(
          'NET 7',
          'Payment due within 7 days of invoice date',
          Icons.calendar_today,
        ),
        HelpItem(
          'NET 15',
          'Payment due within 15 days of invoice date',
          Icons.calendar_today,
        ),
        HelpItem(
          'NET 30',
          'Payment due within 30 days of invoice date (Most Common)',
          Icons.calendar_today,
        ),
        HelpItem(
          'NET 60',
          'Payment due within 60 days of invoice date',
          Icons.calendar_today,
        ),
        HelpItem(
          'NET 90',
          'Payment due within 90 days of invoice date',
          Icons.calendar_today,
        ),
        HelpItem(
          'ADVANCE 50',
          '50% payment in advance, remaining 50% on delivery',
          Icons.payment,
        ),
        HelpItem(
          'IMMEDIATE',
          'Full payment due on delivery or pickup',
          Icons.bolt,
        ),
        HelpItem(
          'CUSTOM',
          'Define your own payment terms with the supplier',
          Icons.edit_note,
        ),
      ],
      tip:
          'Tip: Longer payment terms give you more time to pay but may affect supplier relationships.',
    );
  }

  void _showPriorityHelp() {
    _showHelpBottomSheet(
      title: 'Priority Levels',
      subtitle: 'Set the urgency level for your purchase order',
      items: [
        HelpItem(
          'NORMAL',
          'Standard processing time. Use for regular, non-urgent orders that can follow the standard procurement timeline.',
          Icons.flag_outlined,
        ),
        HelpItem(
          'HIGH',
          'Faster processing required. Use when you need the items sooner than usual but it\'s not an emergency.',
          Icons.flag,
        ),
        HelpItem(
          'URGENT',
          'Immediate attention needed. Use only for critical orders that need expedited processing and delivery.',
          Icons.priority_high,
        ),
      ],
      tip:
          'Tip: Use URGENT sparingly. Frequent urgent orders may increase costs and strain supplier relationships.',
    );
  }

  void _showDeliveryDateHelp() {
    _showHelpBottomSheet(
      title: 'Expected Delivery Date',
      subtitle: 'When you need the order to arrive',
      items: [
        HelpItem(
          'Planning Ahead',
          'Consider supplier lead time, shipping duration, and any potential delays. It\'s better to set a realistic date with buffer time.',
          Icons.access_time,
        ),
        HelpItem(
          'Supplier Capabilities',
          'Check with your supplier about their standard delivery timeframes. Rush deliveries may incur additional charges.',
          Icons.local_shipping,
        ),
        HelpItem(
          'Seasonal Factors',
          'Account for holidays, peak seasons, or weather conditions that might affect delivery schedules.',
          Icons.calendar_month,
        ),
      ],
      tip:
          'Tip: Adding 2-3 days buffer to your required date helps avoid stock-outs if there are delays.',
    );
  }

  void _showDeliveryAddressHelp() {
    _showHelpBottomSheet(
      title: 'Delivery Information',
      subtitle: 'Ensure accurate delivery details',
      items: [
        HelpItem(
          'Complete Address',
          'Provide the full street address including building number, street name, and any landmarks that help locate your business.',
          Icons.location_on,
        ),
        HelpItem(
          'City & State',
          'Accurate city and state information ensures proper routing and delivery. This also helps calculate shipping costs correctly.',
          Icons.map,
        ),
        HelpItem(
          'Delivery Instructions',
          'Add specific instructions like gate codes, preferred delivery times, or contact person details to ensure smooth delivery.',
          Icons.info_outline,
        ),
      ],
      tip:
          'Tip: Keep delivery instructions clear and concise. Include a contact number for the receiving person.',
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
                        color: context.modeTextSecondary,
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
                  (item) => _buildPaymentTermItem(
                    item.title,
                    item.description,
                    item.icon,
                  ),
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

  Widget _buildSectionHeader(String text, double fontSize) {
    return Text(
      text,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: fontSize + 2,
        fontWeight: FontWeight.w700,
        color: context.modePrimary,
      ),
    );
  }

  Widget _buildLabel(String text, double fontSize) {
    return Text(
      text,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: context.modeTextPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required double labelFontSize,
    required double inputFontSize,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    Color? fillColor,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
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
          cursorColor: context.modePrimary,
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
            fillColor: fillColor ?? context.modeSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: fillColor != null
                    ? context.modePrimary.withValues(alpha: 0.2)
                    : context.modeBorder,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: fillColor != null
                    ? context.modePrimary.withValues(alpha: 0.2)
                    : context.modeBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.modePrimary, width: 2),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierDropdown(double labelFontSize, double inputFontSize) {
    return BlocBuilder<SupplierBloc, SupplierState>(
      builder: (context, state) {
        if (state is SupplierLoading && _selectedSupplierId == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Supplier', labelFontSize),
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
                      style: WorkSansAppTextStyles.medium.copyWith(
                        color: context.modeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (state is SupplierError && _selectedSupplierId == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Supplier', labelFontSize),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.modeError.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.modeError.withValues(alpha: 0.35),
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
              _buildLabel('Supplier', labelFontSize),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedSupplierId,
                decoration: InputDecoration(
                  hintText: 'Select a supplier',
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
                    borderSide: BorderSide(
                      color: context.modePrimary,
                      width: 2,
                    ),
                  ),
                ),
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: inputFontSize,
                  color: context.modeTextPrimary,
                ),
                icon: AppIcon(
                  Icons.keyboard_arrow_down,
                  color: context.modeTextSecondary,
                ),
                dropdownColor: context.modeSurface,
                items: state.suppliers.map((supplier) {
                  return DropdownMenuItem<String>(
                    value: supplier.id,
                    child: Text(
                      supplier.businessName,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: inputFontSize,
                        color: context.modeTextPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    final supplier = state.suppliers.firstWhere(
                      (s) => s.id == value,
                    );
                    setState(() {
                      _selectedSupplierId = value;
                      _selectedSupplierName = supplier.businessName;
                    });
                    _loadSupplierProducts(value);
                  }
                },
              ),
            ],
          );
        }

        // If we have a selected supplier but state changed, preserve the selection
        if (_selectedSupplierId != null && _selectedSupplierName != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Supplier', labelFontSize),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: context.modeSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.modeBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedSupplierName!,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: inputFontSize,
                          color: context.modeTextPrimary,
                        ),
                      ),
                    ),
                    AppIcon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Supplier', labelFontSize),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.modeSurfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.modeBorder),
              ),
              child: Text(
                'No suppliers available',
                style: WorkSansAppTextStyles.medium.copyWith(
                  color: context.modeTextSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriorityDropdown(double labelFontSize, double inputFontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLabel('Priority', labelFontSize),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _showPriorityHelp,
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
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedPriority,
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
              borderSide: BorderSide(color: context.modePrimary, width: 2),
            ),
          ),
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: inputFontSize,
            color: context.modeTextPrimary,
          ),
          icon: AppIcon(
            Icons.keyboard_arrow_down,
            color: context.modeTextSecondary,
          ),
          dropdownColor: context.modeSurface,
          items: _priorities.map((priority) {
            return DropdownMenuItem<String>(
              value: priority,
              child: Text(priority),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedPriority = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildPaymentTermDropdown(double labelFontSize, double inputFontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLabel('Payment Terms', labelFontSize),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _showPaymentTermsHelp,
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
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedPaymentTerm,
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
              borderSide: BorderSide(color: context.modePrimary, width: 2),
            ),
          ),
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: inputFontSize,
            color: context.modeTextPrimary,
          ),
          icon: AppIcon(
            Icons.keyboard_arrow_down,
            color: context.modeTextSecondary,
          ),
          dropdownColor: context.modeSurface,
          items: _paymentTerms.map((term) {
            return DropdownMenuItem<String>(
              value: term,
              child: Text(term.replaceAll('_', ' ')),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedPaymentTerm = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDateField(double inputFontSize) {
    return InkWell(
      onTap: () => _selectDeliveryDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.modeBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM dd, yyyy').format(_expectedDeliveryDate),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: inputFontSize,
                color: context.modeTextPrimary,
              ),
            ),
            AppIcon(
              Icons.calendar_today_outlined,
              color: context.modeTextSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLineItems(
    double labelFontSize,
    double inputFontSize,
    double screenWidth,
  ) {
    List<Widget> widgets = [];
    for (int i = 0; i < _lineItems.length; i++) {
      widgets.add(
        _buildLineItemSection(
          _lineItems[i],
          i,
          labelFontSize,
          inputFontSize,
          screenWidth,
        ),
      );
      if (i < _lineItems.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }
    return widgets;
  }

  Widget _buildLineItemSection(
    OrderLineItem item,
    int index,
    double labelFontSize,
    double inputFontSize,
    double screenWidth,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.modePrimary.withValues(alpha: 0.55),
          width: 1.5,
        ),
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
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w700,
                  color: context.modePrimary,
                ),
              ),
              if (_lineItems.length > 1)
                IconButton(
                  icon: AppIcon(
                    Icons.close,
                    size: 20,
                    color: context.modeError,
                  ),
                  onPressed: () => _removeLineItem(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Product Dropdown
          _buildLabel('Product', labelFontSize),
          const SizedBox(height: 8),
          _buildProductDropdown(item, inputFontSize),
          const SizedBox(height: 16),

          // Quantity and Unit Price Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Quantity', labelFontSize),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: item.quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      cursorColor: context.modePrimary,
                      onChanged: (value) {
                        setState(() {
                          item.calculateTotal();
                        });
                      },
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: inputFontSize,
                        color: context.modeTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
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
                          borderSide: BorderSide(
                            color: context.modeBorder,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.modeBorder,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: context.modePrimary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Unit Price', labelFontSize),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: context.modePrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.modePrimary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        item.selectedProductPrice != null
                            ? 'â‚¦${NumberFormat('#,##0.00').format(item.selectedProductPrice)}'
                            : 'â‚¦0.00',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: inputFontSize,
                          color: context.modeTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Item Notes
          _buildLabel('Notes (Optional)', labelFontSize),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.noteController,
            maxLines: 2,
            cursorColor: context.modePrimary,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: inputFontSize,
              color: context.modeTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Pack separately, handle with care',
              hintStyle: WorkSansAppTextStyles.medium.copyWith(
                fontSize: inputFontSize,
                color: context.modeTextMuted,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: context.modeSurface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
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
                borderSide: BorderSide(color: context.modePrimary, width: 2),
              ),
            ),
          ),

          // Total Display
          if (item.total != null && item.total! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.modePrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Item Total:',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: context.modeTextPrimary,
                    ),
                  ),
                  Text(
                    'â‚¦${NumberFormat('#,##0.00').format(item.total)}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: labelFontSize + 1,
                      fontWeight: FontWeight.w700,
                      color: context.modePrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductDropdown(OrderLineItem item, double inputFontSize) {
    return BlocBuilder<SupplierBloc, SupplierState>(
      builder: (context, state) {
        if (_isLoadingProducts || state is SupplierLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.modeBorder),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.modePrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading products...',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    color: context.modeTextSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is SupplierProductsLoaded) {
          return DropdownButtonFormField<String>(
            initialValue: item.selectedProductId,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Select a product',
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
                borderSide: BorderSide(color: context.modePrimary, width: 2),
              ),
            ),
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: inputFontSize,
              color: context.modeTextPrimary,
            ),
            icon: AppIcon(
              Icons.keyboard_arrow_down,
              color: context.modeTextSecondary,
            ),
            dropdownColor: context.modeSurface,
            items: state.products.map((product) {
              return DropdownMenuItem<String>(
                value: product.id,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.productName,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: inputFontSize,
                        color: context.modeTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'â‚¦${NumberFormat('#,##0.00').format(double.parse(product.baseUnitPrice))} per ${product.unitType}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: inputFontSize - 2,
                        color: context.modeTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? value) {
              if (value != null) {
                final product = state.products.firstWhere((p) => p.id == value);
                setState(() {
                  item.selectedProductId = value;
                  item.selectedProductName = product.productName;
                  item.selectedProductPrice = double.parse(
                    product.baseUnitPrice,
                  );
                  item.calculateTotal();
                });
              }
            },
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.modeSurfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.modeBorder),
          ),
          child: Text(
            _selectedSupplierId == null
                ? 'Please select a supplier first'
                : 'No products available',
            style: TextStyle(color: context.modeTextSecondary),
          ),
        );
      },
    );
  }

  Widget _buildAddLineItemButton(double fontSize) {
    return SizedBox(
      height: _getButtonHeight(fontSize),
      child: OutlinedButton.icon(
        onPressed: _addLineItem,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.modePrimary,
          backgroundColor: context.modePrimary.withValues(alpha: 0.1),
          side: BorderSide(color: context.modePrimary.withValues(alpha: 0.2)),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const AppIcon(Icons.add_circle_outline, size: 20),
        label: Text(
          'Add Another Item',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: context.modePrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(double fontSize, double screenWidth) {
    return SizedBox(
      height: _getSubmitButtonHeight(screenWidth),
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.modePrimary,
          foregroundColor: context.modeTextInverse,
          elevation: 2,
          shadowColor: context.modePrimary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Submit Purchase Order',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: context.modeTextInverse,
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

  Widget _buildPaymentTermItem(
    String title,
    String description,
    IconData icon,
  ) {
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
    if (_formKey.currentState!.validate()) {
      if (_selectedSupplierId == null) {
        _showErrorSnackBar('Please select a supplier');
        return;
      }

      // Validate delivery fields
      if (_deliveryAddressController.text.isEmpty ||
          _deliveryCityController.text.isEmpty ||
          _deliveryStateController.text.isEmpty) {
        _showErrorSnackBar('Please fill in all delivery information');
        return;
      }

      // Validate custom payment term
      String finalPaymentTerm = _selectedPaymentTerm;
      if (_selectedPaymentTerm == 'CUSTOM') {
        if (_customPaymentTermController.text.isEmpty) {
          _showErrorSnackBar('Please specify custom payment terms');
          return;
        }
        finalPaymentTerm = _customPaymentTermController.text;
      }

      // Build items list
      final items = <OrderItemRequest>[];
      for (var lineItem in _lineItems) {
        if (lineItem.selectedProductId != null &&
            lineItem.quantityController.text.isNotEmpty) {
          final quantity = double.tryParse(lineItem.quantityController.text);
          if (quantity == null || quantity <= 0) {
            _showErrorSnackBar('Please enter valid quantities');
            return;
          }

          items.add(
            OrderItemRequest(
              productId: lineItem.selectedProductId!,
              quantityOrdered: quantity,
              notes: lineItem.noteController.text.isNotEmpty
                  ? lineItem.noteController.text
                  : null,
            ),
          );
        }
      }

      if (items.isEmpty) {
        _showErrorSnackBar(
          'Please add at least one item with a product and quantity',
        );
        return;
      }

      // Submit order
      context.read<OrderBloc>().add(
        CreateOrder(
          supplierId: _selectedSupplierId!,
          priority: _selectedPriority,
          expectedDeliveryDate: DateFormat(
            'yyyy-MM-dd',
          ).format(_expectedDeliveryDate),
          paymentTerm: finalPaymentTerm,
          deliveryAddress: _deliveryAddressController.text,
          deliveryCity: _deliveryCityController.text,
          deliveryState: _deliveryStateController.text,
          deliveryInstructions: _deliveryInstructionsController.text.isNotEmpty
              ? _deliveryInstructionsController.text
              : null,
          buyerNotes: _noteController.text.isNotEmpty
              ? _noteController.text
              : null,
          items: items,
        ),
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

  void _showSuccessDialog(String orderNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.modeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.modeSuccess.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                Icons.check_circle,
                color: context.modeSuccess,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Order Created!',
              style: WorkSansAppTextStyles.medium.copyWith(
                color: context.modeTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your purchase order has been successfully submitted for approval.',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/order-list');
            },
            child: Text(
              'View Orders',
              style: WorkSansAppTextStyles.medium.copyWith(
                color: context.modePrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Reset form
              context.read<OrderBloc>().add(const ResetOrderState());
              _resetForm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.modePrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Create Another',
              style: WorkSansAppTextStyles.medium.copyWith(
                color: context.modeTextInverse,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedSupplierId = null;
      _selectedSupplierName = null;
      _selectedPaymentTerm = 'NET_30';
      _deliveryAddressController.clear();
      _deliveryCityController.clear();
      _deliveryStateController.clear();
      _deliveryInstructionsController.clear();
      _noteController.clear();
      _customPaymentTermController.clear();
      _lineItems.clear();
      _lineItems.add(OrderLineItem());
      _isLoadingProducts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OrderBloc, OrderState>(
          listener: (context, state) {
            if (state is OrderCreated) {
              _showSuccessDialog(state.orderNumber);
            } else if (state is OrderError) {
              String message = 'Failed to create order';

              switch (state.errorType) {
                case OrderErrorType.network:
                  message =
                      'Network error. Please check your internet connection.';
                  break;
                case OrderErrorType.timeout:
                  message = 'Request timed out. Please try again.';
                  break;
                case OrderErrorType.server:
                  message = 'Server error. Please try again later.';
                  break;
                case OrderErrorType.validation:
                  message = state.error;
                  break;
                case OrderErrorType.general:
                  message = state.error;
                  break;
              }

              _showErrorSnackBar(message);
            }
          },
        ),
        BlocListener<SupplierBloc, SupplierState>(
          listener: (context, state) {
            // Update loading state when products are loaded
            if (state is SupplierProductsLoaded) {
              setState(() {
                _isLoadingProducts = false;
              });
            } else if (state is SupplierError && _isLoadingProducts) {
              setState(() {
                _isLoadingProducts = false;
              });
            }
          },
        ),
      ],
      child: DefaultTextStyle.merge(
        style: WorkSansAppTextStyles.medium,
        child: Scaffold(
          backgroundColor: context.modeBackground,
          appBar: _buildAppBar(context),
          body: _buildBody(context),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.modeSurface,
      elevation: 0,
      leading: IconButton(
        icon: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Create Purchase Order',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: context.modeTextPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, orderState) {
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

                            // PO Number and Order Date Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _poNumberController,
                                    label: 'PO Number',
                                    labelFontSize: labelFontSize,
                                    inputFontSize: inputFontSize,
                                    readOnly: true,
                                    fillColor: context.modePrimary.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _orderDateController,
                                    label: 'Order Date',
                                    labelFontSize: labelFontSize,
                                    inputFontSize: inputFontSize,
                                    readOnly: true,
                                    fillColor: context.modePrimary.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Supplier Dropdown
                            _buildSupplierDropdown(
                              labelFontSize,
                              inputFontSize,
                            ),
                            const SizedBox(height: 16),

                            // Priority and Payment Terms
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPriorityDropdown(
                                    labelFontSize,
                                    inputFontSize,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildPaymentTermDropdown(
                                    labelFontSize,
                                    inputFontSize,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Custom Payment Term Field (shows when CUSTOM is selected)
                            if (_selectedPaymentTerm == 'CUSTOM') ...[
                              _buildTextField(
                                controller: _customPaymentTermController,
                                label: 'Custom Payment Terms',
                                labelFontSize: labelFontSize,
                                inputFontSize: inputFontSize,
                                hintText:
                                    'e.g., 25% advance, 75% within 45 days',
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Expected Delivery Date
                            Row(
                              children: [
                                _buildLabel(
                                  'Expected Delivery Date',
                                  labelFontSize,
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: _showDeliveryDateHelp,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: context.modePrimary.withValues(
                                        alpha: 0.1,
                                      ),
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
                            const SizedBox(height: 8),
                            _buildDateField(inputFontSize),
                            const SizedBox(height: 16),

                            // Delivery Information Section
                            Row(
                              children: [
                                _buildSectionHeader(
                                  'Delivery Information',
                                  labelFontSize,
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: _showDeliveryAddressHelp,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: context.modePrimary.withValues(
                                        alpha: 0.1,
                                      ),
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
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _deliveryAddressController,
                              label: 'Delivery Address',
                              labelFontSize: labelFontSize,
                              inputFontSize: inputFontSize,
                              hintText: 'Enter street address',
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _deliveryCityController,
                                    label: 'City',
                                    labelFontSize: labelFontSize,
                                    inputFontSize: inputFontSize,
                                    hintText: 'e.g. Lagos',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _deliveryStateController,
                                    label: 'State',
                                    labelFontSize: labelFontSize,
                                    inputFontSize: inputFontSize,
                                    hintText: 'e.g. Lagos',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _deliveryInstructionsController,
                              label: 'Delivery Instructions (Optional)',
                              labelFontSize: labelFontSize,
                              inputFontSize: inputFontSize,
                              hintText: 'e.g. Call 30 minutes before delivery',
                            ),
                            const SizedBox(height: 16),

                            // Line Items Section
                            _buildSectionHeader('Order Items', labelFontSize),
                            const SizedBox(height: 16),

                            ..._buildLineItems(
                              labelFontSize,
                              inputFontSize,
                              constraints.maxWidth,
                            ),

                            // Add Line Item Button
                            const SizedBox(height: 16),
                            _buildAddLineItemButton(buttonFontSize),
                            const SizedBox(height: 24),

                            // Note/Instructions
                            _buildTextField(
                              controller: _noteController,
                              label: 'Buyer Notes (Optional)',
                              labelFontSize: labelFontSize,
                              inputFontSize: inputFontSize,
                              hintText: 'Enter any special instructions...',
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
                if (orderState is OrderCreating)
                  Container(
                    color: Colors.black.withValues(alpha: 0.54),
                    child: Center(
                      child: Card(
                        color: context.modeSurface,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: context.modePrimary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Creating your order...',
                                style: WorkSansAppTextStyles.medium.copyWith(
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

  // Responsive sizing functions
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

  double _getButtonHeight(double fontSize) {
    return fontSize * 3.2;
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

// Updated Line Item Model with product selection
class OrderLineItem {
  String? selectedProductId;
  String? selectedProductName;
  double? selectedProductPrice;
  double? total;

  final TextEditingController quantityController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  void calculateTotal() {
    if (selectedProductPrice != null && quantityController.text.isNotEmpty) {
      final quantity = double.tryParse(quantityController.text);
      if (quantity != null && quantity > 0) {
        total = selectedProductPrice! * quantity;
      } else {
        total = null;
      }
    } else {
      total = null;
    }
  }

  void dispose() {
    quantityController.dispose();
    noteController.dispose();
  }
}
