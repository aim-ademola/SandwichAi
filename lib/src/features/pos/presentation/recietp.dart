import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sandwich_ai/src/features/pos/data/model/payment_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

class ReceiptScreen extends StatefulWidget {
  final PaymentResponseModel paymentResponse;
  final String orderType;
  final String? tableNumber;

  const ReceiptScreen({
    super.key,
    required this.paymentResponse,
    required this.orderType,
    this.tableNumber,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _isGeneratingPdf = false;

  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(dt);
    } catch (e) {
      return dateTime;
    }
  }

  String _formatPrice(String price) {
    try {
      final amount = double.parse(price);
      return '₦${amount.toStringAsFixed(2)}';
    } catch (e) {
      return '₦$price';
    }
  }

  String _getOrderTypeLabel(String orderType) {
    switch (orderType) {
      case 'DINE_IN':
        return 'Dine In';
      case 'TAKE_OUT':
        return 'Take Out';
      case 'DELIVERY':
        return 'Delivery';
      default:
        return orderType;
    }
  }

  Future<void> _downloadReceipt() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      // Generate PDF
      final pdf = await _generatePdf();

      // Get temporary directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/receipt_${widget.paymentResponse.data.receipt.receiptNumber}.pdf',
      );

      // Write PDF to file
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _isGeneratingPdf = false;
      });

      // Share the file
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Receipt ${widget.paymentResponse.data.receipt.receiptNumber}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt saved and ready to share'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingPdf = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    final receipt = widget.paymentResponse.data.receipt;
    final payment = widget.paymentResponse.data.payment;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'PAYMENT RECEIPT',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      receipt.receiptNumber,
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 32),

              // Payment Status
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      '✓ ',
                      style: pw.TextStyle(
                        fontSize: 24,
                        color: PdfColors.green,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Payment Completed',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Customer Information
              pw.Text(
                'Customer Information',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _buildPdfInfoRow('Name:', receipt.customerName),
              if (receipt.customerPhone != null)
                _buildPdfInfoRow('Phone:', receipt.customerPhone!),
              if (receipt.customerEmail != null)
                _buildPdfInfoRow('Email:', receipt.customerEmail!),
              pw.SizedBox(height: 24),

              // Order Information
              pw.Text(
                'Order Information',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _buildPdfInfoRow(
                'Order Type:',
                _getOrderTypeLabel(widget.orderType),
              ),
              if (widget.tableNumber != null)
                _buildPdfInfoRow('Table:', widget.tableNumber!),
              if (payment.orderId != null)
                _buildPdfInfoRow('Order ID:', payment.orderId!),
              pw.SizedBox(height: 24),

              // Payment Information
              pw.Text(
                'Payment Information',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _buildPdfInfoRow('Payment Method:', receipt.paymentMethod),
              _buildPdfInfoRow('Reference:', payment.reference),
              _buildPdfInfoRow('Status:', payment.status),
              if (payment.paidAt != null)
                _buildPdfInfoRow('Paid At:', _formatDateTime(payment.paidAt!)),
              pw.SizedBox(height: 24),

              // Amount
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
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
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _formatPrice(receipt.amount),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 32),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for your business!',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Issued: ${_formatDateTime(receipt.issuedAt)}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receipt = widget.paymentResponse.data.receipt;
    final payment = widget.paymentResponse.data.payment;

    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const SizedBox.shrink(),
          title: Text(
            'Receipt',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),

              // Success Message
              Text(
                'Payment Successful!',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kprimaryTextColor1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                receipt.receiptNumber,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                ),
              ),
              const SizedBox(height: 32),

              // Receipt Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Information
                    _buildSectionHeader('Customer Information'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Name', receipt.customerName),
                    if (receipt.customerPhone != null)
                      _buildInfoRow('Phone', receipt.customerPhone!),
                    if (receipt.customerEmail != null)
                      _buildInfoRow('Email', receipt.customerEmail!),
                    const SizedBox(height: 20),

                    // Order Information
                    _buildSectionHeader('Order Information'),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Order Type',
                      _getOrderTypeLabel(widget.orderType),
                    ),
                    if (widget.tableNumber != null)
                      _buildInfoRow('Table', widget.tableNumber!),
                    if (payment.orderId != null)
                      _buildInfoRow('Order ID', payment.orderId!),
                    const SizedBox(height: 20),

                    // Payment Information
                    _buildSectionHeader('Payment Information'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Payment Method', receipt.paymentMethod),
                    _buildInfoRow('Reference', payment.reference),
                    _buildInfoRow('Status', payment.status),
                    if (payment.paidAt != null)
                      _buildInfoRow(
                        'Paid At',
                        _formatDateTime(payment.paidAt!),
                      ),
                    const SizedBox(height: 20),

                    // Amount Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: kprimaryTextColor1,
                            ),
                          ),
                          Text(
                            _formatPrice(receipt.amount),
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Footer
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Thank you for your business!',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: kprimaryTextColor2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Issued: ${_formatDateTime(receipt.issuedAt)}',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Download PDF Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingPdf ? null : _downloadReceipt,
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.download, color: Colors.white),
                  label: Text(
                    _isGeneratingPdf ? 'Generating PDF...' : 'Download as PDF',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 16,
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
              const SizedBox(height: 12),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate back to home/order screen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimary,
                    side: const BorderSide(color: kPrimary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: kprimaryTextColor1,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
