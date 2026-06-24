// presentation/output_verification_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/bloc/output_ver_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/output_ver_blocs/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/output_ver_blocs/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/output_verfification_model.dart';

import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';

class OutputVerificationHistoryScreen extends StatefulWidget {
  const OutputVerificationHistoryScreen({super.key});

  @override
  State<OutputVerificationHistoryScreen> createState() =>
      _OutputVerificationHistoryScreenState();
}

class _OutputVerificationHistoryScreenState
    extends State<OutputVerificationHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OutputVerificationBloc>().add(const LoadOutputVerifications());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OutputVerificationBloc, OutputVerificationState>(
      builder: (context, state) {
        if (state is OutputVerificationLoading) {
          return _buildLoadingState();
        }

        if (state is OutputVerificationEmpty) {
          return _buildEmptyState();
        }

        if (state is OutputVerificationError) {
          return _buildErrorState(state);
        }

        if (state is OutputVerificationsLoaded ||
            state is OutputVerificationRefreshing) {
          final verifications = state is OutputVerificationsLoaded
              ? state.verifications
              : (state as OutputVerificationRefreshing).currentData;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<OutputVerificationBloc>().add(
                const RefreshOutputVerifications(),
              );
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: kPrimary,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                return ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: _getHorizontalPadding(screenWidth),
                    vertical: _getVerticalPadding(screenWidth),
                  ),
                  itemCount: verifications.length,
                  itemBuilder: (context, index) {
                    final verification = verifications[index];
                    return _buildVerificationCard(verification, screenWidth);
                  },
                );
              },
            ),
          );
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return shimmerCatalogCard(constraints.maxWidth);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fact_check_outlined, size: 50, color: kPrimary),
            ),
            const SizedBox(height: 24),
            Text(
              'No Verifications Yet',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Output verifications will appear here once created',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(OutputVerificationError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(state.errorType),
              size: 64,
              color: const Color(0xFFE53935),
            ),
            const SizedBox(height: 24),
            Text(
              _getErrorTitle(state.errorType),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor2,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<OutputVerificationBloc>().add(
                  const LoadOutputVerifications(),
                );
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                'Retry',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationCard(
    OutputVerification verification,
    double screenWidth,
  ) {
    final variance = int.tryParse(verification.variance) ?? 0;
    final isPositive = variance >= 0;
    final statusColor = _getStatusColor(verification.qcStatus);
    final statusText = _getStatusText(verification.qcStatus);

    return Container(
      margin: EdgeInsets.only(bottom: _getCardSpacing(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with product info
          Container(
            padding: EdgeInsets.all(_getCardPadding(screenWidth)),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_getBorderRadius(screenWidth)),
                topRight: Radius.circular(_getBorderRadius(screenWidth)),
              ),
            ),
            child: Row(
              children: [
                if (verification.recipe?.menuItem?.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      verification.recipe!.menuItem!.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: kPrimary.withValues(alpha: 0.2),
                          child: Icon(Icons.restaurant, color: kPrimary),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.restaurant, color: kPrimary),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verification.productName,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: _getTitleFontSize(screenWidth),
                          fontWeight: FontWeight.w600,
                          color: kprimaryTextColor1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Batch: ${verification.batchId}',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: _getCaptionFontSize(screenWidth),
                          color: kprimaryTextColor2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getCaptionFontSize(screenWidth),
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body with details
          Padding(
            padding: EdgeInsets.all(_getCardPadding(screenWidth)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Output metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Expected',
                        verification.expectedOutput,
                        Icons.track_changes, // <-- replace Icons.target
                        kPrimary,
                        screenWidth,
                      ),
                    ),

                    Expanded(
                      child: _buildMetricItem(
                        'Actual',
                        verification.actualOutput,
                        Icons.check_circle_outline,
                        const Color(0xFF4CAF50),
                        screenWidth,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Variance',
                        '${isPositive ? '+' : ''}${verification.variance}',
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        isPositive
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE53935),
                        screenWidth,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 16),

                // Reason
                _buildDetailRow(
                  'Reason',
                  verification.reason,
                  Icons.info_outline,
                  screenWidth,
                ),
                const SizedBox(height: 12),

                // Personnel
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        'Assigned To',
                        verification.assignedTo,
                        Icons.person_outline,
                        screenWidth,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailRow(
                        'Verified By',
                        verification.verifiedBy,
                        Icons.verified_outlined,
                        screenWidth,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 12),

                // Timestamp
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: kprimaryTextColor2,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateTime(verification.timestamp),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getCaptionFontSize(screenWidth),
                        color: kprimaryTextColor2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
    double screenWidth,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: _getIconSize(screenWidth)),
        const SizedBox(height: 6),
        Text(
          value,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getTitleFontSize(screenWidth),
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getCaptionFontSize(screenWidth),
            color: kprimaryTextColor2,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    double screenWidth,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: _getIconSize(screenWidth) - 4,
          color: kprimaryTextColor2,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getCaptionFontSize(screenWidth),
                  color: kprimaryTextColor2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getBodyFontSize(screenWidth),
                  fontWeight: FontWeight.w500,
                  color: kprimaryTextColor1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTABLE':
        return const Color(0xFF4CAF50);
      case 'SLIGHT_OVERUSE':
        return const Color(0xFFFF9800);
      case 'SIGNIFICANT_OVERUSE':
        return const Color(0xFFE53935);
      case 'UNDERUSE':
        return const Color(0xFF2196F3);
      default:
        return kprimaryTextColor2;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTABLE':
        return 'Acceptable';
      case 'SLIGHT_OVERUSE':
        return 'Slight Overuse';
      case 'SIGNIFICANT_OVERUSE':
        return 'Significant Overuse';
      case 'UNDERUSE':
        return 'Underuse';
      default:
        return status;
    }
  }

  IconData _getErrorIcon(OutputVerificationErrorType type) {
    switch (type) {
      case OutputVerificationErrorType.network:
        return Icons.wifi_off;
      case OutputVerificationErrorType.timeout:
        return Icons.access_time;
      case OutputVerificationErrorType.server:
        return Icons.cloud_off;
      default:
        return Icons.error_outline;
    }
  }

  String _getErrorTitle(OutputVerificationErrorType type) {
    switch (type) {
      case OutputVerificationErrorType.network:
        return 'Connection Error';
      case OutputVerificationErrorType.timeout:
        return 'Request Timeout';
      case OutputVerificationErrorType.server:
        return 'Server Error';
      default:
        return 'Error';
    }
  }

  String _formatDateTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${DateFormat('HH:mm').format(dateTime)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d, yyyy • HH:mm').format(dateTime);
      }
    } catch (e) {
      return timestamp;
    }
  }

  // Responsive sizing functions
  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getVerticalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getCardSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getCardPadding(double width) {
    if (width < 360) return 14;
    if (width < 600) return 16;
    return 18;
  }

  double _getBorderRadius(double width) {
    if (width < 360) return 10;
    if (width < 600) return 12;
    return 14;
  }

  double _getTitleFontSize(double width) {
    if (width < 360) return 15;
    if (width < 600) return 16;
    return 17;
  }

  double _getBodyFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getCaptionFontSize(double width) {
    if (width < 360) return 11;
    if (width < 600) return 12;
    return 13;
  }

  double _getIconSize(double width) {
    if (width < 360) return 20;
    if (width < 600) return 22;
    return 24;
  }
}
