// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
// import 'package:sandwich_ai/src/core/constant/textstyle.dart';
// import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/bloc.dart';
// import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/event.dart';
// import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/state.dart';
// import 'package:sandwich_ai/src/features/pos/data/model/payment_model.dart';
// import 'package:sandwich_ai/src/features/pos/presentation/recietp.dart';

// class ApprovalWaitingScreen extends StatefulWidget {
//   final PaymentResponseModel initialPaymentResponse;
//   final String orderType;
//   final String? tableNumber;

//   const ApprovalWaitingScreen({
//     super.key,
//     required this.initialPaymentResponse,
//     required this.orderType,
//     this.tableNumber,
//   });

//   @override
//   State<ApprovalWaitingScreen> createState() => _ApprovalWaitingScreenState();
// }

// class _ApprovalWaitingScreenState extends State<ApprovalWaitingScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _pulseController;
//   late AnimationController _rotationController;
//   late Animation<double> _pulseAnimation;

//   @override
//   void initState() {
//     super.initState();

//     // Pulse animation for waiting indicator
//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);

//     _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );

//     // Rotation animation for clock icon
//     _rotationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     )..repeat();

//     // Start polling for approval status
//     _startPollingApprovalStatus();
//   }

//   @override
//   void dispose() {
//     _pulseController.dispose();
//     _rotationController.dispose();
//     super.dispose();
//   }

