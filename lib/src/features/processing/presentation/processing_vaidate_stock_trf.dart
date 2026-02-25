import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/processing_transfrer_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/processing_transfrer_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/processing_transfrer_bloc/state.dart';

import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/processing_transfer_model.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';

class RequisitionItem {
  String itemId;
  String itemName;
  int quantity;

  RequisitionItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
  });
}

class ValidateStockTransferToProcessingcreen extends StatefulWidget {
  const ValidateStockTransferToProcessingcreen({super.key});

  @override
  State<ValidateStockTransferToProcessingcreen> createState() =>
      _ValidateStockTransferToProcessingcreenState();
}

class _ValidateStockTransferToProcessingcreenState
    extends State<ValidateStockTransferToProcessingcreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _batchCodeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String? _selectedItemId;
  String? _selectedItemName;
  String branchId = '';
  String employeeId = '';
  bool _isSearching = false;
  bool _isOpened = false;
  bool _isInitialized = false;

  final List<RequisitionItem> _requisitionItems = [];
  List<CatalogItem> _filteredItems = [];
  List<CatalogItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);

    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _getBranchAndEmployeeData();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });

      if (branchId.isNotEmpty) {
        context.read<ProcessingTransferBloc>().add(
          LoadProcessingTransfers(branchId: branchId),
        );
        context.read<BranchStockBloc>().add(
          LoadBranchStock(branchId: branchId),
        );
      } else {
        _showSnackBar(
          'Unable to load branch information. Please restart the app.',
          isError: true,
        );
      }
    }
  }

  Future<void> _getBranchAndEmployeeData() async {
    final bId = await AuthCacheHelper.instance.getBranchID() ?? '';
    final empId = await AuthCacheHelper.instance.getEmpID() ?? '';

    AppLogger.log('=== BRANCH & EMPLOYEE DATA ===');
    AppLogger.log('Branch ID: $bId');
    AppLogger.log('Employee ID: $empId');
    AppLogger.log('==============================');

    if (mounted) {
      setState(() {
        branchId = bId;
        employeeId = empId;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems
            .where(
              (item) => item.name.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _batchCodeController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _showValidateDialog(ProcessingTransferResponse transfer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => _ValidateTransferBottomSheet(
        transfer: transfer,
        onSuccess: () {
          // Refresh the list after successful validation
          context.read<ProcessingTransferBloc>().add(
            LoadProcessingTransfers(branchId: branchId),
          );
        },
      ),
    );
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: backgroundColor ?? (isError ? Colors.red : kGreen),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 3 : 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProcessingTransferBloc, ProcessingTransferState>(
          listener: (context, state) {
            if (state is ProcessingTransferCreated) {
              _showSnackBar(
                'Requisition submitted successfully!',
                backgroundColor: Colors.green,
              );

              // Clear form
              setState(() {
                _requisitionItems.clear();
                _batchCodeController.clear();
                _notesController.clear();
              });

              // Switch to pending tab
              _tabController.animateTo(0);
            } else if (state is ProcessingTransferError) {
              _showSnackBar(state.error, isError: true);
            }
          },
        ),
      ],
      child: BlocBuilder<BranchStockBloc, BranchStockState>(
        builder: (context, stockState) {
          if (stockState is BranchStockLoaded && _allItems.isEmpty) {
            _allItems = stockState.filteredItems;
            _filteredItems = stockState.filteredItems;
          }

          return DefaultTextStyle.merge(
            style: WorkSansAppTextStyles.medium,
            child: Scaffold(
              backgroundColor: const Color(0xFFF8F6F6),
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Validate Stock Transfer',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kprimaryTextColor1,
                  ),
                ),
                centerTitle: true,
              ),
              body: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: kPrimary,
                      unselectedLabelColor: kprimaryTextColor2,
                      indicatorColor: kPrimary,
                      indicatorWeight: 3,
                      labelStyle: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: WorkSansAppTextStyles.medium
                          .copyWith(fontSize: 15, fontWeight: FontWeight.w500),
                      tabs: const [
                        Tab(text: 'Pending'),
                        Tab(text: 'Completed'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildPendingTab(), _buildCompletedTab()],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingTab() {
    return BlocBuilder<ProcessingTransferBloc, ProcessingTransferState>(
      builder: (context, state) {
        if (state is ProcessingTransferLoading) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return shimmerCatalogCard(constraints.maxWidth);
            },
          );
        }

        if (state is ProcessingTransferError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading transfers',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kprimaryTextColor1,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    state.error,
                    textAlign: TextAlign.center,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: kprimaryTextColor2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<ProcessingTransferBloc>().add(
                      LoadProcessingTransfers(branchId: branchId),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is ProcessingTransferListLoaded) {
          if (state.pendingTransfers.isEmpty) {
            return _buildEmptyState(
              icon: Icons.pending_actions_outlined,
              title: 'No Pending Transfer',
              message: 'Your pending transfers will appear here',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProcessingTransferBloc>().add(
                RefreshProcessingTransfers(branchId: branchId),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.pendingTransfers.length,
              itemBuilder: (context, index) {
                final transfer = state.pendingTransfers[index];
                return _buildTransferCard(transfer, isPending: true);
              },
            ),
          );
        }

        return _buildEmptyState(
          icon: Icons.pending_actions_outlined,
          title: 'No Pending Transfer',
          message: 'Your pending transfers will appear here',
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    return BlocBuilder<ProcessingTransferBloc, ProcessingTransferState>(
      builder: (context, state) {
        if (state is ProcessingTransferLoading ||
            state is ProcessingTransferRefreshing) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return shimmerCatalogCard(constraints.maxWidth);
            },
          );
        }

        if (state is ProcessingTransferListLoaded) {
          if (state.completedTransfers.isEmpty) {
            return _buildEmptyState(
              icon: Icons.check_circle_outline,
              title: 'No Completed Transfers',
              message: 'Your completed transfers will appear here',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProcessingTransferBloc>().add(
                RefreshProcessingTransfers(branchId: branchId),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.completedTransfers.length,
              itemBuilder: (context, index) {
                final transfer = state.completedTransfers[index];
                return _buildTransferCard(transfer, isPending: false);
              },
            ),
          );
        }

        return _buildEmptyState(
          icon: Icons.check_circle_outline,
          title: 'No Completed Transfers',
          message: 'Your completed transfers will appear here',
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text(
              title,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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

  Widget _buildTransferCard(
    ProcessingTransferResponse transfer, {
    required bool isPending,
  }) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final formattedDate = dateFormat.format(transfer.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch: ${transfer.batchCode}',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kprimaryTextColor1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: kprimaryTextColor2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPending ? 'Pending' : 'Completed',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPending ? Colors.orange : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: kprimaryTextColor2,
              ),
              const SizedBox(width: 8),
              Text(
                '${transfer.items.length} item(s)',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kprimaryTextColor1,
                ),
              ),
            ],
          ),
          if (transfer.notes != null && transfer.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note_outlined, size: 18, color: kprimaryTextColor2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transfer.notes!,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: kprimaryTextColor2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // UPDATED: Two buttons side by side
          Row(
            children: [
              // View Details button
              Expanded(
                child: InkWell(
                  onTap: () => _showTransferDetails(transfer, isPending),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Details',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: kPrimary,
                      ),
                    ],
                  ),
                ),
              ),
              // Validate button (only for pending transfers)
              if (isPending) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showValidateDialog(transfer),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Validate',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showTransferDetails(
    ProcessingTransferResponse transfer,
    bool isPending,
  ) {
    final dateFormat = DateFormat('MMMM dd, yyyy • hh:mm a');
    final formattedDate = dateFormat.format(transfer.createdAt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requisition Details',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: kprimaryTextColor1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Batch: ${transfer.batchCode}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            color: kprimaryTextColor2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      'Status',
                      isPending ? 'Pending' : 'Completed',
                    ),
                    _buildDetailRow('Date Created', formattedDate),
                    if (transfer.notes != null && transfer.notes!.isNotEmpty)
                      _buildDetailRow('Notes', transfer.notes!),
                    const SizedBox(height: 20),
                    Text(
                      'Items (${transfer.items.length})',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kprimaryTextColor1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...transfer.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.item.itemName,
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: kprimaryTextColor1,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Qty Sent: ${item.qtySent}',
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: 13,
                                          color: kprimaryTextColor2,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidateTransferBottomSheet extends StatefulWidget {
  final ProcessingTransferResponse transfer;
  final VoidCallback onSuccess;

  const _ValidateTransferBottomSheet({
    required this.transfer,
    required this.onSuccess,
  });

  @override
  State<_ValidateTransferBottomSheet> createState() =>
      __ValidateTransferBottomSheetState();
}

class __ValidateTransferBottomSheetState
    extends State<_ValidateTransferBottomSheet> {
  final TextEditingController _varianceNoteController = TextEditingController();
  final Map<String, TextEditingController> _quantityControllers = {};
  bool _qualityCheck = true;
  String employeeId = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final empId = await AuthCacheHelper.instance.getEmpID() ?? '';

    if (mounted) {
      setState(() {
        employeeId = empId;
        _isInitialized = true;
      });

      for (var item in widget.transfer.items) {
        _quantityControllers[item.itemId] = TextEditingController(
          text: item.qtySent.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    _varianceNoteController.dispose();
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _validateAndReceive() {
    if (!_isInitialized || employeeId.isEmpty) {
      _showSnackBar(
        'Employee information not available. Please restart the app.',
        isError: true,
      );
      return;
    }

    final items = <ReceiveTransferItem>[];
    bool hasError = false;

    for (var item in widget.transfer.items) {
      final controller = _quantityControllers[item.itemId];
      if (controller == null) continue;

      final qtyReceived = int.tryParse(controller.text.trim());
      if (qtyReceived == null || qtyReceived < 0) {
        _showSnackBar(
          'Please enter valid quantities for all items',
          isError: true,
        );
        hasError = true;
        break;
      }

      items.add(
        ReceiveTransferItem(itemId: item.itemId, qtyReceived: qtyReceived),
      );
    }

    if (hasError) return;

    // Check if there are variances
    bool hasVariance = false;
    for (var i = 0; i < widget.transfer.items.length; i++) {
      final sentQty = int.parse(widget.transfer.items[i].qtySent);
      final receivedQty = items[i].qtyReceived;
      if (sentQty != receivedQty) {
        hasVariance = true;
        break;
      }
    }

    // If there's variance but no note, show warning
    if (hasVariance && _varianceNoteController.text.trim().isEmpty) {
      _showVarianceAlert(items);
      return;
    }

    _submitReceive(items);
  }

  void _showVarianceAlert(List<ReceiveTransferItem> items) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Variance Detected',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kprimaryTextColor1,
          ),
        ),
        content: Text(
          'There are quantity differences between sent and received items. Please add a variance note to explain the difference.',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: kprimaryTextColor2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor2,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Show message to add note
              if (mounted) {
                _showSnackBar(
                  'Please add a variance note below to continue',
                  isError: false,
                );
              }
            },
            child: Text(
              'Add Note',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitReceive(List<ReceiveTransferItem> items) {
    // Validate before proceeding
    if (!_isInitialized || employeeId.isEmpty) {
      _showSnackBar(
        'Employee information not available. Please restart the app.',
        isError: true,
      );
      return;
    }

    // Create the request object
    final request = ReceiveTransferRequest(
      receivedBy: employeeId,
      items: items,
      qualityCheck: _qualityCheck,
      varianceNote: _varianceNoteController.text.trim().isEmpty
          ? null
          : _varianceNoteController.text.trim(),
    );

    final processingTransferBloc = context.read<ProcessingTransferBloc>();

    Navigator.of(context).pop();

    processingTransferBloc.add(
      ReceiveProcessingTransfer(
        transferId: widget.transfer.id,
        request: request,
      ),
    );

    widget.onSuccess();
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    Color? backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: backgroundColor ?? (isError ? Colors.red : kPrimary),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 3 : 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Validate Transfer',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: kprimaryTextColor1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Batch: ${widget.transfer.batchCode}',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          color: kprimaryTextColor2,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items list
                  Text(
                    'Received Items',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.transfer.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final controller = _quantityControllers[item.itemId]!;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: kPrimary,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.item.itemName,
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kprimaryTextColor1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Qty Sent: ${item.qtySent}',
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 13,
                                    color: kprimaryTextColor2,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  cursorColor: kPrimary,
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kprimaryTextColor1,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Received',
                                    labelStyle: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: 12,
                                          color: kprimaryTextColor2,
                                        ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: kPrimary),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  // Quality Check
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _qualityCheck,
                          onChanged: (value) {
                            setState(() {
                              _qualityCheck = value ?? true;
                            });
                          },
                          activeColor: kPrimary,
                        ),
                        Expanded(
                          child: Text(
                            'Quality check passed',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 14,
                              color: kprimaryTextColor1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Variance Note
                  Text(
                    'Variance Note (Optional)',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _varianceNoteController,
                    maxLines: 3,
                    cursorColor: kPrimary,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: kprimaryTextColor1,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add note if quantities differ...',
                      hintStyle: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: kprimaryTextColor2,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kPrimary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Validate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _validateAndReceive,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Validate & Receive',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
