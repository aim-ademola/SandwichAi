import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_cubit.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/order_session_model.dart';

class SessionManagerScreen extends StatelessWidget {
  const SessionManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderSessionCubit, OrderSessionState>(
      builder: (context, state) {
        return DefaultTextStyle.merge(
          style: WorkSansAppTextStyles.medium,
          child: Scaffold(
            backgroundColor: context.modeBackground,
            appBar: AppBar(
              backgroundColor: context.modeSurface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Sessions',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: context.modeTextPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                if (state.canAddSession)
                  TextButton.icon(
                    onPressed: () => _createAndSwitch(context),
                    icon: Icon(Icons.add, color: context.modePrimary, size: 20),
                    label: Text(
                      'New',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        color: context.modePrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        '10/10',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          color: context.modeTextMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            body: state.sessions.isEmpty
                ? _buildEmpty(context)
                : _buildSessionList(context, state),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: context.modeTextMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No active sessions',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new session to take an order.',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: context.modeTextSecondary,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => _createAndSwitch(context),
            icon: const Icon(Icons.add),
            label: const Text('New Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.modePrimary,
              foregroundColor: context.modeTextInverse,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(BuildContext context, OrderSessionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary bar
        Container(
          color: context.modeSurface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              _SummaryChip(
                label: '${state.sessions.length} Active',
                color: context.modePrimary,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label:
                    '${state.sessions.where((s) => s.status == SessionStatus.paymentInProgress).length} Paying',
                color: context.modeWarning,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label:
                    '${state.sessions.where((s) => s.status == SessionStatus.completed).length} Done',
                color: context.modeSuccess,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: state.sessions.length,
            itemBuilder: (context, index) {
              final session = state.sessions[index];
              final isActive = session.sessionId == state.activeSessionId;
              return _SessionCard(
                session: session,
                isActive: isActive,
                onTap: () => _switchToSession(context, session.sessionId),
                onClose: () => _confirmClose(context, session),
              );
            },
          ),
        ),

        // Bottom CTA if no session is active
        if (!state.hasActiveSession)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.canAddSession
                    ? () => _createAndSwitch(context)
                    : null,
                icon: const Icon(Icons.add),
                label: const Text('New Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.modePrimary,
                  foregroundColor: context.modeTextInverse,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _createAndSwitch(BuildContext context) {
    final cubit = context.read<OrderSessionCubit>();
    cubit.createSession();
    // Pop back — OrderScreen will read the new activeSession on resume.
    Navigator.of(context).pop();
  }

  void _switchToSession(BuildContext context, String sessionId) {
    context.read<OrderSessionCubit>().switchToSession(sessionId);
    Navigator.of(context).pop();
  }

  void _confirmClose(BuildContext context, OrderSession session) {
    final cubit = context.read<OrderSessionCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.modeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Close Session?',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: context.modeTextPrimary,
          ),
        ),
        content: Text(
          'Close "${session.label}"? This will discard all items and order progress.',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: context.modeTextSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: WorkSansAppTextStyles.medium.copyWith(
                color: context.modeTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              cubit.closeSession(session.sessionId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.modeError,
              foregroundColor: context.modeTextInverse,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Close',
              style: WorkSansAppTextStyles.medium.copyWith(
                color: context.modeTextInverse,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session Card
// ─────────────────────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final OrderSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _SessionCard({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(session.status, session.minimizedScreen);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? context.modePrimary : context.modeBorder,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? context.modePrimary.withValues(alpha: 0.12)
                  : Colors.black.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.24
                          : 0.04,
                    ),
              blurRadius: isActive ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status dot / icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusInfo.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusInfo.icon, color: statusInfo.color, size: 22),
              ),
              const SizedBox(width: 14),

              // Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.label,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.modeTextPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: context.modePrimary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Active',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.modeTextInverse,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (session.isMinimized) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.minimize_rounded,
                                  size: 12,
                                  color: Colors.deepOrange,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _minimizedLabel(session.minimizedScreen!),
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          statusInfo.label,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: statusInfo.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '·',
                          style: TextStyle(color: context.modeTextMuted),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${session.totalItemCount} item${session.totalItemCount != 1 ? "s" : ""}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: context.modeTextSecondary,
                          ),
                        ),
                        if (session.orderDetails?.orderType != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '·',
                            style: TextStyle(color: context.modeTextMuted),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _orderTypeLabel(session.orderDetails!.orderType),
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 12,
                              color: context.modeTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(session.lastUpdatedAt),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 11,
                        color: context.modeTextMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Close button
              IconButton(
                icon: Icon(Icons.close, color: context.modeTextMuted, size: 20),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusInfo _statusInfo(SessionStatus status, MinimizedScreen? minimized) {
    // If minimized, show which screen they're paused at
    if (minimized != null) {
      return _StatusInfo(
        label: 'Minimized',
        icon: Icons.minimize_rounded,
        color: Colors.deepOrange,
      );
    }
    switch (status) {
      case SessionStatus.building:
        return _StatusInfo(
          label: 'Building order',
          icon: Icons.shopping_cart_outlined,
          color: Colors.blue,
        );
      case SessionStatus.detailsConfirmed:
        return _StatusInfo(
          label: 'Ready to pay',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        );
      case SessionStatus.paymentInProgress:
        return _StatusInfo(
          label: 'Payment in progress',
          icon: Icons.payment,
          color: Colors.orange,
        );
      case SessionStatus.completed:
        return _StatusInfo(
          label: 'Completed',
          icon: Icons.task_alt,
          color: Colors.green,
        );
    }
  }

  String _minimizedLabel(MinimizedScreen screen) {
    switch (screen) {
      case MinimizedScreen.orderSummary:
        return 'Order Summary';
      case MinimizedScreen.paymentMethod:
        return 'Payment';
      case MinimizedScreen.cashWaiting:
        return 'Cash Approval';
      case MinimizedScreen.onlineQr:
        return 'QR Payment';
    }
  }

  String _orderTypeLabel(String type) {
    switch (type) {
      case 'DINE_IN':
        return 'Dine In';
      case 'TAKE_AWAY':
        return 'Take Away';
      case 'DELIVERY':
        return 'Delivery';
      default:
        return type;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ${diff.inMinutes % 60}m ago';
  }
}

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _StatusInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary chip
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SummaryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
