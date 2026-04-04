import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_cubit.dart';
import 'package:sandwich_ai/src/features/pos/data/model/order_session_model.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/payment_model.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/pos/presentation/cash_payment_success.dart';
import 'package:sandwich_ai/src/features/pos/presentation/minimze.dart';

class CashApprovalWaitingScreen extends StatefulWidget {
  final CashTransaction transaction;
  final String branchId;
  final String orderType;
  final String? tableNumber;

  /// Pass the active sessionId so the success screen can mark it completed.
  final String? sessionId;

  const CashApprovalWaitingScreen({
    super.key,
    required this.transaction,
    required this.branchId,
    required this.orderType,
    this.tableNumber,
    this.sessionId,
  });

  @override
  State<CashApprovalWaitingScreen> createState() =>
      _CashApprovalWaitingScreenState();
}

class _CashApprovalWaitingScreenState extends State<CashApprovalWaitingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  // If branchId wasn't passed (resumed from session), load it here
  late String _resolvedBranchId;

  @override
  void initState() {
    super.initState();

    _resolvedBranchId = widget.branchId;
    if (_resolvedBranchId.isEmpty) {
      _loadBranchId();
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _scheduleNextPoll();
  }

  Future<void> _loadBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    if (mounted) setState(() => _resolvedBranchId = id);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _scheduleNextPoll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        context.read<PaymentBloc>().add(
          PollCashApprovalStatus(
            transactionId: widget.transaction.transactionId,
            branchId: _resolvedBranchId,
          ),
        );
        _scheduleNextPoll();
      }
    });
  }

  void _pollNow() {
    context.read<PaymentBloc>().add(
      PollCashApprovalStatus(
        transactionId: widget.transaction.transactionId,
        branchId: _resolvedBranchId,
      ),
    );
  }

  String _formatAmount(String amount) {
    try {
      return '₦${double.parse(amount).toStringAsFixed(2)}';
    } catch (_) {
      return '₦$amount';
    }
  }

  String _formatDate(String dt) {
    try {
      final wat = DateTime.parse(dt).toUtc().add(const Duration(hours: 1));
      return DateFormat('MMM dd, yyyy • hh:mm a').format(wat);
    } catch (_) {
      return dt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is CashPaymentApproved) {
          // Capture cubit before pushReplacement loses this context
          final sessionCubit = context.read<OrderSessionCubit>();

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: sessionCubit,
                child: CashPaymentSuccessScreen(
                  transaction: widget.transaction,
                  orderType: widget.orderType,
                  tableNumber: widget.tableNumber,
                  sessionId: widget.sessionId,
                ),
              ),
            ),
          );
        }
        // CashPaymentStillPending → polling continues
      },
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (!didPop) {
            final leave = await _showExitDialog();
            if (leave == true && context.mounted) {
              Navigator.of(context).popUntil((r) => r.isFirst);
            }
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F6F6),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Awaiting Approval',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            centerTitle: true,
            actions: [
              MinimizeButton(
                sessionId: widget.sessionId,
                screen: MinimizedScreen.cashWaiting,
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: _hp(w),
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAnimatedIcon(),
                        const SizedBox(height: 28),
                        _buildTitle(w),
                        const SizedBox(height: 12),
                        _buildSubtitle(w),
                        const SizedBox(height: 36),
                        _buildDetailsCard(w),
                        const SizedBox(height: 36),
                        _buildPollingIndicator(),
                        const SizedBox(height: 28),
                        _buildActions(w),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFA000).withOpacity(0.12),
            ),
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFFA000),
          ),
          child: const Icon(
            Icons.hourglass_top_rounded,
            size: 38,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(double w) {
    return Text(
      'Awaiting Manager Approval',
      textAlign: TextAlign.center,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: w < 360
            ? 20
            : w < 600
            ? 22
            : 24,
        fontWeight: FontWeight.w700,
        color: kprimaryTextColor1,
      ),
    );
  }

  Widget _buildSubtitle(double w) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _hp(w)),
      child: Text(
        'This cash payment has been recorded and is pending approval from a branch manager or admin. You will be notified once it\'s approved.',
        textAlign: TextAlign.center,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: w < 360 ? 13 : 14,
          color: kprimaryTextColor2,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _buildDetailsCard(double w) {
    final tx = widget.transaction;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA000).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.pending_outlined,
                      size: 14,
                      color: Color(0xFFFFA000),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'PENDING APPROVAL',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFA000),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _row('Transaction ID', tx.transactionId, w),
          _row('Customer', tx.customerName, w),
          if (tx.customerPhone != null) _row('Phone', tx.customerPhone!, w),
          _row('Amount', _formatAmount(tx.amount), w, highlight: true),
          _row(
            'Received By',
            '${tx.receiver?.firstName ?? ''} ${tx.receiver?.lastName ?? ''}'
                .trim(),
            w,
          ),
          _row('Branch', tx.branch?.name ?? '', w),
          _row('Recorded At', _formatDate(tx.createdAt), w),
        ],
      ),
    );
  }

  Widget _row(String label, String value, double w, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: w < 360 ? 12 : 13,
              color: kprimaryTextColor2,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: w < 360 ? 12 : 13,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                color: highlight ? kPrimary : kprimaryTextColor1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollingIndicator() {
    return Column(
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFA000)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Checking approval status every 5 seconds…',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 12,
            color: kprimaryTextColor2,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(double w) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pollNow,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Check Now',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: w < 360 ? 14 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimary,
              side: const BorderSide(color: kPrimary, width: 1.8),
              padding: EdgeInsets.symmetric(vertical: w < 360 ? 13 : 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () async {
              final leave = await _showExitDialog();
              if (leave == true && mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: kprimaryTextColor2,
              padding: EdgeInsets.symmetric(vertical: w < 360 ? 13 : 15),
            ),
            child: Text(
              'Back to Orders',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: w < 360 ? 14 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Leave This Screen?',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Your cash payment is pending approval. You can check its status later in the transactions section.',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: kprimaryTextColor2,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Stay Here',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor2,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Leave',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _hp(double w) {
    if (w < 360) return 16;
    if (w < 600) return 20;
    if (w < 900) return 24;
    return 32;
  }
}
