import 'package:sandwich_ai/src/core/config/feature_registry.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/app_environment.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/globals/notifications/local_notification.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_cubit.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/customer_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/order_session_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/payment_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/customer_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_order_repo.dart';
import 'package:sandwich_ai/src/features/pos/presentation/cash_approval_waiting.dart';
import 'package:sandwich_ai/src/features/pos/presentation/minimze.dart';
import 'package:sandwich_ai/src/features/pos/presentation/online_qr.dart';
import 'package:sandwich_ai/src/features/pos/presentation/rich_email_editor.dart';

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
  final String? existingOrderId;
  final String? existingOrderNumber;

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
    this.existingOrderId,
    this.existingOrderNumber,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  _PaymentMethod? _selectedMethod;
  String? _createdOrderId;
  String _branchId = '';
  String? _customerEmail;
  String? _emailSubject;
  String? _emailHtmlBody;
  String? _mainOrderId;

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
    _mainOrderId = widget.existingOrderId;
    _createdOrderId = widget.existingOrderNumber;
    _sessionId =
        widget.sessionId ??
        context.read<OrderSessionCubit>().state.activeSession?.sessionId;
    if (!_isExistingOrderPayment) {
      _restorePaymentState();
    }
  }

  bool get _isExistingOrderPayment =>
      widget.existingOrderId != null && widget.existingOrderId!.isNotEmpty;

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
                  orderId: _mainOrderId ?? '',
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
                  orderId: _mainOrderId ?? '',
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
              setState(() {
                _createdOrderId = state.order.orderId;
                _mainOrderId = state.order.id;
              });
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
              NotificationService().showNotification(
                id: state.transaction.hashCode + 9999,
                title: 'Order Placed',
                body: 'Cash order is awaiting manager approval',
                payload: 'cash_approval|$_createdOrderId',
                importance: NotificationImportance.high,
                priority: NotificationPriority.high,
              );
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
                      orderId: _mainOrderId,
                    ),
                  ),
                ),
              );
            } else if (state is OnlinePaymentInitialized) {
              cubit.markOnlinePaymentInitialized(initData: state.initData);
              _dismissLoading();
              NotificationService().showNotification(
                id: state.initData.hashCode + 9999,
                title: 'Payment Ready',
                body: 'QR code is ready for Order #$_createdOrderId',
                payload: 'online_payment|$_createdOrderId',
                importance: NotificationImportance.high,
                priority: NotificationPriority.high,
              );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: OnlinePaymentQrScreen(
                      orderId: _mainOrderId ?? '',
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
              icon: const AppIcon(Icons.arrow_back, color: Colors.black),
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
                  ? kPrimary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
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
                color: selected ? kPrimary : kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppIcon(
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
                  ? const AppIcon(Icons.check, color: Colors.white, size: 13)
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
            color: Colors.black.withValues(alpha: 0.05),
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

  Future<void> _handleProcessOrder() async {
    if (_selectedMethod == null) return;
    if (!FeatureRegistry.isEnabled(AppFeature.payment)) {
      _showSnack(
        AppEnvironment.current.disabledFeatureMessage(AppFeature.payment),
        Colors.red,
      );
      return;
    }
    if (_isExistingOrderPayment) {
      _payExistingOrder();
      return;
    }
    if (_selectedMethod == _PaymentMethod.cardOrBankTransfer) {
      final confirmed = await _showEmailComposer();
      if (!confirmed) return;
      _createOrderAndPay();
    } else {
      _createOrderAndPay();
    }
  }

  void _payExistingOrder() {
    if (_mainOrderId == null || _mainOrderId!.isEmpty) {
      _showSnack('Order ID is missing. Refresh and try again.', Colors.red);
      return;
    }

    _showLoading('Preparing payment...');
    _processPayment();
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
        confirmForKitchen: true,
      ),
    );
  }

  Future<void> _processPayment() async {
    _dismissLoading();
    if (!FeatureRegistry.isEnabled(AppFeature.payment)) {
      _showSnack(
        AppEnvironment.current.disabledFeatureMessage(AppFeature.payment),
        Colors.red,
      );
      return;
    }

    _showLoading('Processing payment…');
    AppLogger.log('=== PROCESS PAYMENT ===');
    AppLogger.log('orderType: ${widget.orderType}');
    AppLogger.log('createdOrderId: $_createdOrderId');
    AppLogger.log('selectedMethod: $_selectedMethod');
    if (_branchId.isEmpty) {
      _branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    }
    if (!mounted) return;

    if (_selectedMethod == _PaymentMethod.cash) {
      context.read<PaymentBloc>().add(
        RecordCashPayment(
          request: CashPaymentRequest(
            amount: widget.totalAmount,
            customerName: widget.customerName ?? 'Guest',
            branchId: _branchId,
            customerPhone: widget.customerPhone,
            orderId: _mainOrderId,
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
            orderId: _mainOrderId,
            description: 'Payment for Order #$_createdOrderId',
            sessionId: '',
            metadata: _emailMetadata,
          ),
        ),
      );
    }
  }

  Map<String, dynamic>? get _emailMetadata {
    final subject = _emailSubject?.trim();
    final htmlBody = _emailHtmlBody?.trim();

    if ((subject == null || subject.isEmpty) &&
        (htmlBody == null || htmlBody.isEmpty)) {
      return null;
    }

    return {
      if (subject != null && subject.isNotEmpty) 'emailSubject': subject,
      if (htmlBody != null && htmlBody.isNotEmpty) 'emailHtmlBody': htmlBody,
    };
  }

  Future<bool> _showEmailComposer() async {
    final result = await showDialog<_EmailComposerResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _EmailComposerDialog(
        initialEmail: _customerEmail,
        initialSubject:
            _emailSubject ??
            (_createdOrderId == null
                ? 'Payment instructions'
                : 'Payment for Order #$_createdOrderId'),
        initialHtmlBody: _emailHtmlBody,
      ),
    );

    if (result == null) return false;
    setState(() {
      _customerEmail = result.email;
      _emailSubject = result.subject;
      _emailHtmlBody = result.htmlBody;
    });
    return true;
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

class _EmailComposerResult {
  const _EmailComposerResult({
    required this.email,
    required this.subject,
    required this.htmlBody,
  });

  final String email;
  final String subject;
  final String htmlBody;
}

class _EmailComposerDialog extends StatefulWidget {
  const _EmailComposerDialog({
    required this.initialEmail,
    required this.initialSubject,
    required this.initialHtmlBody,
  });

  final String? initialEmail;
  final String initialSubject;
  final String? initialHtmlBody;

  @override
  State<_EmailComposerDialog> createState() => _EmailComposerDialogState();
}

class _EmailComposerDialogState extends State<_EmailComposerDialog> {
  final _formKey = GlobalKey<FormState>();
  final CustomerRepositoryInterface _customerRepository = CustomerRepository();
  late final TextEditingController _emailController;
  late final TextEditingController _subjectController;
  late String _htmlBody;
  Timer? _customerSearchDebounce;
  List<CustomerModel> _customerMatches = [];
  bool _isSearchingCustomers = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _subjectController = TextEditingController(text: widget.initialSubject);
    _emailController.addListener(_queueCustomerSearch);
    _htmlBody =
        widget.initialHtmlBody ??
        '<p>Hello,</p>\n<p>Please complete your payment using the secure payment link.</p>';
  }

  @override
  void dispose() {
    _customerSearchDebounce?.cancel();
    _emailController.removeListener(_queueCustomerSearch);
    _emailController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _queueCustomerSearch() {
    final query = _emailController.text.trim();
    _customerSearchDebounce?.cancel();

    if (query.length < 2) {
      if (_customerMatches.isNotEmpty || _isSearchingCustomers) {
        setState(() {
          _customerMatches = [];
          _isSearchingCustomers = false;
        });
      }
      return;
    }

    _customerSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchCustomers(query);
    });
  }

  Future<void> _searchCustomers(String query) async {
    if (!mounted) return;
    setState(() => _isSearchingCustomers = true);

    final response = await _customerRepository.getCustomers(
      page: 1,
      limit: 6,
      search: query,
    );

    if (!mounted || _emailController.text.trim() != query) return;

    await response.when(
      success: (customersResponse) async {
        if (!mounted) return;
        setState(() {
          _customerMatches = customersResponse.data;
          _isSearchingCustomers = false;
        });
      },
      error: (_) async {
        if (!mounted) return;
        setState(() {
          _customerMatches = [];
          _isSearchingCustomers = false;
        });
      },
    );
  }

  void _selectCustomer(CustomerModel customer) {
    _customerSearchDebounce?.cancel();
    setState(() {
      _emailController.text = customer.email;
      _customerMatches = [];
      _isSearchingCustomers = false;
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final htmlBody = _htmlBody.trim();
    if (htmlBody.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Email body is required',
            style: WorkSansAppTextStyles.medium,
          ),
          backgroundColor: context.modeError,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _EmailComposerResult(
        email: _emailController.text.trim(),
        subject: _subjectController.text.trim(),
        htmlBody: htmlBody,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Dialog(
      backgroundColor: context.modeSurface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: width < 520 ? 14 : 32,
        vertical: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Email Message',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.modeTextPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: AppIcon(
                        Icons.close,
                        color: context.modeTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  cursorColor: context.modePrimary,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    color: context.modeTextPrimary,
                  ),
                  decoration: _inputDecoration(context, 'Recipient email'),
                ),
                _CustomerSearchResults(
                  isLoading: _isSearchingCustomers,
                  customers: _customerMatches,
                  onSelect: _selectCustomer,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subjectController,
                  cursorColor: context.modePrimary,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    color: context.modeTextPrimary,
                  ),
                  decoration: _inputDecoration(context, 'Subject'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Subject is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                RichEmailEditor(
                  initialHtml: _htmlBody,
                  onHtmlChanged: (value) => _htmlBody = value,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.modeTextPrimary,
                          side: BorderSide(color: context.modeBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const AppIcon(Icons.check, size: 18),
                        label: const Text('Continue'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.modePrimary,
                          foregroundColor: context.modeTextInverse,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: WorkSansAppTextStyles.medium.copyWith(
        color: context.modeTextSecondary,
      ),
      filled: true,
      fillColor: context.modeSurfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.modeBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.modeBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.modePrimary),
      ),
    );
  }
}

class _CustomerSearchResults extends StatelessWidget {
  const _CustomerSearchResults({
    required this.isLoading,
    required this.customers,
    required this.onSelect,
  });

  final bool isLoading;
  final List<CustomerModel> customers;
  final ValueChanged<CustomerModel> onSelect;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && customers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder),
      ),
      child: isLoading
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.modePrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Searching customers...',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: context.modeTextSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customers.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: context.modeBorder),
              itemBuilder: (context, index) {
                final customer = customers[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: context.modePrimary.withValues(
                      alpha: 0.12,
                    ),
                    child: Text(
                      customer.name.isEmpty
                          ? '?'
                          : customer.name.characters.first.toUpperCase(),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        color: context.modePrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    customer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.modeTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    customer.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 12,
                      color: context.modeTextSecondary,
                    ),
                  ),
                  onTap: () => onSelect(customer),
                );
              },
            ),
    );
  }
}
