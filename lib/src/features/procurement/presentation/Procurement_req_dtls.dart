import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_order_model.dart';

class ProcurementDetailsScreen extends StatelessWidget {
  final ProcurementRequest order;

  const ProcurementDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: _buildAppBar(context),
        body: _buildBody(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Request Details',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _getHorizontalPadding(constraints.maxWidth);
        final maxContentWidth = _getMaxContentWidth(constraints.maxWidth);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSummaryCard(constraints.maxWidth),
                  const SizedBox(height: 16),
                  _buildOrderInfoCard(constraints.maxWidth),
                  const SizedBox(height: 16),
                  _buildItemsSection(constraints.maxWidth),
                  const SizedBox(height: 16),
                  if (order.notes != null) ...[
                    _buildNotesCard(constraints.maxWidth),
                    const SizedBox(height: 16),
                  ],
                  _buildTimelineCard(constraints.maxWidth),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderSummaryCard(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.requestId,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getTitleFontSize(screenWidth),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              _buildStatusBadge(order.status, screenWidth),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Requested By', order.requestedBy, screenWidth),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Branch',
            '${order.branch.name} (${order.branch.branchCode})',
            screenWidth,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Priority',
            order.priority,
            screenWidth,
            valueColor: order.priority == 'URGENT'
                ? Colors.red.shade700
                : const Color(0xFF757575),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getBodyFontSize(screenWidth),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF757575),
                ),
              ),
              Text(
                '₦${_formatAmount(order.totalAmountDouble)}',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getAmountFontSize(screenWidth),
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Information',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getSubtitleFontSize(screenWidth),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Expected Delivery',
            order.formattedExpectedDelivery,
            screenWidth,
          ),
          const SizedBox(height: 8),
          if (order.actualDelivery != null) ...[
            _buildInfoRow(
              'Actual Delivery',
              _formatDate(order.actualDelivery!),
              screenWidth,
            ),
            const SizedBox(height: 8),
          ],
          _buildInfoRow('Created Date', order.formattedCreatedAt, screenWidth),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Items Count',
            '${order.itemCount} item${order.itemCount != 1 ? 's' : ''}',
            screenWidth,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items (${order.items.length})',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getSubtitleFontSize(screenWidth),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...order.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (index > 0) const Divider(height: 24),
                _buildItemCard(item, screenWidth),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildItemCard(ProcurementItem item, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.item.itemName,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getBodyFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getItemStatusColor(item.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.status,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getSmallFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: _getItemStatusColor(item.status),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildItemDetail(
                'Qty Needed',
                '${item.qtyNeeded} ${item.item.unit}',
                screenWidth,
              ),
            ),
            Expanded(
              child: _buildItemDetail(
                'Unit Cost',
                '₦${_formatAmount(item.unitCostDouble)}',
                screenWidth,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildItemDetail(
                'Current Stock',
                '${item.currentStock} ${item.item.unit}',
                screenWidth,
              ),
            ),
            Expanded(
              child: _buildItemDetail(
                'Total Cost',
                '₦${_formatAmount(item.totalCostDouble)}',
                screenWidth,
                highlight: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemDetail(
    String label,
    String value,
    double screenWidth, {
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getSmallFontSize(screenWidth),
            fontWeight: FontWeight.w400,
            color: const Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getBodyFontSize(screenWidth),
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            color: highlight ? kPrimary : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.note_alt_outlined, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getBodyFontSize(screenWidth),
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.notes!,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getBodyFontSize(screenWidth),
                    fontWeight: FontWeight.w400,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getSubtitleFontSize(screenWidth),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            'Created',
            order.formattedCreatedAt,
            Icons.create,
            Colors.blue,
            screenWidth,
          ),
          if (order.approvedBy != null) ...[
            const SizedBox(height: 12),
            _buildTimelineItem(
              'Approved by ${order.approvedBy}',
              _formatDate(order.approvedAt!),
              Icons.check_circle,
              Colors.green,
              screenWidth,
            ),
          ],
          if (order.rejectedBy != null) ...[
            const SizedBox(height: 12),
            _buildTimelineItem(
              'Rejected by ${order.rejectedBy}',
              _formatDate(order.rejectedAt!),
              Icons.cancel,
              Colors.red,
              screenWidth,
            ),
            if (order.rejectionNote != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  'Reason: ${order.rejectionNote}',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getSmallFontSize(screenWidth),
                    fontWeight: FontWeight.w400,
                    color: Colors.red.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String date,
    IconData icon,
    Color color,
    double screenWidth,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getBodyFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getSmallFontSize(screenWidth),
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    double screenWidth, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getBodyFontSize(screenWidth),
            fontWeight: FontWeight.w400,
            color: const Color(0xFF757575),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getBodyFontSize(screenWidth),
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, double screenWidth) {
    Color bgColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'PENDING':
        bgColor = const Color(0xFFF7EADD);
        textColor = kPrimary;
        break;
      case 'APPROVED':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF4CAF50);
        break;
      case 'REJECTED':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFE53935);
        break;
      case 'COMPLETED':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF757575);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getStatusPaddingHorizontal(screenWidth),
        vertical: _getStatusPaddingVertical(screenWidth),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getBodyFontSize(screenWidth),
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Color _getItemStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return kPrimary;
      case 'APPROVED':
        return const Color(0xFF4CAF50);
      case 'REJECTED':
        return const Color(0xFFE53935);
      case 'COMPLETED':
        return const Color(0xFF1976D2);
      default:
        return const Color(0xFF757575);
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return (amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1);
    }
    return amount.toStringAsFixed(2);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

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

  double _getCardPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getTitleFontSize(double width) {
    if (width < 360) return 18;
    if (width < 600) return 20;
    return 22;
  }

  double _getSubtitleFontSize(double width) {
    if (width < 360) return 16;
    if (width < 600) return 17;
    return 18;
  }

  double _getBodyFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getSmallFontSize(double width) {
    if (width < 360) return 11;
    if (width < 600) return 12;
    return 13;
  }

  double _getAmountFontSize(double width) {
    if (width < 360) return 20;
    if (width < 600) return 22;
    return 24;
  }

  double _getStatusPaddingHorizontal(double width) {
    if (width < 360) return 10;
    if (width < 600) return 12;
    return 14;
  }

  double _getStatusPaddingVertical(double width) {
    if (width < 360) return 4;
    if (width < 600) return 5;
    return 6;
  }
}
