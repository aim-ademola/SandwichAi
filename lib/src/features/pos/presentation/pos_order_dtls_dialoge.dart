import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

class PosOrderDetails {
  final String orderType;
  final String? tableNumber;
  final String? customerName;
  final String? customerPhone;
  final double discount;
  final String? specialInstructions;

  PosOrderDetails({
    required this.orderType,
    this.tableNumber,
    this.customerName,
    this.customerPhone,
    this.discount = 0,
    this.specialInstructions,
  });

  factory PosOrderDetails.fromJson(Map<String, dynamic> json) {
    return PosOrderDetails(
      orderType: json['orderType']?.toString() ?? 'DINE_IN',
      tableNumber: json['tableNumber']?.toString(),
      customerName: json['customerName']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      specialInstructions: json['specialInstructions']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderType': orderType,
      'tableNumber': tableNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'discount': discount,
      'specialInstructions': specialInstructions,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosOrderDetails &&
          other.orderType == orderType &&
          other.tableNumber == tableNumber &&
          other.customerName == customerName &&
          other.customerPhone == customerPhone &&
          other.discount == discount &&
          other.specialInstructions == specialInstructions;

  @override
  int get hashCode => Object.hash(
    orderType,
    tableNumber,
    customerName,
    customerPhone,
    discount,
    specialInstructions,
  );
}

extension PosOrderDetailsDialogExtension on BuildContext {
  Future<PosOrderDetails?> showPosOrderDetailsDialog({
    required Map<String, int> orderItems,
    required double totalAmount,
    String? initialSpecialInstructions,
  }) async {
    return showDialog<PosOrderDetails>(
      context: this,
      barrierDismissible: false,
      builder: (context) => _PosOrderDetailsDialog(
        orderItems: orderItems,
        totalAmount: totalAmount,
        initialSpecialInstructions: initialSpecialInstructions,
      ),
    );
  }
}

class _PosOrderDetailsDialog extends StatefulWidget {
  final Map<String, int> orderItems;
  final double totalAmount;
  final String? initialSpecialInstructions;

  const _PosOrderDetailsDialog({
    required this.orderItems,
    required this.totalAmount,
    this.initialSpecialInstructions,
  });

  @override
  State<_PosOrderDetailsDialog> createState() => _PosOrderDetailsDialogState();
}

class _PosOrderDetailsDialogState extends State<_PosOrderDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tableController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _specialInstructionsController = TextEditingController();

  String _selectedOrderType = 'DINE_IN';

  final List<Map<String, String>> _orderTypes = [
    {'value': 'DINE_IN', 'label': 'Dine In'},
    {'value': 'TAKEAWAY', 'label': 'Take Away'},
    {'value': 'DELIVERY', 'label': 'Delivery'},
    {'value': 'ONLINE', 'label': 'Online'},
  ];

  @override
  void initState() {
    super.initState();
    _specialInstructionsController.text =
        widget.initialSpecialInstructions ?? '';
  }

  @override
  void dispose() {
    _tableController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _discountController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  void _submitOrder() {
    if (_formKey.currentState!.validate()) {
      final orderDetails = PosOrderDetails(
        orderType: _selectedOrderType,
        tableNumber: _tableController.text.trim().isEmpty
            ? null
            : _tableController.text.trim(),
        customerName: _customerNameController.text.trim().isEmpty
            ? null
            : _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim().isEmpty
            ? null
            : _customerPhoneController.text.trim(),
        discount: double.tryParse(_discountController.text) ?? 0,
        specialInstructions: _specialInstructionsController.text.trim().isEmpty
            ? null
            : _specialInstructionsController.text.trim(),
      );

      Navigator.of(context).pop(orderDetails);
    }
  }

  TextStyle _labelStyle(BuildContext context) {
    return WorkSansAppTextStyles.medium.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: context.modeTextPrimary,
    );
  }

  TextStyle _fieldTextStyle(BuildContext context) {
    return WorkSansAppTextStyles.medium.copyWith(
      fontSize: 14,
      color: context.modeTextPrimary,
      fontWeight: FontWeight.w600,
    );
  }

  OutlineInputBorder _fieldBorder(BuildContext context, Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: WorkSansAppTextStyles.medium.copyWith(
        fontSize: 14,
        color: context.modeTextMuted,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: context.modeSurfaceAlt,
      border: _fieldBorder(context, context.modeBorder),
      enabledBorder: _fieldBorder(context, context.modeBorder),
      focusedBorder: _fieldBorder(context, context.modePrimary),
      errorBorder: _fieldBorder(context, context.modeError),
      focusedErrorBorder: _fieldBorder(context, context.modeError),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discountedTotal =
        widget.totalAmount - (double.tryParse(_discountController.text) ?? 0);

    return Dialog(
      backgroundColor: context.modeSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Order Details',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: context.modeTextPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: AppIcon(
                          Icons.close,
                          color: context.modeTextPrimary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Order Type
                  Text('Order Type *', style: _labelStyle(context)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: context.modeSurfaceAlt,
                      border: Border.all(color: context.modeBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedOrderType,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      dropdownColor: context.modeSurface,
                      iconEnabledColor: context.modeTextSecondary,
                      style: _fieldTextStyle(context),
                      items: _orderTypes.map((type) {
                        return DropdownMenuItem(
                          value: type['value'],
                          child: Text(
                            type['label']!,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 14,
                              color: context.modeTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedOrderType = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Table Number (only for Dine In)
                  if (_selectedOrderType == 'DINE_IN') ...[
                    Text('Table Number', style: _labelStyle(context)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tableController,
                      decoration: _fieldDecoration(
                        context,
                        hintText: 'e.g., Table 5',
                      ),
                      style: _fieldTextStyle(context),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Customer Name
                  Text('Customer Name', style: _labelStyle(context)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customerNameController,
                    decoration: _fieldDecoration(
                      context,
                      hintText: 'Enter customer name',
                    ),
                    style: _fieldTextStyle(context),
                  ),
                  const SizedBox(height: 16),

                  // Customer Phone
                  Text('Customer Phone', style: _labelStyle(context)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customerPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _fieldDecoration(
                      context,
                      hintText: '+234 803 123 4567',
                    ),
                    style: _fieldTextStyle(context),
                  ),
                  const SizedBox(height: 16),

                  // Discount
                  Text('Discount (N)', style: _labelStyle(context)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {}); // Rebuild to update total
                    },
                    decoration: _fieldDecoration(context, hintText: '0'),
                    style: _fieldTextStyle(context),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final discount = double.tryParse(value);
                        if (discount == null) {
                          return 'Please enter a valid number';
                        }
                        if (discount < 0) {
                          return 'Discount cannot be negative';
                        }
                        if (discount > widget.totalAmount) {
                          return 'Discount cannot exceed total amount';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Special Instructions
                  Text('Special Instructions', style: _labelStyle(context)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _specialInstructionsController,
                    maxLines: 3,
                    decoration: _fieldDecoration(
                      context,
                      hintText: 'Any special instructions for this order...',
                    ),
                    style: _fieldTextStyle(context),
                  ),
                  const SizedBox(height: 24),

                  // Total Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.modeSurfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.modeBorder),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal:',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                color: context.modeTextSecondary,
                              ),
                            ),
                            Text(
                              'N${widget.totalAmount.toStringAsFixed(2)}',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                color: context.modeTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Discount:',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                color: context.modeTextSecondary,
                              ),
                            ),
                            Text(
                              '- N${(double.tryParse(_discountController.text) ?? 0).toStringAsFixed(2)}',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                color: context.modeError,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 24, color: context.modeDivider),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.modeTextPrimary,
                              ),
                            ),
                            Text(
                              'N${discountedTotal.toStringAsFixed(2)}',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.modePrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                            side: BorderSide(color: context.modeBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.modeTextPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.modePrimary,
                            foregroundColor: context.modeTextInverse,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Submit Order',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 14,
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
        ),
      ),
    );
  }
}
