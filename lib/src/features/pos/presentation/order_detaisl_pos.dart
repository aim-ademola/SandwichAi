import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

// Models for order data
class OrderDetails {
  final String orderType;
  final String? tableNumber;
  final String? customerName;
  final String? customerPhone;
  final double discount;
  final String? specialInstructions;

  OrderDetails({
    required this.orderType,
    this.tableNumber,
    this.customerName,
    this.customerPhone,
    this.discount = 0,
    this.specialInstructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderType': orderType,
      if (tableNumber != null) 'tableNumber': tableNumber,
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      'discount': discount,
      if (specialInstructions != null)
        'specialInstructions': specialInstructions,
    };
  }
}

// Extension to show order details dialog
extension OrderDetailsDialogExtension on BuildContext {
  Future<OrderDetails?> showOrderDetailsDialog({
    required Map<String, int> orderItems,
    required double totalAmount,
  }) {
    return showDialog<OrderDetails>(
      context: this,
      barrierDismissible: false,
      builder: (context) =>
          OrderDetailsDialog(orderItems: orderItems, totalAmount: totalAmount),
    );
  }
}

class OrderDetailsDialog extends StatefulWidget {
  final Map<String, int> orderItems;
  final double totalAmount;

  const OrderDetailsDialog({
    super.key,
    required this.orderItems,
    required this.totalAmount,
  });

  @override
  State<OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<OrderDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Controllers
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _tableNumberController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _specialInstructionsController = TextEditingController();

  // State
  String _selectedOrderType = 'DINE_IN';
  int _currentPage = 0;

  final List<String> _orderTypes = ['DINE_IN', 'TAKE_OUT', 'DELIVERY'];

  @override
  void dispose() {
    _pageController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _tableNumberController.dispose();
    _discountController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      // Validate order type selection
      if (_selectedOrderType == 'DINE_IN' &&
          _tableNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter table number for dine-in orders'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
    }

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  void _submitOrder() {
    if (_formKey.currentState!.validate()) {
      final orderDetails = OrderDetails(
        orderType: _selectedOrderType,
        tableNumber: _selectedOrderType == 'DINE_IN'
            ? _tableNumberController.text.trim()
            : null,
        customerName: _customerNameController.text.trim().isNotEmpty
            ? _customerNameController.text.trim()
            : null,
        customerPhone: _customerPhoneController.text.trim().isNotEmpty
            ? _customerPhoneController.text.trim()
            : null,
        discount: double.tryParse(_discountController.text) ?? 0,
        specialInstructions:
            _specialInstructionsController.text.trim().isNotEmpty
            ? _specialInstructionsController.text.trim()
            : null,
      );

      Navigator.of(context).pop(orderDetails);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Order Details',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.orderItems.length} items • ₦${widget.totalAmount.toStringAsFixed(2)}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? kPrimary
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Content
            Flexible(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildOrderTypePage(),
                    _buildCustomerInfoPage(),
                    _buildAdditionalDetailsPage(),
                  ],
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: kPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Back',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kPrimary,
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentPage < 2 ? _nextPage : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _currentPage < 2 ? 'Continue' : 'Submit Order',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildOrderTypePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Order Type',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 16),

          // Order type cards
          ..._orderTypes.map((type) {
            final isSelected = _selectedOrderType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedOrderType = type),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? kPrimary.withValues(alpha: 0.1)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected ? kPrimary : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getOrderTypeIcon(type),
                      color: isSelected ? kPrimary : kprimaryTextColor2,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getOrderTypeLabel(type),
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? kPrimary : kprimaryTextColor1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getOrderTypeDescription(type),
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 13,
                              color: kprimaryTextColor2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: kPrimary, size: 24),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 16),

          // Table number field (only for dine-in)
          if (_selectedOrderType == 'DINE_IN') ...[
            Text(
              'Table Number',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tableNumberController,
              decoration: InputDecoration(
                hintText: 'e.g., Table 5',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  color: kprimaryTextColor2,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F6F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              validator: (value) {
                if (_selectedOrderType == 'DINE_IN' &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Table number is required for dine-in orders';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Information',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional - Add customer details for better service',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              color: kprimaryTextColor2,
            ),
          ),
          const SizedBox(height: 20),

          // Customer name
          Text(
            'Customer Name',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _customerNameController,
            decoration: InputDecoration(
              hintText: 'e.g., John Doe',
              hintStyle: WorkSansAppTextStyles.medium.copyWith(
                color: kprimaryTextColor2,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F6F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Customer phone
          Text(
            'Phone Number',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _customerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'e.g., +234 803 123 4567',
              hintStyle: WorkSansAppTextStyles.medium.copyWith(
                color: kprimaryTextColor2,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F6F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                // Basic phone validation
                final phoneRegex = RegExp(r'^\+?[\d\s\-()]+$');
                if (!phoneRegex.hasMatch(value)) {
                  return 'Please enter a valid phone number';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Details',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 20),

          // Discount
          Text(
            'Discount (₦)',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: WorkSansAppTextStyles.medium.copyWith(
                color: kprimaryTextColor2,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F6F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final discount = double.tryParse(value);
                if (discount == null || discount < 0) {
                  return 'Please enter a valid discount amount';
                }
                if (discount > widget.totalAmount) {
                  return 'Discount cannot exceed total amount';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Special instructions
          Text(
            'Special Instructions',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _specialInstructionsController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Any special requests or notes...',
              hintStyle: WorkSansAppTextStyles.medium.copyWith(
                color: kprimaryTextColor2,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F6F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Order summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal', widget.totalAmount),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Discount',
                  -(double.tryParse(_discountController.text) ?? 0),
                  isDiscount: true,
                ),
                const Divider(height: 20),
                _buildSummaryRow(
                  'Total',
                  widget.totalAmount -
                      (double.tryParse(_discountController.text) ?? 0),
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: kprimaryTextColor1,
          ),
        ),
        Text(
          '₦${amount.toStringAsFixed(2)}',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isDiscount
                ? Colors.red
                : (isTotal ? kPrimary : kprimaryTextColor1),
          ),
        ),
      ],
    );
  }

  IconData _getOrderTypeIcon(String type) {
    switch (type) {
      case 'DINE_IN':
        return Icons.restaurant;
      case 'TAKE_AWAY':
        return Icons.shopping_bag_outlined;
      case 'DELIVERY':
        return Icons.delivery_dining;
      default:
        return Icons.receipt;
    }
  }

  String _getOrderTypeLabel(String type) {
    switch (type) {
      case 'DINE_IN':
        return 'Dine In';
      case 'TAKE_AWAY':
        return 'Take Away';
      case 'DELIVERY':
        return 'Delivery';
      default:
        return type;
    }
  }

  String _getOrderTypeDescription(String type) {
    switch (type) {
      case 'DINE_IN':
        return 'Customer will eat at the restaurant';
      case 'TAKE_AWAY':
        return 'Customer will take order to go';
      case 'DELIVERY':
        return 'Order will be delivered to customer';
      default:
        return '';
    }
  }
}
