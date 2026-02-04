// presentation/product_intake_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
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
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Intake Details',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
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
                _buildHeaderCard(),
                const SizedBox(height: 16),

                // Product Information
                _buildSectionCard(
                  title: 'Product Information',
                  children: [
                    _buildInfoRow(
                      'Product Name',
                      intake.productName,
                      Icons.inventory_2,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      'Product Type',
                      intake.productType.displayName,
                      Icons.category,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      'Quantity Received',
                      '${intake.qtyReceived} ${intake.unit.displayName}',
                      Icons.scale,
                      valueColor: kPrimary,
                      isBold: true,
                    ),
                    if (intake.item != null) ...[
                      _buildDivider(),
                      _buildInfoRow(
                        'Category',
                        intake.item!.category,
                        Icons.label,
                      ),
                      _buildDivider(),
                      _buildInfoRow('SKU', intake.item!.sku, Icons.qr_code_2),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Batch Information
                _buildSectionCard(
                  title: 'Batch Information',
                  children: [
                    _buildInfoRow(
                      'Stock Batch ID',
                      intake.stockBatchId,
                      Icons.qr_code,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      'Issued By',
                      intake.issuedBy,
                      Icons.person_outline,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
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
                  title: 'Quality Status',
                  children: [_buildQualityStatusRow()],
                ),
                const SizedBox(height: 16),

                // Branch Information
                if (intake.branch != null) ...[
                  _buildSectionCard(
                    title: 'Branch Information',
                    children: [
                      _buildInfoRow(
                        'Branch Name',
                        intake.branch!.name,
                        Icons.store,
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        'Branch Code',
                        intake.branch!.branchCode,
                        Icons.tag,
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        'Location',
                        '${intake.branch!.city}, ${intake.branch!.state}',
                        Icons.location_on,
                      ),
                      _buildDivider(),
                      _buildInfoRow(
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
                    title: 'Notes',
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          intake.notes!,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Timestamps
                _buildSectionCard(
                  title: 'System Information',
                  children: [
                    _buildInfoRow(
                      'Created At',
                      DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(intake.createdAt),
                      Icons.add_circle_outline,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      'Last Updated',
                      DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(intake.updatedAt),
                      Icons.update,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
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

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary.withOpacity(0.1), kPrimary.withOpacity(0.05)],
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
                    color: kPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.inventory_2, color: kPrimary, size: 28),
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
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildProductTypeBadge(intake.productType),
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
                    'Quantity',
                    '${intake.qtyReceived} ${intake.unit.displayName}',
                    Icons.scale,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStat(
                    'Quality',
                    intake.qualityStatus ? 'Passed' : 'Failed',
                    intake.qualityStatus ? Icons.check_circle : Icons.cancel,
                    color: intake.qualityStatus
                        ? Colors.green.shade600
                        : Colors.red.shade600,
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
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                label,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 12,
                  color: Colors.grey.shade600,
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
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
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
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 15,
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                    color: valueColor ?? Colors.black,
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

  Widget _buildQualityStatusRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: intake.qualityStatus ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: intake.qualityStatus
              ? Colors.green.shade200
              : Colors.red.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: intake.qualityStatus
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              intake.qualityStatus ? Icons.check_circle : Icons.cancel,
              color: intake.qualityStatus
                  ? Colors.green.shade700
                  : Colors.red.shade700,
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
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  intake.qualityStatus
                      ? 'Quality Passed ✓'
                      : 'Quality Failed ✗',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: intake.qualityStatus
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  intake.qualityStatus
                      ? 'Product meets quality standards'
                      : 'Product failed quality inspection',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTypeBadge(ProductType productType) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (productType) {
      case ProductType.rawMaterial:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.grass;
        break;
      case ProductType.semiProcessed:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.settings;
        break;
      case ProductType.finishedProduct:
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
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
          Icon(icon, size: 16, color: textColor),
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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }
}
