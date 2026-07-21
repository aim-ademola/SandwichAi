import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/data/model/oder_status_model.dart';
import 'package:sandwich_ai/src/features/pos/presentation/payment_method.dart';

class OrderDetailScreen extends StatelessWidget {
  final KitchenOrder order;
  final VoidCallback? onBack;
  final Future<void> Function()? onConfirmPending;

  const OrderDetailScreen({
    super.key,
    required this.order,
    this.onBack,
    this.onConfirmPending,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
        appBar: AppBar(
          backgroundColor: context.modeSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
            onPressed: onBack ?? () => Navigator.pop(context),
          ),
          title: Text(
            'Order Details',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = _getHorizontalPadding(
              constraints.maxWidth,
            );
            final verticalSpacing = _getVerticalSpacing(constraints.maxWidth);
            final textSize = _getBodyTextSize(constraints.maxWidth);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalSpacing,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderHeader(textSize, context),
                  SizedBox(height: verticalSpacing),
                  _buildCustomerInfo(context, textSize),
                  SizedBox(height: verticalSpacing),
                  _buildOrderItems(context, textSize),
                  SizedBox(height: verticalSpacing),
                  _buildPricingBreakdown(context, textSize),
                  if (_shouldShowPaymentAction()) ...[
                    SizedBox(height: verticalSpacing),
                    _buildPaymentAction(context, textSize),
                  ],
                  if (_shouldShowConfirmAction()) ...[
                    SizedBox(height: verticalSpacing),
                    _buildConfirmAction(context, textSize),
                  ],
                  SizedBox(height: verticalSpacing),
                  _buildTimeline(context, textSize),
                  if (order.specialInstructions != null) ...[
                    SizedBox(height: verticalSpacing),
                    _buildSpecialInstructions(context, textSize),
                  ],
                  if ((order.cancellationReason ?? '').trim().isNotEmpty) ...[
                    SizedBox(height: verticalSpacing),
                    _buildCancellationReason(context, textSize),
                  ],
                  SizedBox(height: verticalSpacing),
                  _buildBranchInfo(context, textSize),
                  SizedBox(height: verticalSpacing * 2),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderHeader(double textSize, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            order.orderId,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: textSize + 4,
                              fontWeight: FontWeight.w700,
                              color: context.modeTextPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: order.orderId),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Order ID copied: ${order.orderId}',
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    color: context.modeTextInverse,
                                    fontSize: 14,
                                  ),
                                ),
                                backgroundColor: context.modeSuccess,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          child: AppIcon(
                            Icons.copy,
                            size: 20,
                            color: context.modePrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatOrderType(order.orderType),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: textSize - 1,
                        fontWeight: FontWeight.w500,
                        color: context.modeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(context, order.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.displayName,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: textSize,
                    fontWeight: FontWeight.w600,
                    color: _getStatusTextColor(context, order.status),
                  ),
                ),
              ),
            ],
          ),
          if (order.tableNumber != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                AppIcon(
                  Icons.table_restaurant,
                  size: 18,
                  color: context.modeTextSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  order.tableNumber!,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: textSize,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context, double textSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Information',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize + 1,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            Icons.person_outline,
            'Name',
            order.customerName ?? '',
            textSize,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            Icons.phone_outlined,
            'Phone',
            order.customerPhone ?? '',
            textSize,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context, double textSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize + 1,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...order.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (index > 0) const SizedBox(height: 16),
                _buildOrderItem(context, item, textSize),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
    BuildContext context,
    OrderItem item,
    double textSize,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(item.menuItem.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.menuItem.dishName,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.menuItem.category,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize - 2,
                  color: context.modeTextSecondary,
                ),
              ),
              if (item.specialRequest != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.modeWarning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Note: ${item.specialRequest}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: textSize - 2,
                      color: context.modeWarning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '×${item.quantity}',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: textSize,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₦${item.totalPrice}',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: textSize,
                fontWeight: FontWeight.w700,
                color: context.modePrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingBreakdown(BuildContext context, double textSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing Summary',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize + 1,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow(context, 'Subtotal', order.subtotal, textSize, false),
          const SizedBox(height: 12),
          _buildPriceRow(context, 'Tax', order.tax, textSize, false),
          if (double.parse(order.discount) > 0) ...[
            const SizedBox(height: 12),
            _buildPriceRow(
              context,
              'Discount',
              '-${order.discount}',
              textSize,
              false,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _buildPriceRow(
            context,
            'Total Amount',
            order.totalAmount,
            textSize,
            true,
          ),
          if (order.amountPaid != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: textSize,
                    color: context.modeTextSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.modeSuccess.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.paymentMethod ?? 'Cash',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: textSize - 1,
                      fontWeight: FontWeight.w600,
                      color: context.modeSuccess,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentAction(BuildContext context, double textSize) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Pending',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize + 1,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This order has been served. Take payment to complete it.',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize - 1,
              fontWeight: FontWeight.w500,
              color: context.modeTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openPayment(context),
              icon: const AppIcon(Icons.payments_outlined),
              label: Text(
                'Take Payment',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                foregroundColor: context.modeTextInverse,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmAction(BuildContext context, double textSize) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Awaiting Confirmation',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize + 1,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Confirm this order when customer service has cleared it for kitchen.',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize - 1,
              fontWeight: FontWeight.w500,
              color: context.modeTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onConfirmPending,
              icon: const AppIcon(Icons.check_circle_outline),
              label: Text(
                'Confirm Order',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                foregroundColor: context.modeTextInverse,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPayment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentMethodScreen(
          orderItems: const {},
          specialRequests: const {},
          orderType: order.orderType.value,
          tableNumber: order.tableNumber,
          customerName: order.customerName,
          customerPhone: order.customerPhone,
          totalAmount: double.tryParse(order.totalAmount) ?? 0,
          existingOrderId: order.id,
          existingOrderNumber: order.orderId,
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, double textSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Timeline',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize + 1,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            context,
            'Order Placed',
            order.orderedAt,
            textSize,
            true,
          ),
          if (order.confirmedAt != null)
            _buildTimelineItem(
              context,
              'Order Confirmed',
              order.confirmedAt!,
              textSize,
              true,
            ),
          if (order.startedAt != null)
            _buildTimelineItem(
              context,
              'Preparation Started',
              order.startedAt!,
              textSize,
              true,
            ),
          if (order.readyAt != null)
            _buildTimelineItem(
              context,
              'Order Ready',
              order.readyAt!,
              textSize,
              true,
            ),
          if (order.servedAt != null)
            _buildTimelineItem(
              context,
              'Order Served',
              order.servedAt!,
              textSize,
              true,
            ),
          if (order.completedAt != null)
            _buildTimelineItem(
              context,
              'Order Completed',
              order.completedAt!,
              textSize,
              true,
            ),
          if (order.cancelledAt != null)
            _buildTimelineItem(
              context,
              'Order Cancelled',
              order.cancelledAt!,
              textSize,
              false,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    dynamic time,
    double textSize,
    bool isSuccess,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isSuccess ? context.modeSuccess : context.modeError,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: textSize,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(time), // already handles String and DateTime
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: textSize - 2,
                    color: context.modeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions(BuildContext context, double textSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.modeWarning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.modeWarning.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(Icons.info_outline, color: context.modeWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Special Instructions',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  color: context.modeWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.specialInstructions!,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize - 1,
              color: context.modeTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationReason(BuildContext context, double textSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.modeError.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.modeError.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                Icons.cancel_outlined,
                color: context.modeError,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cancellation reason',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  color: context.modeError,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.cancellationReason!.trim(),
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize - 1,
              color: context.modeTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchInfo(BuildContext context, double textSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Branch Information',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize + 1,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            Icons.store_outlined,
            'Branch',
            order.branch.name,
            textSize,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            Icons.location_on_outlined,
            'Address',
            '${order.branch.address}, ${order.branch.city}',
            textSize,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    double textSize,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(icon, size: 20, color: context.modeTextSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize - 2,
                  color: context.modeTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    String amount,
    double textSize,
    bool isBold,
  ) {
    final parsedAmount = double.tryParse(amount.replaceAll('-', '')) ?? 0;
    final formattedAmount = NumberFormat('#,##0.##').format(parsedAmount);
    final displayAmount = amount.startsWith('-')
        ? '-₦$formattedAmount'
        : '₦$formattedAmount';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: textSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: context.modeTextPrimary,
          ),
        ),
        Text(
          displayAmount,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: textSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isBold ? context.modePrimary : context.modeTextPrimary,
          ),
        ),
      ],
    );
  }

  String _formatOrderType(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Dine In';

      case OrderType.takeaway:
        return 'Takeaway';
      case OrderType.online:
        return 'Online';
      case OrderType.delivery:
        return 'Delivery';
    }
  }

  String _formatDate(dynamic dt) {
    try {
      DateTime dateTime;

      if (dt is DateTime) {
        dateTime = dt;
      } else if (dt is String) {
        dateTime = DateTime.parse(dt);
      } else {
        return dt.toString();
      }

      final wat = dateTime.toUtc().add(const Duration(hours: 1));
      return DateFormat('MMM dd, yyyy • hh:mm a').format(wat);
    } catch (_) {
      return dt.toString();
    }
  }

  Color _getStatusColor(BuildContext context, OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return context.modeWarning.withValues(alpha: 0.24);
      case OrderStatus.confirmed:
        return context.modeInfo.withValues(alpha: 0.22);
      case OrderStatus.inQueue:
        return context.modeWarning.withValues(alpha: 0.22);
      case OrderStatus.preparing:
        return context.modePrimary.withValues(alpha: 0.18);
      case OrderStatus.ready:
        return context.modeSuccess;
      case OrderStatus.served:
        return context.modeSuccess;
      case OrderStatus.completed:
        return context.modeTextSecondary;
      case OrderStatus.cancelled:
        return context.modeError;
    }
  }

  Color _getStatusTextColor(BuildContext context, OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
      case OrderStatus.inQueue:
      case OrderStatus.preparing:
        return context.modeTextPrimary;
      case OrderStatus.served:
        return _textOnStatusColor(context, _getStatusColor(context, status));
      default:
        return context.modeTextInverse;
    }
  }

  Color _textOnStatusColor(BuildContext context, Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark
        ? context.modeTextInverse
        : context.modeTextPrimary;
  }

  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 24;
    return 32;
  }

  double _getVerticalSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    if (width < 900) return 16;
    return 18;
  }

  double _getBodyTextSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    if (width < 900) return 16;
    return 17;
  }

  bool _hasPayment() {
    final amountPaid = double.tryParse(order.amountPaid ?? '') ?? 0;
    final method = order.paymentMethod?.trim();
    return amountPaid > 0 || (method != null && method.isNotEmpty);
  }

  bool _shouldShowPaymentAction() {
    return order.status == OrderStatus.served && !_hasPayment();
  }

  bool _shouldShowConfirmAction() {
    return order.status == OrderStatus.pending && onConfirmPending != null;
  }
}
