import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/data/model/oder_status_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final KitchenOrder order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kprimaryTextColor1),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Order Details',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
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
                  _buildCustomerInfo(textSize),
                  SizedBox(height: verticalSpacing),
                  _buildOrderItems(textSize),
                  SizedBox(height: verticalSpacing),
                  _buildPricingBreakdown(textSize),
                  SizedBox(height: verticalSpacing),
                  _buildTimeline(textSize),
                  if (order.specialInstructions != null) ...[
                    SizedBox(height: verticalSpacing),
                    _buildSpecialInstructions(textSize),
                  ],
                  if (order.cancellationReason != null) ...[
                    SizedBox(height: verticalSpacing),
                    _buildCancellationReason(textSize),
                  ],
                  SizedBox(height: verticalSpacing),
                  _buildBranchInfo(textSize),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                              color: kprimaryTextColor1,
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
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                backgroundColor: kGreen,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          child: Icon(Icons.copy, size: 20, color: kPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatOrderType(order.orderType),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: textSize - 1,
                        fontWeight: FontWeight.w500,
                        color: kprimaryTextColor1.withOpacity(0.6),
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
                  color: _getStatusColor(order.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.displayName,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: textSize,
                    fontWeight: FontWeight.w600,
                    color: _getStatusTextColor(order.status),
                  ),
                ),
              ),
            ],
          ),
          if (order.tableNumber != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.table_restaurant,
                  size: 18,
                  color: kprimaryTextColor1.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  order.tableNumber!,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: textSize,
                    fontWeight: FontWeight.w600,
                    color: kprimaryTextColor1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(double textSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.person_outline,
            'Name',
            order.customerName ?? '',
            textSize,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.phone_outlined,
            'Phone',
            order.customerPhone ?? '',
            textSize,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(double textSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 16),
          ...order.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (index > 0) const SizedBox(height: 16),
                _buildOrderItem(item, textSize),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item, double textSize) {
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
                  color: kprimaryTextColor1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.menuItem.category,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize - 2,
                  color: kprimaryTextColor1.withOpacity(0.6),
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
                    color: const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Note: ${item.specialRequest}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: textSize - 2,
                      color: const Color(0xFFFF9800),
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
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₦${item.totalPrice}',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: textSize,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingBreakdown(double textSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Subtotal', order.subtotal, textSize, false),
          const SizedBox(height: 12),
          _buildPriceRow('Tax', order.tax, textSize, false),
          if (double.parse(order.discount) > 0) ...[
            const SizedBox(height: 12),
            _buildPriceRow('Discount', '-${order.discount}', textSize, false),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _buildPriceRow('Total Amount', order.totalAmount, textSize, true),
          if (order.amountPaid != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: textSize,
                    color: kprimaryTextColor1.withOpacity(0.7),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.paymentMethod ?? 'Cash',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: textSize - 1,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D32),
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

  Widget _buildTimeline(double textSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem('Order Placed', order.orderedAt, textSize, true),
          if (order.confirmedAt != null)
            _buildTimelineItem(
              'Order Confirmed',
              order.confirmedAt!,
              textSize,
              true,
            ),
          if (order.startedAt != null)
            _buildTimelineItem(
              'Preparation Started',
              order.startedAt!,
              textSize,
              true,
            ),
          if (order.readyAt != null)
            _buildTimelineItem('Order Ready', order.readyAt!, textSize, true),
          if (order.servedAt != null)
            _buildTimelineItem('Order Served', order.servedAt!, textSize, true),
          if (order.completedAt != null)
            _buildTimelineItem(
              'Order Completed',
              order.completedAt!,
              textSize,
              true,
            ),
          if (order.cancelledAt != null)
            _buildTimelineItem(
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
              color: isSuccess ? kGreen : Colors.red,
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
                    color: kprimaryTextColor1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(time), // already handles String and DateTime
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: textSize - 2,
                    color: kprimaryTextColor1.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions(double textSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFFFF9800),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Special Instructions',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.specialInstructions!,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize - 1,
              color: kprimaryTextColor1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationReason(double textSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF5350), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cancel_outlined,
                color: Color(0xFFEF5350),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cancellation Reason',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF5350),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.cancellationReason!,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: textSize - 1,
              color: kprimaryTextColor1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchInfo(double textSize) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.store_outlined,
            'Branch',
            order.branch.name,
            textSize,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
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
    IconData icon,
    String label,
    String value,
    double textSize,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: kprimaryTextColor1.withOpacity(0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize - 2,
                  color: kprimaryTextColor1.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  color: kprimaryTextColor1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
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
            color: kprimaryTextColor1,
          ),
        ),
        Text(
          displayAmount,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: textSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isBold ? kPrimary : kprimaryTextColor1,
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('MMM dd, yyyy at HH:mm').format(dateTime);
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFFFE770);
      case OrderStatus.confirmed:
        return const Color(0xFF87CEEB);
      case OrderStatus.inQueue:
        return const Color(0xFFFFB347);
      case OrderStatus.preparing:
        return const Color(0xFFFFE770);
      case OrderStatus.ready:
        return const Color(0xFF30A46C);
      case OrderStatus.served:
        return const Color(0xFF9E9E9E);
      case OrderStatus.completed:
        return const Color(0xFF4A5568);
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  Color _getStatusTextColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
      case OrderStatus.inQueue:
      case OrderStatus.preparing:
        return kprimaryTextColor1;
      default:
        return Colors.white;
    }
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
}
