import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class OrderDetailsScreen extends StatefulWidget {
  final PurchaseOrder order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFFF8F6F6),
            appBar: _buildAppBar(context),
            body: _buildBody(context),
          ),
          if (_isGeneratingPdf)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: kPrimary),
                        const SizedBox(height: 16),
                        Text(
                          'Generating PDF...',
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
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Order Details',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.black),
          onPressed: _shareOrderPdf,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onSelected: (value) {
            switch (value) {
              case 'print':
                _printOrder();
                break;
              case 'download':
                _downloadOrderPdf();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  const Icon(Icons.print, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Print Order',
                    style: WorkSansAppTextStyles.medium.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  const Icon(Icons.download, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Download PDF',
                    style: WorkSansAppTextStyles.medium.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Generate PDF document
  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.workSansRegular();
    final fontBold = await PdfGoogleFonts.workSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildPdfHeader(fontBold, font),
            pw.SizedBox(height: 20),
            _buildPdfOrderInfo(fontBold, font),
            pw.SizedBox(height: 20),
            _buildPdfSection('Supplier Information', fontBold, [
              _buildPdfInfoRow(
                'Business Name',
                widget.order.supplier.businessName,
                font,
              ),
              _buildPdfInfoRow(
                'Supplier ID',
                widget.order.supplier.supplierId,
                font,
              ),
              _buildPdfInfoRow('Email', widget.order.supplier.email, font),
              _buildPdfInfoRow('Phone', widget.order.supplier.phone, font),
            ]),
            pw.SizedBox(height: 15),
            _buildPdfSection('Delivery Information', fontBold, [
              _buildPdfInfoRow('Address', widget.order.deliveryAddress, font),
              _buildPdfInfoRow(
                'City',
                '${widget.order.deliveryCity}, ${widget.order.deliveryState}',
                font,
              ),
              _buildPdfInfoRow(
                'Expected Delivery',
                DateFormat(
                  'MMMM dd, yyyy',
                ).format(widget.order.expectedDeliveryDate),
                font,
              ),
              if (widget.order.deliveryInstructions != null)
                _buildPdfInfoRow(
                  'Instructions',
                  widget.order.deliveryInstructions!,
                  font,
                ),
            ]),
            pw.SizedBox(height: 20),
            _buildPdfItemsTable(fontBold, font),
            pw.SizedBox(height: 20),
            _buildPdfFinancialSummary(fontBold, font),
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated on ${DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now())}',
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfHeader(pw.Font fontBold, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F7EADD'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PURCHASE ORDER',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 24,
                      color: PdfColor.fromHex('#EC9455'),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    widget.order.orderNumber,
                    style: pw.TextStyle(font: fontBold, fontSize: 18),
                  ),
                ],
              ),
              _buildPdfStatusBadge(widget.order.status, font, fontBold),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfOrderInfo(pw.Font fontBold, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Order Date',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                DateFormat('MMM dd, yyyy').format(widget.order.orderDate),
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Payment Terms',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                widget.order.paymentTerm,
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Priority',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                widget.order.priority,
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSection(
    String title,
    pw.Font fontBold,
    List<pw.Widget> children,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              style: pw.TextStyle(font: font, fontSize: 10),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfItemsTable(pw.Font fontBold, pw.Font font) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F7EADD')),
          children: [
            _buildPdfTableCell('Item', fontBold, isHeader: true),
            _buildPdfTableCell('Code', fontBold, isHeader: true),
            _buildPdfTableCell('Qty', fontBold, isHeader: true),
            _buildPdfTableCell('Unit Price', fontBold, isHeader: true),
            _buildPdfTableCell('Total', fontBold, isHeader: true),
          ],
        ),
        ...widget.order.items.map((item) {
          return pw.TableRow(
            children: [
              _buildPdfTableCell(item.productName, font),
              _buildPdfTableCell(item.productCode, font),
              _buildPdfTableCell('${item.quantityOrdered} ${item.unit}', font),
              _buildPdfTableCell(
                '₦${NumberFormat('#,##0.00').format(item.unitPrice)}',
                font,
              ),
              _buildPdfTableCell(
                '₦${NumberFormat('#,##0.00').format(item.totalPrice)}',
                font,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildPdfTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildPdfFinancialSummary(pw.Font fontBold, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F7EADD'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _buildPdfPriceRow(
            'Subtotal',
            '₦${NumberFormat('#,##0.00').format(widget.order.subtotal)}',
            font,
          ),
          pw.SizedBox(height: 8),
          _buildPdfPriceRow(
            'Tax',
            '₦${NumberFormat('#,##0.00').format(widget.order.tax)}',
            font,
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          _buildPdfPriceRow(
            'TOTAL',
            '₦${NumberFormat('#,##0.00').format(widget.order.totalAmount)}',
            fontBold,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfPriceRow(
    String label,
    String value,
    pw.Font font, {
    bool isTotal = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: font, fontSize: isTotal ? 14 : 11),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontSize: isTotal ? 16 : 12,
            color: isTotal ? PdfColor.fromHex('#EC9455') : PdfColors.black,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfStatusBadge(
    String status,
    pw.Font font,
    pw.Font fontBold,
  ) {
    PdfColor backgroundColor;
    PdfColor textColor;

    switch (status.toUpperCase()) {
      case 'PENDING':
        backgroundColor = PdfColor.fromHex('#FFF3E0');
        textColor = PdfColor.fromHex('#F57C00');
        break;
      case 'ACCEPTED':
        backgroundColor = PdfColor.fromHex('#E3F2FD');
        textColor = PdfColor.fromHex('#1976D2');
        break;
      case 'COMPLETED':
        backgroundColor = PdfColor.fromHex('#E8F5E9');
        textColor = PdfColor.fromHex('#388E3C');
        break;
      case 'CANCELLED':
        backgroundColor = PdfColor.fromHex('#EEEEEE');
        textColor = PdfColor.fromHex('#616161');
        break;
      default:
        backgroundColor = PdfColor.fromHex('#F5F5F5');
        textColor = PdfColor.fromHex('#757575');
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        status.toUpperCase(),
        style: pw.TextStyle(font: fontBold, fontSize: 10, color: textColor),
      ),
    );
  }

  Future<void> _printOrder() async {
    try {
      setState(() => _isGeneratingPdf = true);
      final pdf = await _generatePdf();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '${widget.order.orderNumber}.pdf',
      );
      if (mounted) setState(() => _isGeneratingPdf = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
        _showErrorSnackBar('Failed to print: $e');
      }
    }
  }

  Future<void> _downloadOrderPdf() async {
    try {
      setState(() => _isGeneratingPdf = true);

      final pdf = await _generatePdf();
      final bytes = await pdf.save();

      String? path;
      Directory? directory;

      // Use app-specific directories only (no permissions needed)
      if (Platform.isAndroid) {
        directory = await getApplicationDocumentsDirectory();
        path = directory.path;
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
        path = directory.path;
      } else {
        directory = await getDownloadsDirectory();
        path = directory?.path;
      }

      if (path == null) throw Exception('Could not get storage directory');

      final fileName = '${widget.order.orderNumber}.pdf';
      final filePath = '$path/$fileName';
      final file = File(filePath);

      // Write the file
      await file.writeAsBytes(bytes);

      if (mounted) {
        setState(() => _isGeneratingPdf = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDF saved successfully!',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fileName,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () async {
                final result = await OpenFile.open(filePath);
                if (result.type != ResultType.done && mounted) {
                  // If can't open, offer to share instead
                  _showShareDialog(bytes, fileName);
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
        _showErrorSnackBar('Failed to save PDF: ${e.toString()}');
      }
    }
  }

  void _showShareDialog(List<int> bytes, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: kPrimary),
            const SizedBox(width: 12),
            const Text('Open PDF'),
          ],
        ),
        content: Text(
          'No PDF viewer found. Would you like to share the PDF to view it in another app?',
          style: WorkSansAppTextStyles.medium.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: WorkSansAppTextStyles.medium.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Printing.sharePdf(bytes: bytes as Uint8List, filename: fileName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Share',
              style: WorkSansAppTextStyles.medium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareOrderPdf() async {
    try {
      setState(() => _isGeneratingPdf = true);
      final pdf = await _generatePdf();
      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${widget.order.orderNumber}.pdf',
      );
      if (mounted) setState(() => _isGeneratingPdf = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
        _showErrorSnackBar('Failed to share: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _getHorizontalPadding(constraints.maxWidth);
        final maxContentWidth = _getMaxContentWidth(constraints.maxWidth);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                _buildStatusHeader(horizontalPadding),
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: kPrimary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: kPrimary,
                    labelStyle: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Items'),
                      Tab(text: 'Timeline'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(horizontalPadding),
                      _buildItemsTab(horizontalPadding),
                      _buildTimelineTab(horizontalPadding),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader(double padding) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.orderNumber,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ordered on ${DateFormat('MMM dd, yyyy').format(widget.order.orderDate)}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(widget.order.status),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7EADD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₦${NumberFormat('#,##0.00').format(widget.order.totalAmount)}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildPaymentBadge(widget.order.paymentStatus),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.order.items.length} items',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Supplier Information',
            icon: Icons.store_outlined,
            child: Column(
              children: [
                _buildInfoRow(
                  'Business Name',
                  widget.order.supplier.businessName,
                ),
                const Divider(height: 24),
                _buildInfoRow('Supplier ID', widget.order.supplier.supplierId),
                const Divider(height: 24),
                _buildInfoRow('Email', widget.order.supplier.email),
                const Divider(height: 24),
                _buildInfoRow('Phone', widget.order.supplier.phone),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Delivery Information',
            icon: Icons.local_shipping_outlined,
            child: Column(
              children: [
                _buildInfoRow('Delivery Address', widget.order.deliveryAddress),
                const Divider(height: 24),
                _buildInfoRow(
                  'City',
                  '${widget.order.deliveryCity}, ${widget.order.deliveryState}',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  'Expected Delivery',
                  DateFormat(
                    'MMMM dd, yyyy',
                  ).format(widget.order.expectedDeliveryDate),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Financial Summary',
            icon: Icons.account_balance_wallet_outlined,
            child: Column(
              children: [
                _buildPriceRow(
                  'Subtotal',
                  '₦${NumberFormat('#,##0.00').format(widget.order.subtotal)}',
                ),
                const Divider(height: 24),
                _buildPriceRow(
                  'Tax',
                  '₦${NumberFormat('#,##0.00').format(widget.order.tax)}',
                ),
                const Divider(height: 24),
                _buildPriceRow(
                  'Total',
                  '₦${NumberFormat('#,##0.00').format(widget.order.totalAmount)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildItemsTab(double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          ...widget.order.items
              .map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEC9455),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.productCode,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Qty: ${item.quantityOrdered} ${item.unit}',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '₦${NumberFormat('#,##0.00').format(item.totalPrice)}',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Order Timeline',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            'Order Created',
            DateFormat('MMM dd, yyyy').format(widget.order.createdAt),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: kPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? Colors.black : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.w700,
            color: isTotal ? kPrimary : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'PENDING':
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      case 'ACCEPTED':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case 'DECLINED':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      case 'IN_TRANSIT':
        backgroundColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        break;
      case 'DELIVERED':
        backgroundColor = Colors.teal.shade50;
        textColor = Colors.teal.shade700;
        break;
      case 'COMPLETED':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'CANCELLED':
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(String status) {
    Color color;
    IconData icon;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'FAILED':
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.amber;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 32;
    return 48;
  }

  double _getMaxContentWidth(double width) {
    if (width < 600) return double.infinity;
    if (width < 900) return 600;
    return 900;
  }
}
