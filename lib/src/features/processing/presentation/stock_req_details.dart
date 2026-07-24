import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/processing/data/model/stock_reuest_model.dart';

class StockRequestDetailsScreen extends StatelessWidget {
  final StockRequest request;

  const StockRequestDetailsScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final horizontalPadding = _getHorizontalPadding(screenWidth);
        final maxContentWidth = _getMaxContentWidth(screenWidth);

        return Scaffold(
          backgroundColor: context.modeBackground,
          appBar: _buildAppBar(context, screenWidth),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: _getVerticalPadding(screenWidth),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(context, screenWidth),
                    SizedBox(height: _getSectionSpacing(screenWidth)),
                    _buildRequestInfoCard(context, screenWidth),
                    SizedBox(height: _getSectionSpacing(screenWidth)),
                    _buildItemsSection(context, screenWidth),
                    if (request.approvedBy != null) ...[
                      SizedBox(height: _getSectionSpacing(screenWidth)),
                      _buildApprovalInfoCard(context, screenWidth),
                    ],
                    SizedBox(height: _getVerticalPadding(screenWidth)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, double screenWidth) {
    return AppBar(
      backgroundColor: context.modeSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: AppIcon(
          Icons.arrow_back,
          color: context.modeTextPrimary,
          size: _getIconSize(screenWidth),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Request Details',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getAppBarTitleFontSize(screenWidth),
          fontWeight: FontWeight.w600,
          color: context.modeTextPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeaderCard(BuildContext context, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.modePrimary,
            context.modePrimary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        boxShadow: [
          BoxShadow(
            color: context.modePrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.modeTextInverse.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppIcon(
                  Icons.receipt_long,
                  color: context.modeTextInverse,
                  size: _getIconSize(screenWidth) + 4,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requestId,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getSectionTitleFontSize(screenWidth),
                        fontWeight: FontWeight.w700,
                        color: context.modeTextInverse,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock Request',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getCaptionFontSize(screenWidth),
                        color: context.modeTextInverse.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(
                context,
                request.status,
                screenWidth,
                isWhiteBg: true,
              ),
            ],
          ),
          SizedBox(height: _getFieldSpacing(screenWidth)),
          Divider(
            color: context.modeTextInverse.withValues(alpha: 0.3),
            height: 1,
          ),
          SizedBox(height: _getFieldSpacing(screenWidth)),
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  context: context,
                  icon: Icons.inventory_2_outlined,
                  label: 'Items',
                  value: '${request.totalItemsCount}',
                  screenWidth: screenWidth,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: context.modeTextInverse.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildHeaderStat(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Total Qty',
                  value: '${request.totalQuantityRequested}',
                  context: context,
                  screenWidth: screenWidth,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required double screenWidth,
  }) {
    return Column(
      children: [
        AppIcon(
          icon,
          color: context.modeTextInverse,
          size: _getIconSize(screenWidth),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getSectionTitleFontSize(screenWidth),
            fontWeight: FontWeight.w700,
            color: context.modeTextInverse,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getCaptionFontSize(screenWidth),
            color: context.modeTextInverse.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestInfoCard(BuildContext context, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Information',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getSectionTitleFontSize(screenWidth),
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          SizedBox(height: _getFieldSpacing(screenWidth)),
          _buildInfoRow(
            context: context,
            icon: Icons.business_outlined,
            label: 'Requesting Branch',
            value: request.requestingBranch?.name ?? 'Unknown',
            sublabel: request.requestingBranch?.branchCode,
            screenWidth: screenWidth,
          ),
          _buildDivider(context),
          _buildInfoRow(
            context: context,
            icon: Icons.person_outline,
            label: 'Requested By',
            value: request.requestedBy?.fullName ?? 'N/A',
            screenWidth: screenWidth,
          ),
          _buildDivider(context),
          _buildInfoRow(
            context: context,
            icon: Icons.category_outlined,
            label: 'Department',
            value: request.department,
            screenWidth: screenWidth,
          ),
          _buildDivider(context),
          _buildInfoRow(
            context: context,
            icon: Icons.calendar_today_outlined,
            label: 'Created Date',
            value: _formatDate(request.createdAt),
            screenWidth: screenWidth,
          ),
          if (request.notes.isNotEmpty) ...[
            _buildDivider(context),
            _buildInfoRow(
              context: context,
              icon: Icons.note_outlined,
              label: 'Notes',
              value: request.notes,
              screenWidth: screenWidth,
              isMultiline: true,
            ),
          ],
        ],
      ),
    );
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
      return DateFormat('MMM dd, yyyy - hh:mm a').format(wat);
    } catch (_) {
      return dt.toString();
    }
  }

  Widget _buildItemsSection(BuildContext context, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requested Items',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getSectionTitleFontSize(screenWidth),
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          SizedBox(height: _getFieldSpacing(screenWidth)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: request.items.length,
            separatorBuilder: (context, index) => Divider(
              height: _getFieldSpacing(screenWidth) * 2,
              color: context.modeDivider,
            ),
            itemBuilder: (context, index) {
              final item = request.items[index];
              return _buildItemCard(context, item, screenWidth);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    StockRequestItem item,
    double screenWidth,
  ) {
    return Row(
      children: [
        Container(
          width: _getIconSize(screenWidth) + 12,
          height: _getIconSize(screenWidth) + 12,
          decoration: BoxDecoration(
            color: context.modePrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: AppIcon(
            Icons.inventory_2_outlined,
            color: context.modePrimary,
            size: _getIconSize(screenWidth) - 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.item?.itemName ?? 'Unknown Item',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getInputFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildItemBadge(
                    label:
                        'Requested: ${item.qtyRequested} ${item.item?.unit ?? ''}',
                    color: context.modeInfo,
                    screenWidth: screenWidth,
                  ),
                  if (item.qtySent != null) ...[
                    const SizedBox(width: 8),
                    _buildItemBadge(
                      label: 'Sent: ${item.qtySent} ${item.item?.unit ?? ''}',
                      color: context.modeSuccess,
                      screenWidth: screenWidth,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        _buildStatusBadge(context, item.status, screenWidth),
      ],
    );
  }

  Widget _buildItemBadge({
    required String label,
    required Color color,
    required double screenWidth,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getCaptionFontSize(screenWidth),
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildApprovalInfoCard(BuildContext context, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(
          color: _getStatusColor(
            context,
            request.status,
          ).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    context,
                    request.status,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppIcon(
                  request.status == 'COMPLETED'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: _getStatusColor(context, request.status),
                  size: _getIconSize(screenWidth),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                request.status == 'COMPLETED'
                    ? 'Approval Information'
                    : 'Rejection Information',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getSectionTitleFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: _getFieldSpacing(screenWidth)),
          _buildInfoRow(
            context: context,
            icon: Icons.person_outline,
            label: request.status == 'COMPLETED'
                ? 'Approved By'
                : 'Rejected By',
            value: request.approvedBy?.fullName ?? 'N/A',
            screenWidth: screenWidth,
          ),
          if (request.approvedAt != null) ...[
            _buildDivider(context),
            _buildInfoRow(
              context: context,
              icon: Icons.calendar_today_outlined,
              label: request.status == 'COMPLETED'
                  ? 'Approved Date'
                  : 'Rejected Date',
              value: _formatDate(request.approvedAt!),
              screenWidth: screenWidth,
            ),
          ],
          if (request.completedBy != null) ...[
            _buildDivider(context),
            _buildInfoRow(
              context: context,
              icon: Icons.done_all_outlined,
              label: 'Completed By',
              value: request.completedBy?.fullName ?? 'N/A',
              screenWidth: screenWidth,
            ),
          ],
          if (request.completedAt != null) ...[
            _buildDivider(context),
            _buildInfoRow(
              context: context,
              icon: Icons.schedule_outlined,
              label: 'Completed Date',
              value: _formatDate(request.completedAt!),
              screenWidth: screenWidth,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    String? sublabel,
    required double screenWidth,
    bool isMultiline = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: _getFieldSpacing(screenWidth) / 2,
      ),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          AppIcon(
            icon,
            size: _getIconSize(screenWidth) - 2,
            color: context.modeTextSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getCaptionFontSize(screenWidth),
                    color: context.modeTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getInputFontSize(screenWidth),
                    fontWeight: FontWeight.w500,
                    color: context.modeTextPrimary,
                  ),
                ),
                if (sublabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getCaptionFontSize(screenWidth),
                      color: context.modeTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(height: _getFieldSpacing(600), color: context.modeDivider);
  }

  Widget _buildStatusBadge(
    BuildContext context,
    String status,
    double screenWidth, {
    bool isWhiteBg = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isWhiteBg
            ? context.modeTextInverse.withValues(alpha: 0.9)
            : _getStatusColor(context, status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusText(status),
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getCaptionFontSize(screenWidth),
          fontWeight: FontWeight.w600,
          color: _getStatusColor(context, status),
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return context.modeWarning;
      case 'APPROVED':
        return context.modeInfo;
      case 'COMPLETED':
        return context.modeSuccess;
      case 'REJECTED':
        return context.modeError;
      default:
        return context.modeTextSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'COMPLETED':
        return 'Completed';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }

  // Responsive sizing functions
  double _getHorizontalPadding(double width) => width < 360
      ? 16
      : width < 600
      ? 20
      : 32;
  double _getMaxContentWidth(double width) => width < 600
      ? double.infinity
      : width < 900
      ? 600
      : 700;
  double _getVerticalPadding(double width) => width < 360
      ? 16
      : width < 600
      ? 20
      : 24;
  double _getCardPadding(double width) => width < 360
      ? 16
      : width < 600
      ? 18
      : 20;
  double _getSectionSpacing(double width) => width < 360
      ? 16
      : width < 600
      ? 18
      : 20;
  double _getFieldSpacing(double width) => width < 360
      ? 12
      : width < 600
      ? 14
      : 16;
  double _getAppBarTitleFontSize(double width) => width < 360
      ? 17
      : width < 600
      ? 18
      : 19;
  double _getSectionTitleFontSize(double width) => width < 360
      ? 16
      : width < 600
      ? 17
      : 18;
  double _getInputFontSize(double width) => width < 360
      ? 14
      : width < 600
      ? 15
      : 16;
  double _getCaptionFontSize(double width) => width < 360
      ? 11
      : width < 600
      ? 12
      : 13;
  double _getIconSize(double width) => width < 360
      ? 20
      : width < 600
      ? 22
      : 24;
  double _getBorderRadius(double width) => width < 360
      ? 8
      : width < 600
      ? 10
      : 12;
}
