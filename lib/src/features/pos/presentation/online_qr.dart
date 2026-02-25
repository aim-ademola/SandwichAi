import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_cubit.dart';
import 'package:sandwich_ai/src/features/pos/data/model/order_session_model.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/payment_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:sandwich_ai/src/features/pos/presentation/minimze.dart'
    show MinimizeButton;
import 'package:sandwich_ai/src/features/pos/presentation/online_reciet.dart';

class OnlinePaymentQrScreen extends StatefulWidget {
  final OnlinePaymentInitData initData;
  final String orderType;
  final String? tableNumber;
  final String customerName;

  /// The session this payment belongs to. Passed through to receipt screen.
  final String? sessionId;

  const OnlinePaymentQrScreen({
    super.key,
    required this.initData,
    required this.orderType,
    this.tableNumber,
    required this.customerName,
    this.sessionId,
  });

  @override
  State<OnlinePaymentQrScreen> createState() => _OnlinePaymentQrScreenState();
}

class _OnlinePaymentQrScreenState extends State<OnlinePaymentQrScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scheduleNextPoll();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _scheduleNextPoll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        context.read<PaymentBloc>().add(
          PollOnlinePaymentStatus(reference: widget.initData.reference),
        );
        _scheduleNextPoll();
      }
    });
  }

  void _pollNow() {
    context.read<PaymentBloc>().add(
      PollOnlinePaymentStatus(reference: widget.initData.reference),
    );
  }

  String _formatAmount(double amount) => '₦${amount.toStringAsFixed(2)}';

  String _formatExpiry(String dt) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(dt));
    } catch (_) {
      return dt;
    }
  }

  void _copyReference() {
    Clipboard.setData(ClipboardData(text: widget.initData.reference));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reference copied to clipboard',
          style: WorkSansAppTextStyles.medium,
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is OnlinePaymentCompleted) {
          // Capture cubit before pushReplacement loses this context
          final sessionCubit = context.read<OrderSessionCubit>();

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: sessionCubit,
                child: OnlineReceiptScreen(
                  statusData: state.statusData,
                  orderType: widget.orderType,
                  tableNumber: widget.tableNumber,
                  sessionId: widget.sessionId,
                ),
              ),
            ),
          );
        } else if (state is OnlinePaymentFailed) {
          _showFailureDialog(state.reason);
        }
        // OnlinePaymentStillPending → do nothing
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
        child: DefaultTextStyle.merge(
          style: WorkSansAppTextStyles.medium,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F6F6),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () async {
                  final leave = await _showExitDialog();
                  if (leave == true && context.mounted) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
              ),
              title: Text(
                'Scan to Pay',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kprimaryTextColor1,
                ),
              ),
              centerTitle: true,
              actions: [
                MinimizeButton(
                  sessionId: widget.sessionId,
                  screen: MinimizedScreen.onlineQr,
                ),
              ],
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: _hp(w),
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      _buildInstructions(w),
                      const SizedBox(height: 24),
                      _buildQrCard(w),
                      const SizedBox(height: 20),
                      _buildInfoCard(w),
                      const SizedBox(height: 28),
                      _buildPollingIndicator(),
                      const SizedBox(height: 20),
                      _buildActions(w),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions(double w) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: kPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ask the customer to scan this QR code to complete payment.',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: w < 360 ? 12 : 13,
                color: kPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(double w) {
    final qrSize = w < 360
        ? 200.0
        : w < 600
        ? 240.0
        : 280.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _formatAmount(widget.initData.amount),
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: w < 360 ? 28 : 32,
              fontWeight: FontWeight.w800,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.customerName,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: kprimaryTextColor2,
            ),
          ),
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: kPrimary.withOpacity(0.2), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: widget.initData.authorizationUrl,
                version: QrVersions.auto,
                size: qrSize,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Expires at ${_formatExpiry(widget.initData.expiresAt)}',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(double w) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow('Reference', widget.initData.reference, canCopy: true),
          const Divider(height: 20),
          _infoRow('Access Code', widget.initData.accessCode),
          const Divider(height: 20),
          _infoRow('Payment Method', 'Card / Bank Transfer'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool canCopy = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 13,
            color: kprimaryTextColor2,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            if (canCopy) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _copyReference,
                child: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: kPrimary.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ],
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
            valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Waiting for payment confirmation…',
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
              'Check Payment Status',
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
              'Cancel Payment',
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

  void _showFailureDialog(String? reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Colors.red, size: 26),
            const SizedBox(width: 10),
            Text(
              'Payment Failed',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          reason ?? 'The payment could not be completed. Please try again.',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: kprimaryTextColor2,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Back to Orders',
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

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Payment?',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'If the customer has already scanned and paid, the payment will still be recorded. Are you sure you want to leave?',
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
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
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
