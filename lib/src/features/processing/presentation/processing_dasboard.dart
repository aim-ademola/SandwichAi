import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_dash_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_dash_bloc/event.dart'
    show RefreshProcessingDashboard, LoadProcessingDashboard;
import 'package:sandwich_ai/src/features/processing/bloc/processing_dash_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/processing_dash_model.dart';
import 'package:sandwich_ai/src/features/processing/presentation/processing_drawer.dart';
import 'package:sandwich_ai/src/features/processing/presentation/recent_ver_dtls.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';

class ProcessingDashboardScreen extends StatefulWidget {
  const ProcessingDashboardScreen({super.key});

  @override
  State<ProcessingDashboardScreen> createState() =>
      _ProcessingDashboardScreenState();
}

class _ProcessingDashboardScreenState extends State<ProcessingDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    context.read<ProcessingDashboardBloc>().add(LoadProcessingDashboard());
  }

  Future<void> _onRefresh() async {
    context.read<ProcessingDashboardBloc>().add(RefreshProcessingDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: ProcessingAppDrawer(),
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: _buildAppBar(context),
        body: BlocConsumer<ProcessingDashboardBloc, ProcessingDashboardState>(
          listener: (context, state) {
            if (state is ProcessingDashboardError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ProcessingDashboardInitial ||
                state is ProcessingDashboardLoading ||
                state is ProcessingDashboardRefreshing) {
              return _buildLoading();
            } else if (state is ProcessingDashboardLoaded) {
              return _buildDashboardContent(state.data);
            } else if (state is ProcessingDashboardRefreshing) {
              return _buildDashboardContent(state.currentData);
            } else if (state is ProcessingDashboardError) {
              return _buildError(state.error, state.errorType);
            }
            return _buildLoading();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: Text(
        'Today\'s Overview',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      centerTitle: false,
      actions: [
        BlocBuilder<ProcessingDashboardBloc, ProcessingDashboardState>(
          builder: (context, state) {
            return IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: state is ProcessingDashboardLoading
                  ? null
                  : () => _onRefresh(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return shimmerCatalogCard(constraints.maxWidth);
      },
    );
  }

  Widget _buildError(String error, ProcessingDashboardErrorType errorType) {
    IconData errorIcon;
    String errorTitle;

    switch (errorType) {
      case ProcessingDashboardErrorType.network:
        errorIcon = Icons.wifi_off;
        errorTitle = 'Connection Error';
        break;
      case ProcessingDashboardErrorType.timeout:
        errorIcon = Icons.access_time;
        errorTitle = 'Request Timeout';
        break;
      case ProcessingDashboardErrorType.server:
        errorIcon = Icons.error_outline;
        errorTitle = 'Server Error';
        break;
      case ProcessingDashboardErrorType.notFound:
        errorIcon = Icons.search_off;
        errorTitle = 'Not Found';
        break;
      default:
        errorIcon = Icons.error_outline;
        errorTitle = 'Error';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(errorIcon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              errorTitle,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(ProcessingDashboardData data) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: kPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(data),
            const SizedBox(height: 28),
            _buildDailyProcessingTasks(data.processingTasks),
            const SizedBox(height: 40),
            _buildRecentVerificationsCard(data.recentVerifications),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(ProcessingDashboardData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 16.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Product Intake',
                value: data.productIntake.count.toString(),
                subtitle: null,
                trend: null,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: 'Waste Today',
                value: '₦${_formatNumber(data.wasteToday.value)}',
                subtitle: '${data.wasteToday.count} items',
                trend: null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    String? trend,
  }) {
    final Color? trendColor = trend != null
        ? (trend.startsWith('+')
              ? const Color(0xFF4CAF50)
              : const Color(0xFFF44336))
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              height: 1.3,
              color: const Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          if (trend != null)
            Text(
              trend,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: trendColor,
              ),
            )
          else if (subtitle != null)
            Text(
              subtitle,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: const Color(0xFF9E9E9E),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyProcessingTasks(ProcessingTasks tasks) {
    final total = tasks.pending + tasks.inProcess + tasks.completedToday;

    return Container(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 20),
            child: Text(
              'Daily Processing Tasks',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          _buildTaskProgressRow(
            label: 'Pending',
            value: tasks.pending,
            total: total,
            color: const Color(0xFF9E9E9E),
          ),
          const SizedBox(height: 28),
          _buildTaskProgressRow(
            label: 'In Process',
            value: tasks.inProcess,
            total: total,
            color: const Color(0xFFFF9800),
          ),
          const SizedBox(height: 28),
          _buildTaskProgressRow(
            label: 'Completed',
            value: tasks.completedToday,
            total: total,
            color: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskProgressRow({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final progress = total > 0 ? value / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Text(
              value.toString(),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            color: kPrimary,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentVerificationsCard(List<RecentVerification> verifications) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Verifications',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          if (verifications.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent verifications',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: verifications.length,
              separatorBuilder: (context, index) => Divider(
                height: 32,
                color: const Color(0xFFF5F5F5),
                thickness: 1,
              ),
              itemBuilder: (context, index) {
                final verification = verifications[index];
                return _buildVerificationItem(verification);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(RecentVerification verification) {
    final statusColor = verification.status.toLowerCase() == 'verified'
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF9800);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) =>
                VerificationDetailsScreen(verification: verification),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.check_circle, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verification.productName,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${verification.verifiedBy}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF9E9E9E),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  verification.status,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: const Color(0xFF9E9E9E),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }
}
