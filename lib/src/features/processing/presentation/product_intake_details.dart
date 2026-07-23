// presentation/product_intake_details_screen.dart

import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/data/model/product_intake_model.dart';

class ProductIntakeDetailsScreen extends StatelessWidget {
  final ProductIntake intake;

  const ProductIntakeDetailsScreen({super.key, required this.intake});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
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
            'Intake Details',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card with Product Name and Quality Status
                _buildHeaderCard(context),
                const SizedBox(height: 16),

                // Product Information
                _buildSectionCard(
                  context,
                  title: 'Product Information',
                  children: [
                    _buildInfoRow(
                      context,
                      'Product Name',
                      intake.productName,
                      Icons.inventory_2,
                    ),
                    _buildDivider(context),
                    _buildInfoRow(
                      context,
                      'Product Type',
                      intake.productType.displayName,
                      Icons.category,
                    ),
                    _buildDivider(context),
                    _buildInfoRow(
                      context,
                      'Quantity Received',
                      '${intake.qtyReceived} ${intake.unit.displayName}',
                      Icons.scale,
                      valueColor: kPrimary,
                      isBold: true,
                    ),
                    if (intake.item != null) ...[
                      _buildDivider(context),
                      _buildInfoRow(
                        context,
                        'Category',
                        intake.item!.category,
                        Icons.label,
                      ),
                      _buildDivider(context),
                      _buildInfoRow(
                        context,
                        'SKU',
                        intake.item!.sku,
                        Icons.qr_code_2,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Batch Information
                _buildSectionCard(
                  context,
                  title: 'Batch Information',
                  children: [
                    _buildInfoRow(
                      context,
                      'Stock Batch ID',
                      intake.stockBatchId,
                      Icons.qr_code,
                    ),
                    _buildDivider(context),
                    _buildInfoRow(
                      context,
                      'Issued By',
                      intake.issuedBy,
                      Icons.person_outline,
                    ),
                    _buildDivider(context),
                    _buildInfoRow(
                      context,
                      'Intake Date',
                      DateFormat(
                        'MMMM dd, yyyy • hh:mm a',
                      ).format(intake.intakeDate),
                      Icons.calendar_today,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quality Status
                _buildSectionCard(
                  context,
                  title: 'Quality Status',
                  children: [_buildQualityStatusRow(context)],
                ),
                const SizedBox(height: 16),

                // Branch Information
                if (intake.branch != null) ...[
                  _buildSectionCard(
                    context,
                    title: 'Branch Information',
                    children: [
                      _buildInfoRow(
                        context,
                        'Branch Name',
                        intake.branch!.name,
                        Icons.store,
                      ),
                      _buildDivider(context),
                      _buildInfoRow(
                        context,
                        'Branch Code',
                        intake.branch!.branchCode,
                        Icons.tag,
                      ),
                      _buildDivider(context),
                      _buildInfoRow(
                        context,
                        'Location',
                        '${intake.branch!.city}, ${intake.branch!.state}',
                        Icons.location_on,
                      ),
                      _buildDivider(context),
                      _buildInfoRow(
                        context,
                        'Address',
                        intake.branch!.address,
                        Icons.place,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes
                if (intake.notes != null && intake.notes!.isNotEmpty) ...[
                  _buildSectionCard(
                    context,
                    title: 'Notes',
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.modeSurfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          intake.notes!,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            color: context.modeTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Timestamps
                _buildSectionCard(
                  context,
                  title: 'System Information',
                  children: [
                    _buildInfoRow(
                      context,
                      'Created At',
                      DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(intake.createdAt),
                      Icons.add_circle_outline,
                    ),
                    _buildDivider(context),
                    _buildInfoRow(
                      context,
                      'Last Updated',
                      DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(intake.updatedAt),
                      Icons.update,
                    ),
                    _buildDivider(context),
                    _buildInfoRow(
                      context,
                      'Intake ID',
                      intake.id,
                      Icons.fingerprint,
                      isMonospace: true,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.modeBorder),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kPrimary.withValues(alpha: 0.1),
              kPrimary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AppIcon(Icons.inventory_2, color: kPrimary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        intake.productName,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.modeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildProductTypeBadge(context, intake.productType),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    context,
                    'Quantity',
                    '${intake.qtyReceived} ${intake.unit.displayName}',
                    Icons.scale,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStat(
                    context,
                    'Quality',
                    intake.qualityStatus ? 'Passed' : 'Failed',
                    intake.qualityStatus ? Icons.check_circle : Icons.cancel,
                    color: intake.qualityStatus
                        ? context.modeSuccess
                        : context.modeError,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.modeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon, size: 16, color: color ?? context.modeTextMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 12,
                  color: context.modeTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color ?? context.modeTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.modeBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool isBold = false,
    bool isMonospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, size: 20, color: context.modeTextMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: context.modeTextMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 15,
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                    color: valueColor ?? context.modeTextPrimary,
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityStatusRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: intake.qualityStatus
            ? context.modeSuccess.withValues(alpha: 0.1)
            : context.modeError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: intake.qualityStatus
              ? context.modeSuccess.withValues(alpha: 0.35)
              : context.modeError.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: intake.qualityStatus
                  ? context.modeSuccess.withValues(alpha: 0.16)
                  : context.modeError.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: AppIcon(
              intake.qualityStatus ? Icons.check_circle : Icons.cancel,
              color: intake.qualityStatus
                  ? context.modeSuccess
                  : context.modeError,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quality Check',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: context.modeTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  intake.qualityStatus ? 'Quality Passed' : 'Quality Failed',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: intake.qualityStatus
                        ? context.modeSuccess
                        : context.modeError,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  intake.qualityStatus
                      ? 'Product meets quality standards'
                      : 'Product failed quality inspection',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
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

  Widget _buildProductTypeBadge(BuildContext context, ProductType productType) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (productType) {
      case ProductType.rawMaterial:
        bgColor = context.modeWarning.withValues(alpha: 0.1);
        textColor = context.modeWarning;
        icon = Icons.grass;
        break;
      case ProductType.semiProcessed:
        bgColor = context.modeInfo.withValues(alpha: 0.1);
        textColor = context.modeInfo;
        icon = Icons.settings;
        break;
      case ProductType.finishedProduct:
        bgColor = context.modePrimaryAlt.withValues(alpha: 0.1);
        textColor = context.modePrimaryAlt;
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            productType.displayName,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, color: context.modeDivider),
    );
  }
}
