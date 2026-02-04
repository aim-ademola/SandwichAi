import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/state.dart';

import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/payment_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_order_repo.dart';
import 'package:sandwich_ai/src/features/pos/presentation/recietp.dart';

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
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  PaymentMethod? _selectedPaymentMethod;
  String? _createdOrderId;

  // Bank Transfer Form Controllers
  final _bankReferenceController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _bankReferenceController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  final List<PaymentMethodOption> _paymentMethods = [
    PaymentMethodOption(
      method: PaymentMethod.cash,
      title: 'Cash',
      icon: Icons.account_balance_wallet_outlined,
    ),
    PaymentMethodOption(
      method: PaymentMethod.bankTransfer,
      title: 'Bank Transfer',
      icon: Icons.account_balance,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen to POS Order creation
        BlocListener<PosOrderBloc, PosOrderState>(
          listener: (context, state) {
            if (state is PosOrderCreated) {
              // Order created successfully, save order ID and proceed to payment
              setState(() {
                _createdOrderId = state.order.orderId;
              });
              _processPayment();
            } else if (state is PosOrderError) {
              // Close loading dialog if showing
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              // Show error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        ),
        // Listen to Payment processing
        BlocListener<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentSuccess) {
              // Close loading dialog
              Navigator.of(context).pop();
              // Navigate to receipt screen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ReceiptScreen(
                    paymentResponse: state.paymentResponse,
                    orderType: widget.orderType,
                    tableNumber: widget.tableNumber,
                  ),
                ),
              );
            } else if (state is PaymentError) {
              // Close loading dialog if showing
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              // Show error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
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
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(constraints.maxWidth),
                          _buildPaymentOptions(constraints.maxWidth),
                          if (_selectedPaymentMethod ==
                              PaymentMethod.bankTransfer)
                            _buildBankTransferForm(constraints.maxWidth),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomActions(constraints.maxWidth),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    final horizontalPadding = _getHorizontalPadding(screenWidth);
    final headerTextSize = _getHeaderTextSize(screenWidth);

    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a Payment Method',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: headerTextSize,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Amount: ₦${widget.totalAmount.toStringAsFixed(2)}',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions(double screenWidth) {
    final horizontalPadding = _getHorizontalPadding(screenWidth);
    final verticalSpacing = _getVerticalSpacing(screenWidth);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalSpacing * 1.5,
      ),
      child: Column(
        children: _paymentMethods
            .map(
              (option) => Padding(
                padding: EdgeInsets.only(bottom: verticalSpacing),
                child: _buildPaymentMethodCard(option, screenWidth),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    PaymentMethodOption option,
    double screenWidth,
  ) {
    final isSelected = _selectedPaymentMethod == option.method;
    final textSize = _getBodyTextSize(screenWidth);
    final iconSize = _getIconSize(screenWidth);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = option.method;
          // Clear bank transfer form when switching payment methods
          if (option.method != PaymentMethod.bankTransfer) {
            _bankReferenceController.clear();
            _accountNumberController.clear();
            _bankNameController.clear();
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(_getCardPadding(screenWidth)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kPrimary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: EdgeInsets.all(_getIconPadding(screenWidth)),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(option.icon, color: Colors.white, size: iconSize),
            ),
            SizedBox(width: _getIconTextSpacing(screenWidth)),
            // Title
            Expanded(
              child: Text(
                option.title,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  color: kprimaryTextColor1,
                ),
              ),
            ),
            // Selection indicator
            Container(
              width: _getRadioSize(screenWidth),
              height: _getRadioSize(screenWidth),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? kPrimary : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? kPrimary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: _getRadioSize(screenWidth) * 0.6,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankTransferForm(double screenWidth) {
    final horizontalPadding = _getHorizontalPadding(screenWidth);
    final verticalSpacing = _getVerticalSpacing(screenWidth);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      padding: EdgeInsets.all(_getCardPadding(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Transfer Details',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getBodyTextSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            SizedBox(height: verticalSpacing),

            // Bank Reference
            TextFormField(
              controller: _bankReferenceController,
              decoration: InputDecoration(
                labelText: 'Bank Reference *',
                labelStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kprimaryTextColor2,
                ),
                hintText: 'e.g., TRF123456789',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kPrimary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bank reference is required';
                }
                return null;
              },
            ),
            SizedBox(height: verticalSpacing),

            // Account Number (optional)
            TextFormField(
              controller: _accountNumberController,
              decoration: InputDecoration(
                labelText: 'Sender Account Number (Optional)',
                labelStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kprimaryTextColor2,
                ),
                hintText: 'e.g., 1234567890',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kPrimary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: verticalSpacing),

            // Bank Name (optional)
            TextFormField(
              controller: _bankNameController,
              decoration: InputDecoration(
                labelText: 'Sender Bank (Optional)',
                labelStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kprimaryTextColor2,
                ),
                hintText: 'e.g., GTBank',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kPrimary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(double screenWidth) {
    final horizontalPadding = _getHorizontalPadding(screenWidth);
    final buttonTextSize = _getButtonTextSize(screenWidth);
    final buttonPadding = _getButtonVerticalPadding(screenWidth);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16,
      ),
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
            // Cancel button
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleCancel(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  backgroundColor: Colors.grey[100],
                  padding: EdgeInsets.symmetric(vertical: buttonPadding),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: buttonTextSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Process payment button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _selectedPaymentMethod != null
                    ? () => _handleProcessOrder()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  padding: EdgeInsets.symmetric(vertical: buttonPadding),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Process Order',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: buttonTextSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  void _handleProcessOrder() {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate bank transfer form if selected
    if (_selectedPaymentMethod == PaymentMethod.bankTransfer) {
      if (_formKey.currentState?.validate() != true) {
        return;
      }
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: kPrimary),
                const SizedBox(height: 16),
                Text(
                  'Creating order...',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Create order first
    final orderItemsPayload = widget.orderItems.entries.map((entry) {
      final item = entry.key;
      final quantity = entry.value;

      return PosOrderItemPayload(
        menuItemId: item.id,
        quantity: quantity,
        specialRequest: widget.specialRequests[item.id],
      );
    }).toList();

    context.read<PosOrderBloc>().add(
      CreatePosOrder(
        orderType: widget.orderType,
        tableNumber: widget.tableNumber,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        items: orderItemsPayload,
        discount: widget.discount,
        specialInstructions: widget.specialInstructions,
      ),
    );
  }

  Future<void> _processPayment() async {
    // Update loading dialog
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: kPrimary),
                const SizedBox(height: 16),
                Text(
                  'Processing payment...',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final branchId = await AuthCacheHelper.instance.getBranchID() ?? '';

    if (_selectedPaymentMethod == PaymentMethod.cash) {
      final request = CashPaymentRequest(
        amount: widget.totalAmount,
        customerName: widget.customerName ?? 'Guest',
        branchId: branchId,
        customerPhone: widget.customerPhone,
        orderId: _createdOrderId,
        description: 'Cash payment for Order #$_createdOrderId',
      );

      context.read<PaymentBloc>().add(ProcessCashPayment(request: request));
    } else if (_selectedPaymentMethod == PaymentMethod.bankTransfer) {
      final request = BankTransferPaymentRequest(
        amount: widget.totalAmount,
        customerName: widget.customerName ?? 'Guest',
        branchId: branchId,
        bankReference: _bankReferenceController.text.trim(),
        senderAccountNumber: _accountNumberController.text.trim().isNotEmpty
            ? _accountNumberController.text.trim()
            : null,
        senderBank: _bankNameController.text.trim().isNotEmpty
            ? _bankNameController.text.trim()
            : null,
        customerPhone: widget.customerPhone,
        orderId: _createdOrderId,
        description: 'Bank transfer for Order #$_createdOrderId',
      );

      context.read<PaymentBloc>().add(
        ProcessBankTransferPayment(request: request),
      );
    }
  }

  // Responsive sizing functions
  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 24;
    return 32;
  }

  double _getVerticalSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    if (width < 900) return 16;
    return 18;
  }

  double _getCardPadding(double width) {
    if (width < 360) return 14;
    if (width < 600) return 16;
    if (width < 900) return 18;
    return 20;
  }

  double _getIconPadding(double width) {
    if (width < 360) return 10;
    if (width < 600) return 12;
    if (width < 900) return 14;
    return 16;
  }

  double _getHeaderTextSize(double width) {
    if (width < 360) return 16;
    if (width < 600) return 17;
    if (width < 900) return 18;
    return 19;
  }

  double _getBodyTextSize(double width) {
    if (width < 360) return 15;
    if (width < 600) return 16;
    if (width < 900) return 17;
    return 18;
  }

  double _getIconSize(double width) {
    if (width < 360) return 22;
    if (width < 600) return 24;
    if (width < 900) return 26;
    return 28;
  }

  double _getRadioSize(double width) {
    if (width < 360) return 22;
    if (width < 600) return 24;
    if (width < 900) return 26;
    return 28;
  }

  double _getIconTextSpacing(double width) {
    if (width < 360) return 14;
    if (width < 600) return 16;
    if (width < 900) return 18;
    return 20;
  }

  double _getButtonTextSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    if (width < 900) return 16;
    return 17;
  }

  double _getButtonVerticalPadding(double width) {
    if (width < 360) return 14;
    if (width < 600) return 16;
    if (width < 900) return 18;
    return 20;
  }
}

// Data models
enum PaymentMethod { cash, card, bankTransfer, digitalWallet }

class PaymentMethodOption {
  final PaymentMethod method;
  final String title;
  final IconData icon;

  PaymentMethodOption({
    required this.method,
    required this.title,
    required this.icon,
  });
}
