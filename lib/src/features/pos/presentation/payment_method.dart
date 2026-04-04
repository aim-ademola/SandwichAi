import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_cubit.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/order_session_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/payment_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_order_repo.dart';
import 'package:sandwich_ai/src/features/pos/presentation/cash_approval_waiting.dart';
import 'package:sandwich_ai/src/features/pos/presentation/minimze.dart';
import 'package:sandwich_ai/src/features/pos/presentation/online_qr.dart';

enum _PaymentMethod { cash, cardOrBankTransfer }

class _PaymentMethodOption {
  final _PaymentMethod method;
  final String title;
  final String subtitle;
  final IconData icon;
  const _PaymentMethodOption({
    required this.method,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class PaymentMethodScreen extends StatefulWidget {
  final Map<ApiMenuItem, int> orderItems;
  final Map<String, String> specialRequests;
  final String orderType;
  final String? tableNumber;
  final String? customerName;
  final String? customerPhone;
  final double discount;
  final String? specialInstructions;
  final double totalAmount;
  final String? sessionId;

  const PaymentMethodScreen({
    super.key,
    required this.orderItems,
    required this.specialRequests,
    required this.orderType,
    this.tableNumber,
    this.customerName,
    this.customerPhone,
    this.discount = 0,
    this.specialInstructions,
    required this.totalAmount,
    this.sessionId,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  _PaymentMethod? _selectedMethod;
  String? _createdOrderId;
  String _branchId = '';
  String? _customerEmail;

  /// Prefer the sessionId passed from the parent. Falls back to the
  /// cubit's active session — covers both fresh navigation and resume paths.
  String? _sessionId;

  final List<_PaymentMethodOption> _options = const [
    _PaymentMethodOption(
      method: _PaymentMethod.cash,
      title: 'Cash',
      subtitle: 'Requires manager approval before finalizing',
      icon: Icons.account_balance_wallet_outlined,
    ),
    _PaymentMethodOption(
      method: _PaymentMethod.cardOrBankTransfer,
      title: 'Card / Bank Transfer',
      subtitle: 'Pay via Paystack — scan QR or link',
      icon: Icons.credit_card_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBranchId();
    _sessionId =
        widget.sessionId ??
        context.read<OrderSessionCubit>().state.activeSession?.sessionId;
    _restorePaymentState();
  }

  Future<void> _loadBranchId() async {
    _branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
  }

  void _restorePaymentState() {
    final session = context.read<OrderSessionCubit>().state.activeSession;
    if (session == null) return;

    final saved = session.paymentState;

    if (saved.method != PaymentMethod.none) {
      setState(() {
        _selectedMethod = saved.method == PaymentMethod.cash
            ? _PaymentMethod.cash
            : _PaymentMethod.cardOrBankTransfer;
        _createdOrderId = saved.createdOrderId;
      });

      if (saved.onlinePaymentInitData != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final cubit = context.read<OrderSessionCubit>();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: OnlinePaymentQrScreen(
                  initData: saved.onlinePaymentInitData!,
                  orderType: _normalizeOrderType(widget.orderType),

                  tableNumber: widget.tableNumber,
                  customerName: widget.customerName ?? 'Guest',
                  sessionId: _sessionId,
                ),
              ),
            ),
          );
        });
      } else if (saved.cashTransaction != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final cubit = context.read<OrderSessionCubit>();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: CashApprovalWaitingScreen(
                  transaction: saved.cashTransaction!,
                  branchId: _branchId,
                  orderType: _normalizeOrderType(widget.orderType),

                  tableNumber: widget.tableNumber,
                  sessionId: _sessionId,
                ),
              ),
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PosOrderBloc, PosOrderState>(
          listener: (context, state) {
            if (state is PosOrderCreated) {
              setState(() => _createdOrderId = state.order.orderId);
              context.read<OrderSessionCubit>().markOrderCreated(
                state.order.orderId,
              );
              _processPayment();
            } else if (state is PosOrderError) {
              _dismissLoading();
              context.read<OrderSessionCubit>().markPaymentError(state.error);
              _showSnack(state.error, Colors.red);
            }
          },
        ),
        BlocListener<PaymentBloc, PaymentState>(
          listener: (context, state) {
            final cubit = context.read<OrderSessionCubit>();

            if (state is CashPaymentPendingApproval) {
              cubit.markCashPendingApproval(transaction: state.transaction);
              _dismissLoading();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: CashApprovalWaitingScreen(
                      transaction: state.transaction,
                      branchId: _branchId,
                      orderType: widget.orderType,
                      tableNumber: widget.tableNumber,
                      sessionId: _sessionId,
                    ),
                  ),
                ),
              );
            } else if (state is OnlinePaymentInitialized) {
              cubit.markOnlinePaymentInitialized(initData: state.initData);
              _dismissLoading();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: OnlinePaymentQrScreen(
                      initData: state.initData,
                      orderType: widget.orderType,
                      tableNumber: widget.tableNumber,
                      customerName: widget.customerName ?? 'Guest',
                      sessionId: _sessionId,
                    ),
                  ),
                ),
              );
            } else if (state is PaymentError) {
              cubit.markPaymentError(state.error);
              _dismissLoading();
              _showSnack(state.error, Colors.red);
            }
          },
        ),
      ],
      child: DefaultTextStyle.merge(
        style: WorkSansAppTextStyles.medium,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F6F6),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Payment',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            centerTitle: true,
            actions: [
              MinimizeButton(
                sessionId: _sessionId,
                screen: MinimizedScreen.paymentMethod,
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(w),
                          _buildOptions(w),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(w),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double w) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: _hp(w), vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Payment Method',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: w < 360
                  ? 15
                  : w < 600
                  ? 16
                  : 17,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total: ₦${widget.totalAmount.toStringAsFixed(2)}',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(double w) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _hp(w), vertical: 20),
      child: Column(
        children: _options
            .map(
              (opt) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildOptionCard(opt, w),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildOptionCard(_PaymentMethodOption opt, double w) {
    final selected = _selectedMethod == opt.method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = opt.method),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(_cp(w)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kPrimary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? kPrimary.withOpacity(0.08)
                  : Colors.black.withOpacity(0.04),
              blurRadius: selected ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? kPrimary : kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                opt.icon,
                color: selected ? Colors.white : kPrimary,
                size: w < 360 ? 22 : 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opt.title,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: w < 360 ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    opt.subtitle,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: w < 360 ? 11 : 12,
                      color: kprimaryTextColor2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? kPrimary : Colors.grey[350]!,
                  width: 2,
                ),
                color: selected ? kPrimary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(double w) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _hp(w), vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  backgroundColor: Colors.grey[100],
                  padding: EdgeInsets.symmetric(vertical: w < 360 ? 13 : 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: w < 360 ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _selectedMethod != null ? _handleProcessOrder : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: EdgeInsets.symmetric(vertical: w < 360 ? 13 : 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Process Order',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: w < 360 ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: _selectedMethod != null
                        ? Colors.white
                        : Colors.grey[500],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleProcessOrder() {
    if (_selectedMethod == null) return;
    if (_selectedMethod == _PaymentMethod.cardOrBankTransfer) {
      // _showEmailDialog();
      _createOrderAndPay();
    } else {
      _createOrderAndPay();
    }
  }

  void _showEmailDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Customer Email',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: kprimaryTextColor1,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'An email address is required for card/bank transfer payments.',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 13,
                  color: kprimaryTextColor2,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'customer@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kPrimary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor2,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                _customerEmail = emailController.text.trim();
                Navigator.of(ctx).pop();
                _createOrderAndPay();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Continue',
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

  String _normalizeOrderType(String orderType) {
    switch (orderType.toLowerCase().trim().replaceAll(' ', '_')) {
      case 'dine_in':
      case 'dinein':
      case 'dine-in':
        return 'DINE_IN';
      case 'take_out':
      case 'takeout':
      case 'take-out':
      case 'to_go':
      case 'togo':
        return 'TAKE_OUT';
      case 'delivery':
        return 'DELIVERY';
      default:
        return orderType.toUpperCase().replaceAll(' ', '_');
    }
  }

  void _createOrderAndPay() {
    _showLoading('Creating order…');

    context.read<OrderSessionCubit>().markPaymentStarted(
      method: _selectedMethod == _PaymentMethod.cash
          ? PaymentMethod.cash
          : PaymentMethod.cardOrBankTransfer,
    );

    final items = widget.orderItems.entries.map((e) {
      return PosOrderItemPayload(
        menuItemId: e.key.id,
        quantity: e.value,
        specialRequest: widget.specialRequests[e.key.id],
      );
    }).toList();
    AppLogger.log(widget.orderType);
    context.read<PosOrderBloc>().add(
      CreatePosOrder(
        orderType: _normalizeOrderType(widget.orderType),
        tableNumber: widget.tableNumber,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        items: items,
        discount: widget.discount,
        specialInstructions: widget.specialInstructions,
      ),
    );
  }

  Future<void> _processPayment() async {
    _dismissLoading();
    _showLoading('Processing payment…');
    AppLogger.log('=== PROCESS PAYMENT ===');
    AppLogger.log('orderType: ${widget.orderType}');
    AppLogger.log('createdOrderId: $_createdOrderId');
    AppLogger.log('selectedMethod: $_selectedMethod');
    if (_branchId.isEmpty) {
      _branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    }

    if (_selectedMethod == _PaymentMethod.cash) {
      context.read<PaymentBloc>().add(
        RecordCashPayment(
          request: CashPaymentRequest(
            amount: widget.totalAmount,
            customerName: widget.customerName ?? 'Guest',
            branchId: _branchId,
            customerPhone: widget.customerPhone,
            orderId: _createdOrderId,
            description: 'Cash payment for Order #$_createdOrderId',
            sessionId: '',
          ),
        ),
      );
    } else {
      context.read<PaymentBloc>().add(
        InitializeOnlinePayment(
          request: OnlinePaymentRequest(
            amount: widget.totalAmount,
            customerName: widget.customerName ?? 'Guest',
            email: _customerEmail ?? 'customer@gmail.com',
            branchId: _branchId,
            customerPhone: widget.customerPhone,
            orderId: _createdOrderId,
            description: 'Payment for Order #$_createdOrderId',
            sessionId: '',
          ),
        ),
      );
    }
  }

  void _showLoading(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: kPrimary),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _dismissLoading() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: WorkSansAppTextStyles.medium),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  double _hp(double w) {
    if (w < 360) return 16;
    if (w < 600) return 20;
    if (w < 900) return 24;
    return 32;
  }

  double _cp(double w) {
    if (w < 360) return 14;
    if (w < 600) return 16;
    if (w < 900) return 18;
    return 20;
  }
}
