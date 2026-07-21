import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_cubit.dart';
import 'package:sandwich_ai/src/features/pos/data/model/payment_model.dart';
import 'package:share_plus/share_plus.dart';

class OnlineReceiptScreen extends StatefulWidget {
  final OnlinePaymentStatusData statusData;
  final String orderType;
  final String? tableNumber;

  /// The session this payment belongs to. Used to mark it completed on Done.
  final String? sessionId;

  const OnlineReceiptScreen({
    super.key,
    required this.statusData,
    required this.orderType,
    this.tableNumber,
    this.sessionId,
  });

  @override
  State<OnlineReceiptScreen> createState() => _OnlineReceiptScreenState();
}

class _OnlineReceiptScreenState extends State<OnlineReceiptScreen>
    with SingleTickerProviderStateMixin {
  bool _isGeneratingPdf = false;
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  /// Mark session completed in cubit, close session after brief delay,
  /// then pop back to the very first route (OrderScreen).
  void _onDone() {
    if (widget.sessionId != null) {
      final cubit = context.read<OrderSessionCubit>();
      cubit.markSessionCompleted(widget.sessionId!);
      Future.delayed(const Duration(milliseconds: 800), () {
        cubit.closeSession(widget.sessionId!);
      });
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  String _formatAmount(String amount) {
    try {
      return 'â‚¦${double.parse(amount).toStringAsFixed(2)}';
    } catch (_) {
      return 'â‚¦$amount';
    }
  }

  String _formatDate(String dt) {
    try {
      final wat = DateTime.parse(dt).toUtc().add(const Duration(hours: 1));
      return DateFormat('MMM dd, yyyy â€¢ hh:mm a').format(wat);
    } catch (_) {
      return dt;
    }
  }

  String _orderTypeLabel(String type) {
    switch (type) {
      case 'DINE_IN':
        return 'Dine In';
      case 'TAKE_OUT':
        return 'Take Out';
      case 'DELIVERY':
        return 'Delivery';
      default:
        return type;
    }
  }

  String _cardInfo() {
    final meta = widget.statusData.metadata;
    if (meta == null) return '';
    final paystackData = meta['paystackData'] as Map<String, dynamic>?;
    if (paystackData == null) return '';
    final channel = paystackData['channel']?.toString() ?? '';
    return channel.isNotEmpty
        ? channel[0].toUpperCase() + channel.substring(1)
        : '';
  }

  String _receiptCardInfo() {
    final meta = widget.statusData.receipt?.metadata;
    if (meta == null) return '';
    final brand = meta['cardBrand']?.toString() ?? '';
    final last4 = meta['cardLast4']?.toString() ?? '';
    if (brand.isNotEmpty && last4.isNotEmpty) {
      return '${brand[0].toUpperCase()}${brand.substring(1)} â€¢â€¢â€¢â€¢ $last4';
    }
    return '';
  }

  Future<void> _downloadPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdf = await _buildPdf();
      final dir = await getApplicationDocumentsDirectory();
      final receiptNum =
          widget.statusData.receipt?.receiptNumber ??
          widget.statusData.reference;
      final file = File('${dir.path}/receipt_$receiptNum.pdf');
      await file.writeAsBytes(await pdf.save());
      setState(() => _isGeneratingPdf = false);
      await Share.shareXFiles([XFile(file.path)], text: 'Receipt $receiptNum');
      if (mounted) _showSnack('Receipt saved and ready to share', Colors.green);
    } catch (e) {
      setState(() => _isGeneratingPdf = false);
      if (mounted) _showSnack('Failed to generate PDF: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: WorkSansAppTextStyles.medium),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<pw.Document> _buildPdf() async {
    final d = widget.statusData;
    final receipt = d.receipt;
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'PAYMENT RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    receipt?.receiptNumber ?? d.reference,
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 28),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'âœ“  Payment Completed',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Customer Information',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.SizedBox(height: 6),
            _pdfRow('Name:', d.customerName),
            if (receipt?.customerPhone != null)
              _pdfRow('Phone:', receipt!.customerPhone!),
            if (receipt?.customerEmail != null)
              _pdfRow('Email:', receipt!.customerEmail!),
            pw.SizedBox(height: 20),
            pw.Text(
              'Order Information',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.SizedBox(height: 6),
            _pdfRow('Order Type:', _orderTypeLabel(widget.orderType)),
            if (widget.tableNumber != null)
              _pdfRow('Table:', widget.tableNumber!),
            pw.SizedBox(height: 20),
            pw.Text(
              'Payment Information',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.SizedBox(height: 6),
            _pdfRow('Reference:', d.reference),
            _pdfRow('Method:', d.paymentMethod),
            if (_cardInfo().isNotEmpty) _pdfRow('Channel:', _cardInfo()),
            if (_receiptCardInfo().isNotEmpty)
              _pdfRow('Card:', _receiptCardInfo()),
            if (receipt?.branch != null)
              _pdfRow('Branch:', receipt!.branch!.name),
            if (receipt?.organization != null)
              _pdfRow('Merchant:', receipt!.organization!.name),
            if (d.paidAt != null) _pdfRow('Paid At:', _formatDate(d.paidAt!)),
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Amount:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _formatAmount(d.amount),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 32),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  if (receipt?.issuedAt != null)
                    pw.Text(
                      'Issued: ${_formatDate(receipt!.issuedAt)}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return pdf;
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.statusData;
    final receipt = d.receipt;

    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Payment Receipt',
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
            final w = constraints.maxWidth;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: _hp(w), vertical: 24),
              child: Column(
                children: [
                  // Animated check
                  ScaleTransition(
                    scale: _checkAnimation,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const AppIcon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Payment Successful!',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: w < 360
                          ? 20
                          : w < 600
                          ? 22
                          : 24,
                      fontWeight: FontWeight.w700,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    receipt?.receiptNumber ?? d.reference,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Receipt card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Customer Information'),
                        const SizedBox(height: 12),
                        _infoRow('Name', d.customerName),
                        if (receipt?.customerPhone != null)
                          _infoRow('Phone', receipt!.customerPhone!),
                        if (receipt?.customerEmail != null)
                          _infoRow('Email', receipt!.customerEmail!),
                        const SizedBox(height: 18),

                        _sectionHeader('Order Information'),
                        const SizedBox(height: 12),
                        _infoRow(
                          'Order Type',
                          _orderTypeLabel(widget.orderType),
                        ),
                        if (widget.tableNumber != null)
                          _infoRow('Table', widget.tableNumber!),
                        const SizedBox(height: 18),

                        _sectionHeader('Payment Details'),
                        const SizedBox(height: 12),
                        _infoRow('Reference', d.reference),
                        _infoRow('Method', d.paymentMethod),
                        if (_cardInfo().isNotEmpty)
                          _infoRow('Channel', _cardInfo()),
                        if (_receiptCardInfo().isNotEmpty)
                          _infoRow('Card', _receiptCardInfo()),
                        if (receipt?.branch != null)
                          _infoRow('Branch', receipt!.branch!.name),
                        if (receipt?.organization != null)
                          _infoRow('Merchant', receipt!.organization!.name),
                        if (d.paidAt != null)
                          _infoRow('Paid At', _formatDate(d.paidAt!)),
                        const SizedBox(height: 18),

                        // Amount block
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: kprimaryTextColor1,
                                ),
                              ),
                              Text(
                                _formatAmount(d.amount),
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Thank you for your business!',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: kprimaryTextColor2,
                                ),
                              ),
                              if (receipt?.issuedAt != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Issued: ${_formatDate(receipt!.issuedAt)}',
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Download PDF
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingPdf ? null : _downloadPdf,
                      icon: _isGeneratingPdf
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const AppIcon(
                              Icons.download_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                      label: Text(
                        _isGeneratingPdf
                            ? 'Generating PDFâ€¦'
                            : 'Download Receipt',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Done â€” marks session completed
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: _onDone,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimary,
                        side: const BorderSide(color: kPrimary, width: 1.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: kprimaryTextColor1,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: kprimaryTextColor2,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
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
