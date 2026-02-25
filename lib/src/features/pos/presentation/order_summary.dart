import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_cubit.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/order_session_model.dart';
import 'package:sandwich_ai/src/features/pos/presentation/minimze.dart';
import 'package:sandwich_ai/src/features/pos/presentation/payment_method.dart';

class OrderSummaryScreen extends StatefulWidget {
  final Map<ApiMenuItem, int> orderItems;
  final Map<String, String> specialRequests;
  final String orderType;
  final String? tableNumber;
  final String? customerName;
  final String? customerPhone;
  final double discount;
  final String? specialInstructions;
  final String? sessionId;

  const OrderSummaryScreen({
    super.key,
    this.sessionId,
    required this.orderItems,
    required this.specialRequests,
    required this.orderType,
    this.tableNumber,
    this.customerName,
    this.customerPhone,
    this.discount = 0,
    this.specialInstructions,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  double _calculateSubtotal() {
    double subtotal = 0;
    widget.orderItems.forEach((item, quantity) {
      subtotal += double.parse(item.price) * quantity;
    });
    return subtotal;
  }

  double _calculateTaxes() {
    final subtotal = _calculateSubtotal();
    final discount = widget.discount;
    return (subtotal - discount) * 0.0250;
  }

  double _calculateGrandTotal() {
    final subtotal = _calculateSubtotal();
    final discount = widget.discount;
    final taxes = _calculateTaxes();
    return subtotal - discount + taxes;
  }

  String _formatPrice(double price) {
    return '₦${price.toStringAsFixed(2)}';
  }

  void _continueToPayment() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<PosOrderBloc>()),
            BlocProvider.value(value: context.read<OrderSessionCubit>()),
          ],
          child: PaymentMethodScreen(
            orderItems: widget.orderItems,
            specialRequests: widget.specialRequests,
            orderType: widget.orderType,
            tableNumber: widget.tableNumber,
            customerName: widget.customerName,
            customerPhone: widget.customerPhone,
            discount: widget.discount,
            specialInstructions: widget.specialInstructions,
            totalAmount: _calculateGrandTotal(),
            sessionId: widget.sessionId,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotal();
    final discount = widget.discount;
    final taxes = _calculateTaxes();
    final grandTotal = _calculateGrandTotal();

    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kprimaryTextColor1),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Order Summary',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          actions: [
            MinimizeButton(
              sessionId: widget.sessionId,
              screen: MinimizedScreen.orderSummary,
            ),
          ],
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Order Details Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F6F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getOrderTypeIcon(widget.orderType),
                                color: kPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getOrderTypeLabel(widget.orderType),
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: kprimaryTextColor1,
                                ),
                              ),
                            ],
                          ),
                          if (widget.tableNumber != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Table: ${widget.tableNumber}',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                color: kprimaryTextColor2,
                              ),
                            ),
                          ],
                          if (widget.customerName != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Customer: ${widget.customerName}',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                color: kprimaryTextColor2,
                              ),
                            ),
                          ],
                          if (widget.customerPhone != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Phone: ${widget.customerPhone}',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                color: kprimaryTextColor2,
                              ),
                            ),
                          ],
                          if (widget.specialInstructions != null) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Text(
                              'Special Instructions:',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kprimaryTextColor1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.specialInstructions!,
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                color: kprimaryTextColor2,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Order Items',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kprimaryTextColor1,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ...widget.orderItems.entries.map((entry) {
                      final item = entry.key;
                      final quantity = entry.value;
                      final totalPrice = double.parse(item.price) * quantity;
                      final hasSpecialRequest = widget.specialRequests
                          .containsKey(item.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.imageUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 48,
                                        height: 48,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.restaurant,
                                          size: 24,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.dishName,
                                        style: WorkSansAppTextStyles.medium
                                            .copyWith(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: kprimaryTextColor1,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$quantity x ${_formatPrice(double.parse(item.price))}',
                                        style: WorkSansAppTextStyles.medium
                                            .copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: kprimaryTextColor2,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatPrice(totalPrice),
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: kprimaryTextColor1,
                                  ),
                                ),
                              ],
                            ),
                            if (hasSpecialRequest) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit_note,
                                      size: 16,
                                      color: kPrimary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.specialRequests[item.id]!,
                                        style: WorkSansAppTextStyles.medium
                                            .copyWith(
                                              fontSize: 13,
                                              color: kPrimary,
                                              fontStyle: FontStyle.italic,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 8),
                    Divider(color: Colors.grey[300], thickness: 1),
                    const SizedBox(height: 16),

                    _buildSummaryRow('Subtotal', _formatPrice(subtotal)),
                    const SizedBox(height: 12),

                    if (discount > 0)
                      _buildSummaryRow(
                        'Discount',
                        '-${_formatPrice(discount)}',
                        isDiscount: true,
                      ),
                    if (discount > 0) const SizedBox(height: 12),

                    _buildSummaryRow('Taxes (2.5%)', _formatPrice(taxes)),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Grand Total',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: kprimaryTextColor1,
                          ),
                        ),
                        Text(
                          _formatPrice(grandTotal),
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _continueToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue to Payment',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: kprimaryTextColor2,
          ),
        ),
        Text(
          value,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDiscount ? Colors.red : kprimaryTextColor1,
          ),
        ),
      ],
    );
  }

  IconData _getOrderTypeIcon(String orderType) {
    switch (orderType) {
      case 'DINE_IN':
        return Icons.restaurant;
      case 'TAKE_OUT':
        return Icons.shopping_bag;
      case 'DELIVERY':
        return Icons.delivery_dining;
      default:
        return Icons.receipt;
    }
  }

  String _getOrderTypeLabel(String orderType) {
    switch (orderType) {
      case 'DINE_IN':
        return 'Dine In';
      case 'TAKE_OUT':
        return 'Take Out';
      case 'DELIVERY':
        return 'Delivery';
      default:
        return orderType;
    }
  }
}