//   void _startPollingApprovalStatus() {
//     // Poll every 3 seconds to check approval status
//     Future.delayed(const Duration(seconds: 3), () {
//       if (mounted) {
//         context.read<PaymentBloc>().add(
//           CheckPaymentApprovalStatus(
//             paymentId: widget.initialPaymentResponse.data.payment.paymentId,
//           ),
//         );
//         _startPollingApprovalStatus();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<PaymentBloc, PaymentState>(
//       listener: (context, state) {
//         if (state is PaymentApprovalApproved) {
//           // Payment approved, navigate to receipt
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(
//               builder: (context) => ReceiptScreen(
//                 paymentResponse: state.paymentResponse,
//                 orderType: widget.orderType,
//                 tableNumber: widget.tableNumber,
//               ),
//             ),
//           );
//         } else if (state is PaymentApprovalRejected) {
//           // Payment rejected, show dialog
//           _showRejectionDialog(state.rejectionReason);
//         } else if (state is PaymentError) {
//           // Error checking status
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Error: ${state.error}'),
//               backgroundColor: Colors.orange,
//               duration: const Duration(seconds: 3),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           );
//         }
//       },
//       child: WillPopScope(
//         onWillPop: () async {
//           // Show confirmation dialog before leaving
//           return await _showExitConfirmationDialog() ?? false;
//         },
//         child: Scaffold(
//           backgroundColor: const Color(0xFFF8F6F6),
//           body: SafeArea(
//             child: LayoutBuilder(
//               builder: (context, constraints) {
//                 return Center(
//                   child: SingleChildScrollView(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: _getHorizontalPadding(constraints.maxWidth),
//                       vertical: 24,
//                     ),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         _buildAnimatedIcon(),
//                         const SizedBox(height: 32),
//                         _buildTitle(constraints.maxWidth),
//                         const SizedBox(height: 16),
//                         _buildMessage(constraints.maxWidth),
//                         const SizedBox(height: 40),
//                         _buildPaymentDetails(constraints.maxWidth),
//                         const SizedBox(height: 40),
//                         _buildWaitingIndicator(),
//                         const SizedBox(height: 32),
//                         _buildActionButtons(constraints.maxWidth),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAnimatedIcon() {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         // Pulsing circle background
//         ScaleTransition(
//           scale: _pulseAnimation,
//           child: Container(
//             width: 120,
//             height: 120,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: kPrimary.withValues(alpha: 0.1),
//             ),
//           ),
//         ),
//         // Rotating clock icon
//         RotationTransition(
//           turns: _rotationController,
//           child: Container(
//             width: 80,
//             height: 80,
//             decoration: const BoxDecoration(
//               shape: BoxShape.circle,
//               color: kPrimary,
//             ),
//             child: const Icon(Icons.access_time, size: 40, color: Colors.white),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTitle(double screenWidth) {
//     return Text(
//       'Awaiting Approval',
//       textAlign: TextAlign.center,
//       style: WorkSansAppTextStyles.medium.copyWith(
//         fontSize: _getTitleTextSize(screenWidth),
//         fontWeight: FontWeight.w700,
//         color: kprimaryTextColor1,
//       ),
//     );
//   }

//   Widget _buildMessage(double screenWidth) {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: _getHorizontalPadding(screenWidth),
//       ),
//       child: Text(
//         'Your cash payment is pending manager approval. Please wait while we verify the transaction.',
//         textAlign: TextAlign.center,
//         style: WorkSansAppTextStyles.medium.copyWith(
//           fontSize: _getBodyTextSize(screenWidth),
//           color: kprimaryTextColor2,
//           height: 1.5,
//         ),
//       ),
//     );
//   }

//   Widget _buildPaymentDetails(double screenWidth) {
//     final payment = widget.initialPaymentResponse.data.payment;

//     return Container(
//       margin: EdgeInsets.symmetric(
//         horizontal: _getHorizontalPadding(screenWidth),
//       ),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Payment Details',
//             style: WorkSansAppTextStyles.medium.copyWith(
//               fontSize: _getBodyTextSize(screenWidth),
//               fontWeight: FontWeight.w600,
//               color: kprimaryTextColor1,
//             ),
//           ),
//           const SizedBox(height: 16),
//           _buildDetailRow('Payment ID', payment.paymentId, screenWidth),
//           const SizedBox(height: 12),
//           _buildDetailRow('Customer', payment.customerName, screenWidth),
//           const SizedBox(height: 12),
//           _buildDetailRow(
//             'Amount',
//             '₦${double.parse(payment.amount).toStringAsFixed(2)}',
//             screenWidth,
//             isAmount: true,
//           ),
//           const SizedBox(height: 12),
//           _buildDetailRow('Payment Method', payment.paymentMethod, screenWidth),
//           const SizedBox(height: 12),
//           _buildDetailRow(
//             'Status',
//             payment.approvalStatus ?? 'PENDING',
//             screenWidth,
//             isStatus: true,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(
//     String label,
//     String value,
//     double screenWidth, {
//     bool isAmount = false,
//     bool isStatus = false,
//   }) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: WorkSansAppTextStyles.medium.copyWith(
//             fontSize: _getDetailTextSize(screenWidth),
//             color: kprimaryTextColor2,
//           ),
//         ),
//         Text(
//           value,
//           style: WorkSansAppTextStyles.medium.copyWith(
//             fontSize: _getDetailTextSize(screenWidth),
//             fontWeight: isAmount || isStatus
//                 ? FontWeight.w700
//                 : FontWeight.w600,
//             color: isAmount
//                 ? kPrimary
//                 : isStatus
//                 ? Colors.orange
//                 : kprimaryTextColor1,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildWaitingIndicator() {
//     return Column(
//       children: [
//         const SizedBox(
//           width: 24,
//           height: 24,
//           child: CircularProgressIndicator(
//             strokeWidth: 3,
//             valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
//           ),
//         ),
//         const SizedBox(height: 12),
//         Text(
//           'Checking approval status...',
//           style: WorkSansAppTextStyles.medium.copyWith(
//             fontSize: 13,
//             color: kprimaryTextColor2,
//             fontStyle: FontStyle.italic,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButtons(double screenWidth) {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: _getHorizontalPadding(screenWidth),
//       ),
//       child: Column(
//         children: [
//           // Refresh button
//           SizedBox(
//             width: double.infinity,
//             child: OutlinedButton.icon(
//               onPressed: () {
//                 context.read<PaymentBloc>().add(
//                   CheckPaymentApprovalStatus(
//                     paymentId:
//                         widget.initialPaymentResponse.data.payment.paymentId,
//                   ),
//                 );
//               },
//               icon: const Icon(Icons.refresh, size: 20),
//               label: Text(
//                 'Refresh Status',
//                 style: WorkSansAppTextStyles.medium.copyWith(
//                   fontSize: _getButtonTextSize(screenWidth),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: kPrimary,
//                 side: const BorderSide(color: kPrimary, width: 2),
//                 padding: EdgeInsets.symmetric(
//                   vertical: _getButtonVerticalPadding(screenWidth),
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           // Back to orders button
//           SizedBox(
//             width: double.infinity,
//             child: TextButton(
//               onPressed: () async {
//                 final shouldExit = await _showExitConfirmationDialog();
//                 if (shouldExit == true && mounted) {
//                   Navigator.of(context).popUntil((route) => route.isFirst);
//                 }
//               },
//               style: TextButton.styleFrom(
//                 foregroundColor: kprimaryTextColor2,
//                 padding: EdgeInsets.symmetric(
//                   vertical: _getButtonVerticalPadding(screenWidth),
//                 ),
//               ),
//               child: Text(
//                 'Back to Orders',
//                 style: WorkSansAppTextStyles.medium.copyWith(
//                   fontSize: _getButtonTextSize(screenWidth),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<bool?> _showExitConfirmationDialog() {
//     return showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Text(
//           'Leave This Screen?',
//           style: WorkSansAppTextStyles.medium.copyWith(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         content: Text(
//           'Your payment is still pending approval. You can check the status later in the payments section.',
//           style: WorkSansAppTextStyles.medium.copyWith(
//             fontSize: 14,
//             color: kprimaryTextColor2,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: Text(
//               'Stay Here',
//               style: WorkSansAppTextStyles.medium.copyWith(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: kprimaryTextColor2,
//               ),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: kPrimary,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: Text(
//               'Leave',
//               style: WorkSansAppTextStyles.medium.copyWith(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showRejectionDialog(String? reason) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             const Icon(Icons.cancel, color: Colors.red, size: 28),
//             const SizedBox(width: 12),
//             Text(
//               'Payment Rejected',
//               style: WorkSansAppTextStyles.medium.copyWith(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//         content: Text(
//           reason ??
//               'The manager has rejected this payment. Please contact your manager for more details.',
//           style: WorkSansAppTextStyles.medium.copyWith(
//             fontSize: 14,
//             color: kprimaryTextColor2,
//           ),
//         ),
//         actions: [
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               Navigator.of(context).popUntil((route) => route.isFirst);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: Text(
//               'Back to Orders',
//               style: WorkSansAppTextStyles.medium.copyWith(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Responsive sizing functions
//   double _getHorizontalPadding(double width) {
//     if (width < 360) return 16;
//     if (width < 600) return 20;
//     if (width < 900) return 24;
//     return 32;
//   }

//   double _getTitleTextSize(double width) {
//     if (width < 360) return 22;
//     if (width < 600) return 24;
//     if (width < 900) return 26;
//     return 28;
//   }

//   double _getBodyTextSize(double width) {
//     if (width < 360) return 14;
//     if (width < 600) return 15;
//     if (width < 900) return 16;
//     return 17;
//   }

//   double _getDetailTextSize(double width) {
//     if (width < 360) return 13;
//     if (width < 600) return 14;
//     if (width < 900) return 15;
//     return 16;
//   }

//   double _getButtonTextSize(double width) {
//     if (width < 360) return 14;
//     if (width < 600) return 15;
//     if (width < 900) return 16;
//     return 17;
//   }

//   double _getButtonVerticalPadding(double width) {
//     if (width < 360) return 14;
//     if (width < 600) return 16;
//     if (width < 900) return 18;
//     return 20;
//   }
// }
