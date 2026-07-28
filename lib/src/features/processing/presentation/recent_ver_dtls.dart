import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/processing/data/model/processing_dash_model.dart';

class VerificationDetailsScreen extends StatelessWidget {
  final RecentVerification verification;

  const VerificationDetailsScreen({super.key, required this.verification});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
        appBar: _buildAppBar(context),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(context),
              const SizedBox(height: 20),
              _buildBatchInfoCard(context),
              const SizedBox(height: 20),
              _buildProductionMetricsCard(context),
              const SizedBox(height: 20),
              _buildQualityControlCard(context),
              const SizedBox(height: 20),
              _buildTeamInfoCard(context),
              const SizedBox(height: 20),
              _buildTimestampCard(context),
            ],
          ),
        ),
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
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Verification Details',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: context.modeTextPrimary,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildStatusCard(BuildContext context) {
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      verification.productName,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 18,
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
                    fontSize: 12,
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
      context,
      title: 'Batch Information',
      icon: Icons.inventory_2_outlined,
      children: [
        _buildInfoRow(context, 'Batch ID', verification.batchId),
        const SizedBox(height: 16),
        _buildInfoRow(context, 'Batch Code', verification.batchCode ?? 'N/A'),
        const SizedBox(height: 16),
        // _buildCopyableInfoRow('Recipe ID', verification.recipeId, context),
      ],
    );
  }

  Widget _buildProductionMetricsCard(BuildContext context) {
    final expectedOutput = double.tryParse(verification.expectedOutput) ?? 0;
    final actualOutput = double.tryParse(verification.actualOutput) ?? 0;
    final variance = double.tryParse(verification.variance) ?? 0;
    final efficiency = expectedOutput > 0
        ? ((actualOutput / expectedOutput) * 100).toStringAsFixed(1)
        : '0.0';

    return _buildInfoCard(
      context,
      title: 'Production Metrics',
      icon: Icons.analytics_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricBox(
                context,
                label: 'Expected',
                value: verification.expectedOutput,
                color: const Color(0xFF2196F3),
                icon: Icons.flag_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricBox(
                context,
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
                context,
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
                context,
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

  Widget _buildQualityControlCard(BuildContext context) {
    final qcStatusColor = _getQcStatusColor(verification.qcStatus);

    return _buildInfoCard(
      context,
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
                        color: context.modeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getQcStatusText(verification.qcStatus),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
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
          _buildInfoRow(context, 'Reason', verification.reason),
        ],
      ],
    );
  }

  Widget _buildTeamInfoCard(BuildContext context) {
    return _buildInfoCard(
      context,
      title: 'Team Information',
      icon: Icons.group_outlined,
      children: [
        _buildTeamMemberRow(
          context,
          role: 'Assigned To',
          name: verification.assignedTo,
          icon: Icons.person_outline,
          color: const Color(0xFF2196F3),
        ),
        const SizedBox(height: 16),
        _buildTeamMemberRow(
          context,
          role: 'Verified By',
          name: verification.verifiedBy,
          icon: Icons.verified_user_outlined,
          color: const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildTimestampCard(BuildContext context) {
    return _buildInfoCard(
      context,
      title: 'Timeline',
      icon: Icons.schedule_outlined,
      children: [
        _buildInfoRow(
          context,
          'Timestamp',
          _formatDateTime(verification.timestamp),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          context,
          'Created At',
          _formatDateTime(verification.createdAt),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          context,
          'Updated At',
          _formatDateTime(verification.updatedAt),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modeBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.modeSurfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppIcon(icon, size: 18, color: context.modeTextPrimary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.modeTextPrimary,
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              color: context.modeTextSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, color: color, size: 18),
          const SizedBox(height: 12),
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: context.modeTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberRow(
    BuildContext context, {
    required String role,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: AppIcon(icon, color: color, size: 20),
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
                  color: context.modeTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
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
