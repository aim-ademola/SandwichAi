import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter/services.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/data/model/processing_dash_model.dart';

class VerificationDetailsScreen extends StatelessWidget {
  final RecentVerification verification;

  const VerificationDetailsScreen({super.key, required this.verification});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: _buildAppBar(context),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 20),
              _buildBatchInfoCard(context),
              const SizedBox(height: 20),
              _buildProductionMetricsCard(),
              const SizedBox(height: 20),
              _buildQualityControlCard(),
              const SizedBox(height: 20),
              _buildTeamInfoCard(),
              const SizedBox(height: 20),
              _buildTimestampCard(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const AppIcon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Verification Details',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildStatusCard() {
    final statusColor = verification.status.toLowerCase() == 'verified'
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF9800);

    final qcStatusColor = _getQcStatusColor(verification.qcStatus);
    final qcStatusText = _getQcStatusText(verification.qcStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [statusColor, statusColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppIcon(Icons.verified, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verification.status.toUpperCase(),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      verification.productName,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: qcStatusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  qcStatusText,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchInfoCard(BuildContext context) {
    return _buildInfoCard(
      title: 'Batch Information',
      icon: Icons.inventory_2_outlined,
      children: [
        _buildInfoRow('Batch ID', verification.batchId),
        const SizedBox(height: 16),
        _buildInfoRow('Batch Code', verification.batchCode ?? 'N/A'),
        const SizedBox(height: 16),
        // _buildCopyableInfoRow('Recipe ID', verification.recipeId, context),
      ],
    );
  }

  Widget _buildProductionMetricsCard() {
    final expectedOutput = double.tryParse(verification.expectedOutput) ?? 0;
    final actualOutput = double.tryParse(verification.actualOutput) ?? 0;
    final variance = double.tryParse(verification.variance) ?? 0;
    final efficiency = expectedOutput > 0
        ? ((actualOutput / expectedOutput) * 100).toStringAsFixed(1)
        : '0.0';

    return _buildInfoCard(
      title: 'Production Metrics',
      icon: Icons.analytics_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricBox(
                label: 'Expected',
                value: verification.expectedOutput,
                color: const Color(0xFF2196F3),
                icon: Icons.flag_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricBox(
                label: 'Actual',
                value: verification.actualOutput,
                color: const Color(0xFF4CAF50),
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricBox(
                label: 'Variance',
                value: verification.variance,
                color: variance < 0
                    ? const Color(0xFFF44336)
                    : const Color(0xFF4CAF50),
                icon: variance < 0 ? Icons.trending_down : Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricBox(
                label: 'Efficiency',
                value: '$efficiency%',
                color: const Color(0xFFFF9800),
                icon: Icons.speed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQualityControlCard() {
    final qcStatusColor = _getQcStatusColor(verification.qcStatus);

    return _buildInfoCard(
      title: 'Quality Control',
      icon: Icons.assignment_turned_in_outlined,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: qcStatusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: qcStatusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: qcStatusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppIcon(
                  _getQcStatusIcon(verification.qcStatus),
                  color: qcStatusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QC Status',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getQcStatusText(verification.qcStatus),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: qcStatusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (verification.reason.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInfoRow('Reason', verification.reason),
        ],
      ],
    );
  }

  Widget _buildTeamInfoCard() {
    return _buildInfoCard(
      title: 'Team Information',
      icon: Icons.group_outlined,
      children: [
        _buildTeamMemberRow(
          role: 'Assigned To',
          name: verification.assignedTo,
          icon: Icons.person_outline,
          color: const Color(0xFF2196F3),
        ),
        const SizedBox(height: 16),
        _buildTeamMemberRow(
          role: 'Verified By',
          name: verification.verifiedBy,
          icon: Icons.verified_user_outlined,
          color: const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildTimestampCard() {
    return _buildInfoCard(
      title: 'Timeline',
      icon: Icons.schedule_outlined,
      children: [
        _buildInfoRow('Timestamp', _formatDateTime(verification.timestamp)),
        const SizedBox(height: 16),
        _buildInfoRow('Created At', _formatDateTime(verification.createdAt)),
        const SizedBox(height: 16),
        _buildInfoRow('Updated At', _formatDateTime(verification.updatedAt)),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppIcon(icon, size: 20, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: const Color(0xFF757575),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableInfoRow(
    String label,
    String value,
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: const Color(0xFF757575),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _copyToClipboard(value, context),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const AppIcon(
                    Icons.copy,
                    size: 16,
                    color: Color(0xFF757575),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const AppIcon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              'Recipe ID copied to clipboard',
              style: WorkSansAppTextStyles.medium.copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: const Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberRow({
    required String role,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: AppIcon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getQcStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'WITHIN_TOLERANCE':
        return const Color(0xFF4CAF50);
      case 'SLIGHT_OVERUSE':
      case 'PENDING':
        return const Color(0xFFFF9800);
      case 'REJECTED':
      case 'SIGNIFICANT_VARIANCE':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _getQcStatusText(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  IconData _getQcStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'WITHIN_TOLERANCE':
        return Icons.check_circle;
      case 'SLIGHT_OVERUSE':
      case 'PENDING':
        return Icons.warning;
      case 'REJECTED':
      case 'SIGNIFICANT_VARIANCE':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final month = months[dt.month - 1];
      final day = dt.day.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');

      return '$month $day, $year at $hour:$minute';
    } catch (e) {
      return dateTime;
    }
  }
}
