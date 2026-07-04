import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_cubit.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/order_session_model.dart';

class SessionManagerScreen extends StatefulWidget {
  final void Function(BuildContext context, OrderSession session)?
  onResumeSession;

  const SessionManagerScreen({super.key, this.onResumeSession});

  @override
  State<SessionManagerScreen> createState() => _SessionManagerScreenState();
}

class _SessionManagerScreenState extends State<SessionManagerScreen> {
  late final PageController _pageController;
  String? _activeSessionId;

  @override
  void initState() {
    super.initState();
    final state = context.read<OrderSessionCubit>().state;
    final initialPage = _activeIndex(state);
    _activeSessionId = state.activeSessionId;
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: 0.94,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderSessionCubit, OrderSessionState>(
      listenWhen: (previous, current) =>
          previous.activeSessionId != current.activeSessionId ||
          previous.sessions.length != current.sessions.length,
      listener: (context, state) {
        final index = _activeIndex(state);
        _activeSessionId = state.activeSessionId;
        if (!_pageController.hasClients || state.sessions.isEmpty) return;
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      },
      builder: (context, state) {
        return DefaultTextStyle.merge(
          style: WorkSansAppTextStyles.medium,
          child: Scaffold(
            backgroundColor: context.modeBackground,
            appBar: AppBar(
              backgroundColor: context.modeSurface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: context.modeTextPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'Order Sessions',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.modeTextPrimary,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: 'New session',
                  onPressed: state.canAddSession
                      ? () => _createSession(context)
                      : null,
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: state.canAddSession
                        ? context.modePrimary
                        : context.modeTextMuted,
                  ),
                ),
              ],
            ),
            body: state.sessions.isEmpty
                ? _EmptySessions(onCreate: () => _createSession(context))
                : Column(
                    children: [
                      _SessionOverview(state: state),
                      _SessionTabs(
                        state: state,
                        onSessionTap: (index) => _goToSession(context, index),
                        onCreate: state.canAddSession
                            ? () => _createSession(context)
                            : null,
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: state.sessions.length,
                          onPageChanged: (index) {
                            final sessionId = state.sessions[index].sessionId;
                            if (sessionId == _activeSessionId) return;
                            context.read<OrderSessionCubit>().switchSession(
                              index,
                            );
                          },
                          itemBuilder: (context, index) {
                            final session = state.sessions[index];
                            return _SessionPage(
                              session: session,
                              isActive:
                                  session.sessionId == state.activeSessionId,
                              onResume: () {
                                context
                                    .read<OrderSessionCubit>()
                                    .switchToSession(session.sessionId);
                                if (widget.onResumeSession != null) {
                                  widget.onResumeSession!(context, session);
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                              onMarkPaid: () => context
                                  .read<OrderSessionCubit>()
                                  .markAsPaid(session.sessionId),
                              onSendToKitchen: () => context
                                  .read<OrderSessionCubit>()
                                  .sendToKitchen(session.sessionId),
                              onComplete: () => context
                                  .read<OrderSessionCubit>()
                                  .completeSession(session.sessionId),
                              onEditSupportNotes: () =>
                                  _editSupportNotes(context, session),
                              onDelete: () => _confirmDelete(context, session),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  int _activeIndex(OrderSessionState state) {
    if (state.sessions.isEmpty) return 0;
    final index = state.sessions.indexWhere(
      (session) => session.sessionId == state.activeSessionId,
    );
    return index < 0 ? 0 : index;
  }

  void _createSession(BuildContext context) {
    final cubit = context.read<OrderSessionCubit>();
    if (!cubit.state.canAddSession) return;
    cubit.createSession();
  }

  void _goToSession(BuildContext context, int index) {
    context.read<OrderSessionCubit>().switchSession(index);
  }

  Future<void> _editSupportNotes(
    BuildContext context,
    OrderSession session,
  ) async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.modeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _SupportNotesSheet(initialValue: session.supportNotes),
    );

    if (result == null || !context.mounted) return;
    context.read<OrderSessionCubit>().updateSessionSupportNotes(
      session.sessionId,
      result,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OrderSession session,
  ) async {
    final isCompleted = session.status == SessionStatus.completed;
    final title = isCompleted ? 'Close Completed Session?' : 'Discard Order?';
    final action = isCompleted ? 'Close' : 'Discard';
    final message = isCompleted
        ? 'Close "${session.label}" and remove it from active sessions?'
        : 'Discard "${session.label}"? This removes its items, notes, and progress.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.modeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.modeTextPrimary,
          ),
        ),
        content: Text(
          message,
          style: WorkSansAppTextStyles.medium.copyWith(
            color: context.modeTextSecondary,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: WorkSansAppTextStyles.medium.copyWith(
                color: context.modeTextSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.modeError,
              foregroundColor: context.modeTextInverse,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    context.read<OrderSessionCubit>().deleteSession(session.sessionId);
  }
}

class _SessionOverview extends StatelessWidget {
  final OrderSessionState state;

  const _SessionOverview({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.modeSurface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SummaryChip(
            label: '${state.sessions.length} Active',
            color: context.modePrimary,
          ),
          _SummaryChip(
            label: '${_count(SessionStatus.paymentInProgress)} Awaiting',
            color: context.modeWarning,
          ),
          _SummaryChip(
            label: '${_count(SessionStatus.paid)} Paid',
            color: context.modeSuccess,
          ),
          _SummaryChip(
            label: '${_count(SessionStatus.completed)} Done',
            color: context.modeInfo,
          ),
        ],
      ),
    );
  }

  int _count(SessionStatus status) {
    return state.sessions.where((session) => session.status == status).length;
  }
}

class _SessionTabs extends StatelessWidget {
  final OrderSessionState state;
  final ValueChanged<int> onSessionTap;
  final VoidCallback? onCreate;

  const _SessionTabs({
    required this.state,
    required this.onSessionTap,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      color: context.modeSurface,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: state.sessions.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == state.sessions.length) {
            return ActionChip(
              onPressed: onCreate,
              avatar: Icon(Icons.add, size: 18, color: context.modePrimary),
              label: const Text('New Order'),
              backgroundColor: context.modeSurfaceAlt,
              side: BorderSide(color: context.modeBorder),
              labelStyle: WorkSansAppTextStyles.medium.copyWith(
                color: onCreate == null
                    ? context.modeTextMuted
                    : context.modeTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            );
          }

          final session = state.sessions[index];
          final isActive = session.sessionId == state.activeSessionId;
          final status = _statusInfo(context, session.status);
          return ChoiceChip(
            selected: isActive,
            onSelected: (_) => onSessionTap(index),
            avatar: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
              ),
            ),
            label: Text(
              session.totalItemCount == 0
                  ? session.label
                  : '${session.label} (${session.totalItemCount})',
            ),
            selectedColor: context.modePrimary.withValues(alpha: 0.14),
            backgroundColor: context.modeSurfaceAlt,
            side: BorderSide(
              color: isActive ? context.modePrimary : context.modeBorder,
            ),
            labelStyle: WorkSansAppTextStyles.medium.copyWith(
              color: isActive ? context.modePrimary : context.modeTextSecondary,
              fontWeight: FontWeight.w800,
            ),
          );
        },
      ),
    );
  }
}

class _SessionPage extends StatelessWidget {
  final OrderSession session;
  final bool isActive;
  final VoidCallback onResume;
  final VoidCallback onMarkPaid;
  final VoidCallback onSendToKitchen;
  final VoidCallback onComplete;
  final VoidCallback onEditSupportNotes;
  final VoidCallback onDelete;

  const _SessionPage({
    required this.session,
    required this.isActive,
    required this.onResume,
    required this.onMarkPaid,
    required this.onSendToKitchen,
    required this.onComplete,
    required this.onEditSupportNotes,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo(context, session.status);
    final payment = _paymentInfo(context, session);
    final details = session.orderDetails;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 18),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: context.modeSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? context.modePrimary : context.modeBorder,
              width: isActive ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.22
                      : 0.05,
                ),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(status.icon, color: status.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: context.modeTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Updated ${_timeAgo(session.lastUpdatedAt)}',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 12,
                              color: context.modeTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete session',
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        color: context.modeError,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(label: status.label, color: status.color),
                    _StatusPill(label: payment.label, color: payment.color),
                    if (session.isMinimized)
                      const _StatusPill(
                        label: 'Paused mid-flow',
                        color: Colors.deepOrange,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _InfoGrid(
                  children: [
                    _InfoTile(
                      icon: Icons.person_outline,
                      label: 'Customer',
                      value: details?.customerName ?? 'Guest',
                    ),
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: details?.customerPhone ?? 'Not added',
                    ),
                    _InfoTile(
                      icon: Icons.restaurant_menu,
                      label: 'Items',
                      value:
                          '${session.totalItemCount} item${session.totalItemCount == 1 ? '' : 's'}',
                    ),
                    _InfoTile(
                      icon: Icons.receipt_long_outlined,
                      label: 'Order type',
                      value: _orderTypeLabel(details?.orderType),
                    ),
                  ],
                ),
                if (details?.tableNumber != null) ...[
                  const SizedBox(height: 10),
                  _InlineInfo(
                    icon: Icons.table_restaurant_outlined,
                    label: 'Table',
                    value: details!.tableNumber!,
                  ),
                ],
                const SizedBox(height: 18),
                _NotesBlock(
                  title: 'Order Note',
                  value: session.orderNote,
                  emptyText: 'No kitchen/service note yet.',
                ),
                const SizedBox(height: 10),
                _NotesBlock(
                  title: 'Special Requests',
                  value: _specialRequestSummary(session),
                  emptyText: 'No item special requests.',
                ),
                const SizedBox(height: 10),
                _NotesBlock(
                  title: 'Support Notes',
                  value: session.supportNotes,
                  emptyText: 'No support notes yet.',
                  trailing: TextButton.icon(
                    onPressed: onEditSupportNotes,
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(height: 20),
                _ActionBar(
                  session: session,
                  onResume: onResume,
                  onMarkPaid: onMarkPaid,
                  onSendToKitchen: onSendToKitchen,
                  onComplete: onComplete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _specialRequestSummary(OrderSession session) {
    if (session.specialRequests.isEmpty) return null;
    return session.specialRequests.values.join('\n');
  }
}

class _ActionBar extends StatelessWidget {
  final OrderSession session;
  final VoidCallback onResume;
  final VoidCallback onMarkPaid;
  final VoidCallback onSendToKitchen;
  final VoidCallback onComplete;

  const _ActionBar({
    required this.session,
    required this.onResume,
    required this.onMarkPaid,
    required this.onSendToKitchen,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: onResume,
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Resume Order'),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.modePrimary,
            foregroundColor: context.modeTextInverse,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _canMarkPaid(session.status) ? onMarkPaid : null,
          icon: const Icon(Icons.payments_outlined, size: 18),
          label: const Text('Mark Paid'),
        ),
        OutlinedButton.icon(
          onPressed: _canSendToKitchen(session.status) ? onSendToKitchen : null,
          icon: const Icon(Icons.soup_kitchen_outlined, size: 18),
          label: const Text('Send Kitchen'),
        ),
        OutlinedButton.icon(
          onPressed: session.status == SessionStatus.completed
              ? null
              : onComplete,
          icon: const Icon(Icons.task_alt, size: 18),
          label: const Text('Complete'),
        ),
      ],
    );
  }

  bool _canMarkPaid(SessionStatus status) {
    return status == SessionStatus.detailsConfirmed ||
        status == SessionStatus.paymentInProgress ||
        status == SessionStatus.parked;
  }

  bool _canSendToKitchen(SessionStatus status) {
    return status == SessionStatus.paid ||
        status == SessionStatus.paymentInProgress;
  }
}

class _InfoGrid extends StatelessWidget {
  final List<Widget> children;

  const _InfoGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 520 ? 2 : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 2 ? 3.8 : 4.9,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: children,
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.modePrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 11,
                    height: 1.15,
                    color: context.modeTextMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    height: 1.15,
                    color: context.modeTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InlineInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.modeTextMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: WorkSansAppTextStyles.medium.copyWith(
            color: context.modeTextMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: WorkSansAppTextStyles.medium.copyWith(
              color: context.modeTextPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesBlock extends StatelessWidget {
  final String title;
  final String? value;
  final String emptyText;
  final Widget? trailing;

  const _NotesBlock({
    required this.title,
    required this.value,
    required this.emptyText,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    color: context.modeTextMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          Text(
            hasValue ? value! : emptyText,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              color: hasValue ? context.modeTextPrimary : context.modeTextMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportNotesSheet extends StatefulWidget {
  final String? initialValue;

  const _SupportNotesSheet({this.initialValue});

  @override
  State<_SupportNotesSheet> createState() => _SupportNotesSheetState();
}

class _SupportNotesSheetState extends State<_SupportNotesSheet> {
  late String _notes;

  @override
  void initState() {
    super.initState();
    _notes = widget.initialValue ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support Notes',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _notes,
              autofocus: true,
              maxLines: 5,
              cursorColor: context.modePrimary,
              onChanged: (value) => setState(() => _notes = value),
              style: WorkSansAppTextStyles.medium.copyWith(
                color: context.modeTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Add conversation or follow-up notes...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  color: context.modeTextMuted,
                ),
                filled: true,
                fillColor: context.modeSurfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.modeBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.modePrimary),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (_notes.trim().isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(''),
                    child: Text(
                      'Clear',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        color: context.modeError,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(
                    'Cancel',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      color: context.modeTextSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_notes.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.modePrimary,
                    foregroundColor: context.modeTextInverse,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySessions extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptySessions({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
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
                fontWeight: FontWeight.w700,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new session to take an order.',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('New Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                foregroundColor: context.modeTextInverse,
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
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

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
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
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

_StatusInfo _statusInfo(BuildContext context, SessionStatus status) {
  switch (status) {
    case SessionStatus.building:
      return const _StatusInfo(
        label: 'Draft',
        icon: Icons.shopping_cart_outlined,
        color: Colors.blue,
      );
    case SessionStatus.parked:
      return const _StatusInfo(
        label: 'Parked',
        icon: Icons.pause_circle_outline,
        color: Colors.purple,
      );
    case SessionStatus.detailsConfirmed:
      return _StatusInfo(
        label: 'Ready for payment',
        icon: Icons.fact_check_outlined,
        color: context.modeSuccess,
      );
    case SessionStatus.paymentInProgress:
      return _StatusInfo(
        label: 'Awaiting payment',
        icon: Icons.payment,
        color: context.modeWarning,
      );
    case SessionStatus.paid:
      return _StatusInfo(
        label: 'Paid',
        icon: Icons.payments_outlined,
        color: context.modeSuccess,
      );
    case SessionStatus.sentToKitchen:
      return _StatusInfo(
        label: 'Sent to kitchen',
        icon: Icons.soup_kitchen_outlined,
        color: context.modeInfo,
      );
    case SessionStatus.completed:
      return _StatusInfo(
        label: 'Completed',
        icon: Icons.task_alt,
        color: context.modeSuccess,
      );
    case SessionStatus.cancelled:
      return _StatusInfo(
        label: 'Cancelled',
        icon: Icons.cancel_outlined,
        color: context.modeError,
      );
  }
}

_StatusInfo _paymentInfo(BuildContext context, OrderSession session) {
  if (session.status == SessionStatus.paid ||
      session.status == SessionStatus.sentToKitchen ||
      session.status == SessionStatus.completed) {
    return _StatusInfo(
      label: 'Payment paid',
      icon: Icons.verified_outlined,
      color: context.modeSuccess,
    );
  }

  switch (session.paymentState.method) {
    case PaymentMethod.none:
      return _StatusInfo(
        label: 'Payment not started',
        icon: Icons.money_off_csred_outlined,
        color: context.modeTextMuted,
      );
    case PaymentMethod.cash:
      return _StatusInfo(
        label: session.paymentState.cashTransaction == null
            ? 'Cash selected'
            : 'Cash awaiting approval',
        icon: Icons.account_balance_wallet_outlined,
        color: context.modeWarning,
      );
    case PaymentMethod.cardOrBankTransfer:
      return _StatusInfo(
        label: session.paymentState.onlinePaymentInitData == null
            ? 'Transfer selected'
            : 'QR payment active',
        icon: Icons.qr_code_2_outlined,
        color: context.modeWarning,
      );
  }
}

String _orderTypeLabel(String? type) {
  switch (type) {
    case 'DINE_IN':
      return 'Dine In';
    case 'TAKEAWAY':
    case 'TAKE_AWAY':
    case 'TAKE_OUT':
      return 'Take Away';
    case 'DELIVERY':
      return 'Delivery';
    case 'ONLINE':
      return 'Online';
    case null:
      return 'Not selected';
    default:
      return type;
  }
}

String _timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
