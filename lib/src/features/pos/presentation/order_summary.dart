import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_cubit.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/tax-config-bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/order_session_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/tax_config_model.dart';
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
  //  Core calculations ─

  double _calculateSubtotal() {
    double subtotal = 0;
    widget.orderItems.forEach((item, quantity) {
      subtotal += double.parse(item.price) * quantity;
    });
    return subtotal;
  }

  double _taxableAmount() => _calculateSubtotal() - widget.discount;

  double _calculateTotalTax(List<TaxConfiguration> salesTaxes) {
    final base = _taxableAmount();
    return salesTaxes.fold(
      0.0,
      (sum, tax) => sum + tax.calculateTaxAmount(base),
    );
  }

  double _calculateGrandTotal(List<TaxConfiguration> salesTaxes) {
    return _taxableAmount() + _calculateTotalTax(salesTaxes);
  }

  String _formatPrice(double price) => '₦${price.toStringAsFixed(2)}';

  //  Navigation ──

  void _continueToPayment(List<TaxConfiguration> salesTaxes) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<PosOrderBloc>()),
            BlocProvider.value(value: context.read<OrderSessionCubit>()),
            BlocProvider.value(value: context.read<TaxConfigBloc>()),
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
            totalAmount: _calculateGrandTotal(salesTaxes),
            sessionId: widget.sessionId,
          ),
        ),
      ),
    );
  }

  //  Build ─

  @override
  Widget build(BuildContext context) {
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
        // React to tax config state so the totals update once taxes load.
        body: BlocBuilder<TaxConfigBloc, TaxConfigState>(
          builder: (context, taxState) {
            // Resolve the applicable sales taxes from the current state.
            final salesTaxes = taxState is TaxConfigLoaded
                ? taxState.salesTaxes
                : <TaxConfiguration>[];

            final subtotal = _calculateSubtotal();
            final discount = widget.discount;
            final totalTax = _calculateTotalTax(salesTaxes);
            final grandTotal = _calculateGrandTotal(salesTaxes);

            return Column(
              children: [
                // ── Scrollable body ─
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Order Details Card
                        _OrderDetailsCard(widget: widget),

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

                        // Item rows
                        ...widget.orderItems.entries.map((entry) {
                          final item = entry.key;
                          final quantity = entry.value;
                          final totalPrice =
                              double.parse(item.price) * quantity;
                          final hasSpecialRequest = widget.specialRequests
                              .containsKey(item.id);

                          return _OrderItemCard(
                            item: item,
                            quantity: quantity,
                            totalPrice: totalPrice,
                            specialRequest: hasSpecialRequest
                                ? widget.specialRequests[item.id]
                                : null,
                            formatPrice: _formatPrice,
                          );
                        }),

                        const SizedBox(height: 8),
                        Divider(color: Colors.grey[300], thickness: 1),
                        const SizedBox(height: 16),

                        // Subtotal
                        _buildSummaryRow('Subtotal', _formatPrice(subtotal)),
                        const SizedBox(height: 12),

                        // Discount
                        if (discount > 0) ...[
                          _buildSummaryRow(
                            'Discount',
                            '-${_formatPrice(discount)}',
                            isDiscount: true,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── Tax rows
                        if (taxState is TaxConfigLoading)
                          _TaxLoadingRow()
                        else if (taxState is TaxConfigError)
                          _TaxErrorRow(message: taxState.error)
                        else if (salesTaxes.isEmpty &&
                            taxState is! TaxConfigInitial)
                          _buildSummaryRow('Tax', _formatPrice(0))
                        else
                          ...salesTaxes.map(
                            (tax) => _TaxRow(
                              tax: tax,
                              taxableAmount: _taxableAmount(),
                              formatPrice: _formatPrice,
                            ),
                          ),

                        // Total additional tax (only when > 1 tax line)
                        if (salesTaxes.length > 1) ...[
                          const SizedBox(height: 4),
                          _buildSummaryRow('Total Tax', _formatPrice(totalTax)),
                        ],

                        const SizedBox(height: 16),

                        // Grand Total
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

                // ── Bottom CTA
                _BottomCta(
                  onPressed: taxState is TaxConfigLoading
                      ? null // disable while taxes are loading
                      : () => _continueToPayment(salesTaxes),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  //  Helpers ──

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
}

//  Sub-widgets ─

class _OrderDetailsCard extends StatelessWidget {
  final OrderSummaryScreen widget;

  const _OrderDetailsCard({required this.widget});

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _OrderItemCard extends StatelessWidget {
  final ApiMenuItem item;
  final int quantity;
  final double totalPrice;
  final String? specialRequest;
  final String Function(double) formatPrice;

  const _OrderItemCard({
    required this.item,
    required this.quantity,
    required this.totalPrice,
    required this.specialRequest,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
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
                      child: const Icon(Icons.restaurant, size: 24),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.dishName,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kprimaryTextColor1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$quantity x ${formatPrice(double.parse(item.price))}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: kprimaryTextColor2,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatPrice(totalPrice),
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kprimaryTextColor1,
                ),
              ),
            ],
          ),
          if (specialRequest != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, size: 16, color: kPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      specialRequest!,
                      style: WorkSansAppTextStyles.medium.copyWith(
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
  }
}

/// Renders a single tax line in the summary section.
class _TaxRow extends StatelessWidget {
  final TaxConfiguration tax;
  final double taxableAmount;
  final String Function(double) formatPrice;

  const _TaxRow({
    required this.tax,
    required this.taxableAmount,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    final amount = tax.calculateTaxAmount(taxableAmount);

    // Build a descriptive label: e.g. "VAT (7.5%)" or "Service Fee (flat)"
    final rateLabel = tax.taxRateType.toUpperCase() == 'PERCENTAGE'
        ? '${tax.taxRate.toStringAsFixed(tax.taxRate % 1 == 0 ? 0 : 2)}%'
        : 'flat';
    final label =
        '${tax.taxName} ($rateLabel)${tax.isInclusive ? ' *incl.' : ''}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: kprimaryTextColor2,
              ),
            ),
          ),
          Text(
            // Inclusive tax shows the baked-in amount for transparency
            tax.isInclusive
                ? '${formatPrice(tax.extractInclusiveTaxAmount(taxableAmount))} incl.'
                : formatPrice(amount),
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: kprimaryTextColor1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxLoadingRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tax',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: kprimaryTextColor2,
            ),
          ),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

class _TaxErrorRow extends StatelessWidget {
  final String message;

  const _TaxErrorRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Tax unavailable: $message',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  final VoidCallback? onPressed;

  const _BottomCta({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            disabledBackgroundColor: kPrimary.withValues(alpha: 0.5),
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
    );
  }
}
