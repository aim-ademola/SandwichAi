import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_cubit.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/bloc/tax-config-bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/order_session_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/tax_config_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_order_repo.dart';
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
  // Core calculations

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

  bool get _isDineIn => _normalizeOrderType(widget.orderType) == 'DINE_IN';
  // Navigation

  void _confirmOrder() {
    final items = widget.orderItems.entries.map((entry) {
      return PosOrderItemPayload(
        menuItemId: entry.key.id,
        quantity: entry.value,
        specialRequest: widget.specialRequests[entry.key.id],
      );
    }).toList();

    context.read<PosOrderBloc>().add(
      CreatePosOrder(
        orderType: _normalizeOrderType(widget.orderType),
        tableNumber: widget.tableNumber,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        items: items,
        discount: widget.discount,
        specialInstructions: widget.specialInstructions,
        confirmForKitchen: _isDineIn,
      ),
    );
  }

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

  String _normalizeOrderType(String orderType) {
    switch (orderType.toLowerCase().trim().replaceAll(' ', '_')) {
      case 'dine_in':
      case 'dinein':
      case 'dine-in':
        return 'DINE_IN';
      case 'take_out':
      case 'takeout':
      case 'take-away':
      case 'takeaway':
      case 'to_go':
      case 'togo':
        return 'TAKEAWAY';
      case 'delivery':
        return 'DELIVERY';
      case 'online':
        return 'ONLINE';
      default:
        return orderType.toUpperCase().replaceAll(' ', '_');
    }
  }
  // Build

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PosOrderBloc, PosOrderState>(
          listener: (context, state) {
            if (state is PosOrderCreated) {
              final orderSessionCubit = context.read<OrderSessionCubit>();
              final posOrderBloc = context.read<PosOrderBloc>();
              if (widget.sessionId != null) {
                orderSessionCubit.closeSession(widget.sessionId!);
              }
              orderSessionCubit.createSession();
              posOrderBloc.add(const ResetPosOrderState());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Order sent to Kitchen #${state.order.orderId}',
                  ),
                  backgroundColor: context.modeSuccess,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else if (state is PosOrderError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: context.modeError,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
      child: DefaultTextStyle.merge(
        style: WorkSansAppTextStyles.medium,
        child: Scaffold(
          backgroundColor: context.modeBackground,
          appBar: AppBar(
            backgroundColor: context.modeSurface,
            elevation: 0,
            leading: IconButton(
              icon: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Order Summary',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
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
                  // Scrollable body
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
                              color: context.modeTextPrimary,
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
                          Divider(color: context.modeBorder, thickness: 1),
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
                          // Tax rows
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
                            _buildSummaryRow(
                              'Total Tax',
                              _formatPrice(totalTax),
                            ),
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
                                  color: context.modeTextPrimary,
                                ),
                              ),
                              Text(
                                _formatPrice(grandTotal),
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: context.modePrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  // Bottom CTA
                  BlocBuilder<PosOrderBloc, PosOrderState>(
                    builder: (context, orderState) {
                      return _BottomCta(
                        label: _isDineIn
                            ? 'Send to Kitchen'
                            : 'Continue to Payment',
                        isLoading: orderState is PosOrderCreating,
                        onPressed:
                            taxState is TaxConfigLoading ||
                                orderState is PosOrderCreating
                            ? null
                            : () {
                                if (_isDineIn) {
                                  _confirmOrder();
                                } else {
                                  _continueToPayment(salesTaxes);
                                }
                              },
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
  // Helpers

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
            color: context.modeTextSecondary,
          ),
        ),
        Text(
          value,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDiscount ? context.modeError : context.modeTextPrimary,
          ),
        ),
      ],
    );
  }
}

// Sub-widgets

class _OrderDetailsCard extends StatelessWidget {
  final OrderSummaryScreen widget;

  const _OrderDetailsCard({required this.widget});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Center(
                child: AppIcon(
                  _getOrderTypeIcon(widget.orderType),
                  color: context.modePrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getOrderTypeLabel(widget.orderType),
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
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
                color: context.modeTextSecondary,
              ),
            ),
          ],
          if (widget.orderType == 'DINE_IN') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.modePrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Center(
                    child: AppIcon(
                      Icons.restaurant_menu_rounded,
                      color: context.modePrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dine-in orders are served before payment.',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.modePrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (widget.customerName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Customer: ${widget.customerName}',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
            ),
          ],
          if (widget.customerPhone != null) ...[
            const SizedBox(height: 8),
            Text(
              'Phone: ${widget.customerPhone}',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
            ),
          ],
          if (widget.specialInstructions != null) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: context.modeBorder),
            const SizedBox(height: 12),
            Text(
              'Special Instructions:',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.specialInstructions!,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
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
        color: context.modeSurface,
        border: Border.all(color: context.modeBorder),
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
                      color: context.modeSurfaceAlt,
                      child: Center(
                        child: AppIcon(
                          Icons.restaurant,
                          size: 24,
                          color: context.modeTextMuted,
                        ),
                      ),
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
                        color: context.modeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$quantity x ${formatPrice(double.parse(item.price))}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: context.modeTextSecondary,
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
                  color: context.modeTextPrimary,
                ),
              ),
            ],
          ),
          if (specialRequest != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.modePrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Center(
                    child: AppIcon(
                      Icons.edit_note,
                      size: 16,
                      color: context.modePrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      specialRequest!,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        color: context.modePrimary,
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
    // Build
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
                color: context.modeTextSecondary,
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
              color: context.modeTextPrimary,
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
              color: context.modeTextSecondary,
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
          Center(
            child: AppIcon(
              Icons.warning_amber_rounded,
              size: 16,
              color: context.modeError,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Tax unavailable: $message',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: context.modeError,
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
  final String label;
  final bool isLoading;

  const _BottomCta({
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.modeSurface,
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
            backgroundColor: context.modePrimary,
            disabledBackgroundColor: context.modePrimary.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.modeTextInverse,
                  ),
                )
              : Text(
                  label,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextInverse,
                  ),
                ),
        ),
      ),
    );
  }
}
