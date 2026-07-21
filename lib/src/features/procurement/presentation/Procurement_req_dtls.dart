import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
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
        backgroundColor: context.modeBackground,
        appBar: _buildAppBar(context),
        body: _buildBody(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.modeSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Request Details',
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
                  _buildOrderSummaryCard(context, constraints.maxWidth),
                  const SizedBox(height: 16),
                  _buildOrderInfoCard(context, constraints.maxWidth),
                  const SizedBox(height: 16),
                  _buildItemsSection(context, constraints.maxWidth),
                  const SizedBox(height: 16),
                  if (order.notes != null) ...[
                    _buildNotesCard(context, constraints.maxWidth),
                    const SizedBox(height: 16),
                  ],
                  _buildTimelineCard(context, constraints.maxWidth),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder, width: 1),
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
                  color: context.modeTextPrimary,
                ),
              ),
              _buildStatusBadge(context, order.status, screenWidth),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            'Requested By',
            _nonEmpty(
              order.requestingDepartment,
              fallback: 'Unknown department',
            ),
            screenWidth,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'Branch', _branchLabel, screenWidth),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            'Priority',
            order.priority,
            screenWidth,
            valueColor: order.priority == 'URGENT'
                ? context.modeError
                : context.modeTextSecondary,
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
                  color: context.modeTextSecondary,
                ),
              ),
              Text(
                '₦${_formatAmount(order.totalAmountDouble)}',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getAmountFontSize(screenWidth),
                  fontWeight: FontWeight.bold,
                  color: context.modePrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(BuildContext context, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Information',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getSubtitleFontSize(screenWidth),
              fontWeight: FontWeight.bold,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'Expected Delivery',
            order.formattedExpectedDelivery,
            screenWidth,
          ),
          const SizedBox(height: 8),
          if (order.actualDelivery != null) ...[
            _buildInfoRow(
              context,
              'Actual Delivery',
              _formatDate(order.actualDelivery!),
              screenWidth,
            ),
            const SizedBox(height: 8),
          ],
          _buildInfoRow(
            context,
            'Created Date',
            order.formattedCreatedAt,
            screenWidth,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            'Items Count',
            '${order.itemCount} item${order.itemCount != 1 ? 's' : ''}',
            screenWidth,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items (${order.items.length})',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getSubtitleFontSize(screenWidth),
              fontWeight: FontWeight.bold,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...order.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (index > 0) Divider(height: 24, color: context.modeDivider),
                _buildItemCard(context, item, screenWidth),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    ProcurementItem item,
    double screenWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.item.itemName.isEmpty
                    ? 'Unknown Item'
                    : item.item.itemName,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getBodyFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getItemStatusColor(
                  context,
                  item.status,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.status,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getSmallFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: _getItemStatusColor(context, item.status),
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
                context,
                'Qty Needed',
                _quantityLabel(item.qtyNeeded, item.item.unit),
                screenWidth,
              ),
            ),
            Expanded(
              child: _buildItemDetail(
                context,
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
                context,
                'Current Stock',
                _quantityLabel(item.currentStock, item.item.unit),
                screenWidth,
              ),
            ),
            Expanded(
              child: _buildItemDetail(
                context,
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
    BuildContext context,
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
            color: context.modeTextSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getBodyFontSize(screenWidth),
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            color: highlight ? context.modePrimary : context.modeTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(BuildContext context, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeWarning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.modeWarning.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            Icons.note_alt_outlined,
            color: context.modeWarning,
            size: 20,
          ),
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
                    color: context.modeTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _nonEmpty(order.notes, fallback: 'No notes provided'),
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getBodyFontSize(screenWidth),
                    fontWeight: FontWeight.w400,
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

  Widget _buildTimelineCard(BuildContext context, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getSubtitleFontSize(screenWidth),
              fontWeight: FontWeight.bold,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            context,
            'Created',
            order.formattedCreatedAt,
            Icons.create,
            context.modeInfo,
            screenWidth,
          ),
          if (_hasText(order.approvedBy)) ...[
            const SizedBox(height: 12),
            _buildTimelineItem(
              context,
              'Approved by ${_nonEmpty(order.approvedBy, fallback: 'Unknown user')}',
              _formatDate(order.approvedAt),
              Icons.check_circle,
              context.modeSuccess,
              screenWidth,
            ),
          ],
          if (_hasText(order.rejectedBy)) ...[
            const SizedBox(height: 12),
            _buildTimelineItem(
              context,
              'Rejected by ${_nonEmpty(order.rejectedBy, fallback: 'Unknown user')}',
              _formatDate(order.rejectedAt),
              Icons.cancel,
              context.modeError,
              screenWidth,
            ),
            if (_hasText(order.rejectionNote)) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  'Reason: ${order.rejectionNote}',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getSmallFontSize(screenWidth),
                    fontWeight: FontWeight.w400,
                    color: context.modeError,
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
    BuildContext context,
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
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppIcon(icon, color: color, size: 20),
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
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getSmallFontSize(screenWidth),
                  fontWeight: FontWeight.w400,
                  color: context.modeTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
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
            color: context.modeTextSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getBodyFontSize(screenWidth),
              fontWeight: FontWeight.w600,
              color: valueColor ?? context.modeTextPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    String status,
    double screenWidth,
  ) {
    Color bgColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'PENDING':
        bgColor = context.modePrimary.withValues(alpha: 0.12);
        textColor = context.modePrimary;
        break;
      case 'APPROVED':
        bgColor = context.modeSuccess.withValues(alpha: 0.12);
        textColor = context.modeSuccess;
        break;
      case 'REJECTED':
        bgColor = context.modeError.withValues(alpha: 0.12);
        textColor = context.modeError;
        break;
      case 'COMPLETED':
        bgColor = context.modeInfo.withValues(alpha: 0.12);
        textColor = context.modeInfo;
        break;
      default:
        bgColor = context.modeSurfaceMuted;
        textColor = context.modeTextSecondary;
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

  Color _getItemStatusColor(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return context.modePrimary;
      case 'APPROVED':
        return context.modeSuccess;
      case 'REJECTED':
        return context.modeError;
      case 'COMPLETED':
        return context.modeInfo;
      default:
        return context.modeTextSecondary;
    }
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  String get _branchLabel {
    final name = order.branch.name.isEmpty
        ? 'Unknown branch'
        : order.branch.name;
    if (order.branch.branchCode.isEmpty) return name;
    return '$name (${order.branch.branchCode})';
  }

  String _quantityLabel(String quantity, String unit) {
    if (unit.trim().isEmpty) return quantity;
    return '$quantity $unit';
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  String _nonEmpty(String? value, {required String fallback}) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return 'Not set';
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
