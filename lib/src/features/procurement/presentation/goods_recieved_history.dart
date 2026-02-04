import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_good_recieved_model.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/good_received_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/good_received_bloc/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/good_received_bloc/state.dart';

class GoodsReceivedHistoryScreen extends StatefulWidget {
  const GoodsReceivedHistoryScreen({super.key});

  @override
  State<GoodsReceivedHistoryScreen> createState() =>
      _GoodsReceivedHistoryScreenState();
}

class _GoodsReceivedHistoryScreenState
    extends State<GoodsReceivedHistoryScreen> {
  String _branchId = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    if (mounted) {
      context.read<GoodsReceivedBloc>().add(
        LoadGoodsReceived(branchId: _branchId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoodsReceivedBloc, GoodsReceivedState>(
      builder: (context, state) {
        if (state is GoodsReceivedLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: kPrimary,
              valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
            ),
          );
        }

        if (state is GoodsReceivedError) {
          return _buildErrorState(state.error);
        }

        if (state is GoodsReceivedListLoaded) {
          if (state.receipts.isEmpty) {
            return _buildEmptyState();
          }
          return _buildReceiptsList(state.receipts);
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor2,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: kprimaryTextColor2.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Receipts Found',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by logging your first goods receipt',
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptsList(List<GoodsReceived> receipts) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => _loadData(),
          child: ListView.builder(
            padding: EdgeInsets.all(_getPadding(screenWidth)),
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              final receipt = receipts[index];
              return _buildReceiptCard(receipt, screenWidth);
            },
          ),
        );
      },
    );
  }

  Widget _buildReceiptCard(GoodsReceived receipt, double screenWidth) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final passRate = receipt.totalItems > 0
        ? (receipt.passedQC / receipt.totalItems * 100).toStringAsFixed(0)
        : '0';

    return Container(
      margin: EdgeInsets.only(bottom: _getSpacing(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showReceiptDetails(receipt, screenWidth),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(_getPadding(screenWidth)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: kPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receipt.receiptNo,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: _getTitleFontSize(screenWidth),
                              fontWeight: FontWeight.w600,
                              color: kprimaryTextColor1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            receipt.supplierName,
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: _getLabelFontSize(screenWidth),
                              color: kprimaryTextColor2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: kprimaryTextColor2,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.calendar_today,
                  dateFormat.format(receipt.receivedAt),
                  screenWidth,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.description,
                  'Invoice: ${receipt.invoiceNo} • PO: ${receipt.poNumber}',
                  screenWidth,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.inventory,
                  '${receipt.totalItems} item${receipt.totalItems != 1 ? 's' : ''}',
                  screenWidth,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQualityChip(
                          'Passed',
                          receipt.passedQC.toString(),
                          Colors.green,
                          screenWidth,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQualityChip(
                          'Failed',
                          receipt.failedQC.toString(),
                          Colors.red,
                          screenWidth,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQualityChip(
                          'Pass Rate',
                          '$passRate%',
                          kPrimary,
                          screenWidth,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, double screenWidth) {
    return Row(
      children: [
        Icon(icon, size: _getIconSize(screenWidth), color: kprimaryTextColor2),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getLabelFontSize(screenWidth),
              color: kprimaryTextColor2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQualityChip(
    String label,
    String value,
    Color color,
    double screenWidth,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getTitleFontSize(screenWidth),
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 11,
            color: kprimaryTextColor2,
          ),
        ),
      ],
    );
  }

  void _showReceiptDetails(GoodsReceived receipt, double screenWidth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        receipt.receiptNo,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: kprimaryTextColor1,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailSection('Supplier Information', [
                      _buildDetailRow('Supplier', receipt.supplierName),
                      _buildDetailRow('Invoice No', receipt.invoiceNo),
                      _buildDetailRow('PO Number', receipt.poNumber),
                      _buildDetailRow('Branch', receipt.branch?.name ?? 'N/A'),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('Receipt Information', [
                      _buildDetailRow('Received By', receipt.receivedBy),
                      _buildDetailRow('Inspected By', receipt.inspectedBy),
                      _buildDetailRow(
                        'Received At',
                        DateFormat(
                          'MMM dd, yyyy • hh:mm a',
                        ).format(receipt.receivedAt),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('Quality Control', [
                      _buildDetailRow('Total Items', '${receipt.totalItems}'),
                      _buildDetailRow('Passed QC', '${receipt.passedQC}'),
                      _buildDetailRow('Failed QC', '${receipt.failedQC}'),
                      _buildDetailRow('Notes', receipt.qualityNotes),
                    ]),
                    const SizedBox(height: 20),
                    Text(
                      'Items (${receipt.items.length})',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kprimaryTextColor1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...receipt.items.map((item) => _buildItemCard(item)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kprimaryTextColor1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kprimaryTextColor1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(GoodsReceivedItem item) {
    final statusColor = item.qualityCheck ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.itemName,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kprimaryTextColor1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.qcStatus,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildItemInfo('Ordered', item.orderedQty.toString()),
              ),
              Expanded(
                child: _buildItemInfo('Received', item.receivedQty.toString()),
              ),
            ],
          ),
          if (item.qcNote != null) ...[
            const SizedBox(height: 12),
            Text(
              'Note: ${item.qcNote}',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: kprimaryTextColor2,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (item.expiryDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event, size: 14, color: kprimaryTextColor2),
                const SizedBox(width: 4),
                Text(
                  'Expires: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(item.expiryDate!))}',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: kprimaryTextColor2,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 12,
            color: kprimaryTextColor2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kprimaryTextColor1,
          ),
        ),
      ],
    );
  }

  double _getPadding(double width) => width < 600 ? 16 : 20;
  double _getSpacing(double width) => width < 600 ? 12 : 16;
  double _getTitleFontSize(double width) => width < 600 ? 16 : 17;
  double _getLabelFontSize(double width) => width < 600 ? 14 : 15;
  double _getIconSize(double width) => width < 600 ? 18 : 20;
}
