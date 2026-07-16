import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_good_recieved_model.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/goods_received_advanced_cubit/goods_received_advanced_cubit.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/goods_received_advanced_cubit/goods_received_advanced_state.dart';

class GoodsReceivedDetailScreen extends StatefulWidget {
  final String receiptId;
  final String title;

  const GoodsReceivedDetailScreen({
    super.key,
    required this.receiptId,
    required this.title,
  });

  @override
  State<GoodsReceivedDetailScreen> createState() =>
      _GoodsReceivedDetailScreenState();
}

class _GoodsReceivedDetailScreenState extends State<GoodsReceivedDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GoodsReceivedAdvancedCubit>().loadDetail(widget.receiptId);
  }

  Future<void> _showQcDialog(GoodsReceived receipt) async {
    final noteController = TextEditingController(text: receipt.qualityNotes);
    String qcStatus = receipt.failedQC > 0 ? 'FAILED' : 'PASSED';
    final inspectedBy = await AuthCacheHelper.instance.getEmpID() ?? '';
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update QC'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: qcStatus,
                  items: const [
                    DropdownMenuItem(value: 'PASSED', child: Text('Passed')),
                    DropdownMenuItem(value: 'FAILED', child: Text('Failed')),
                    DropdownMenuItem(value: 'PARTIAL', child: Text('Partial')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => qcStatus = value);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'QC Status'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'QC Note'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final cubit = context.read<GoodsReceivedAdvancedCubit>();
                  final messenger = ScaffoldMessenger.of(context);
                  final errorColor = context.modeError;
                  final ok = await cubit.updateQc(
                    id: receipt.id,
                    request: UpdateGoodsReceivedQcRequest(
                      qcStatus: qcStatus,
                      inspectedBy: inspectedBy,
                      qcNote: noteController.text.trim(),
                    ),
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? 'QC updated.' : 'Failed to update QC.',
                      ),
                      backgroundColor: ok ? kGreen : errorColor,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
        appBar: AppBar(
          backgroundColor: context.modeSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.modeTextPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.title),
          actions: [
            BlocBuilder<GoodsReceivedAdvancedCubit, GoodsReceivedAdvancedState>(
              builder: (context, state) {
                final receipt = state.detail;
                if (receipt == null) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(Icons.fact_check_outlined, color: kPrimary),
                  onPressed: () => _showQcDialog(receipt),
                );
              },
            ),
          ],
        ),
        body:
            BlocBuilder<GoodsReceivedAdvancedCubit, GoodsReceivedAdvancedState>(
              builder: (context, state) {
                if (state.detailStatus == GoodsReceivedAdvancedStatus.loading ||
                    state.detailStatus == GoodsReceivedAdvancedStatus.initial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.detailStatus == GoodsReceivedAdvancedStatus.error) {
                  return Center(
                    child: Text(state.detailError ?? 'Failed to load'),
                  );
                }
                final receipt = state.detail;
                if (receipt == null) return const SizedBox.shrink();
                return _DetailBody(receipt: receipt);
              },
            ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final GoodsReceived receipt;

  const _DetailBody({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: 'Receipt Information',
          children: [
            _Row(label: 'Receipt No', value: receipt.receiptNo),
            _Row(label: 'Supplier', value: receipt.supplierName),
            _Row(label: 'Invoice No', value: receipt.invoiceNo),
            _Row(label: 'PO Number', value: receipt.poNumber),
            _Row(
              label: 'Received At',
              value: DateFormat(
                'MMM dd, yyyy - hh:mm a',
              ).format(receipt.receivedAt),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Quality Control',
          children: [
            _Row(label: 'Total Items', value: '${receipt.totalItems}'),
            _Row(label: 'Passed QC', value: '${receipt.passedQC}'),
            _Row(label: 'Failed QC', value: '${receipt.failedQC}'),
            _Row(label: 'Notes', value: receipt.qualityNotes),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Items',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...receipt.items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.modeBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.modeTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _Row(label: 'Ordered', value: '${item.orderedQty}'),
                _Row(label: 'Received', value: '${item.receivedQty}'),
                _Row(label: 'QC Status', value: item.qcStatus),
                if ((item.qcNote ?? '').isNotEmpty)
                  _Row(label: 'QC Note', value: item.qcNote!),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: context.modeTextMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: context.modeTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
