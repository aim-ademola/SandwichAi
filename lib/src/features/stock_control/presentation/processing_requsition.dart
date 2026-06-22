import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/processing_transfrer_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/processing_transfrer_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/processing_transfrer_bloc/state.dart';

import 'package:sandwich_ai/src/features/stock_control/data/model/processing_transfer_model.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/inventory_items_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/processing_transfer_repo.dart';
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

class StockTransferToProcessingOrKItchenScreen extends StatefulWidget {
  final String? requestId;
  const StockTransferToProcessingOrKItchenScreen({super.key, this.requestId});

  @override
  State<StockTransferToProcessingOrKItchenScreen> createState() =>
      _StockTransferToProcessingOrKItchenScreenState();
}

class _StockTransferToProcessingOrKItchenScreenState
    extends State<StockTransferToProcessingOrKItchenScreen>
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
  String orgaID = '';
  bool _isSearching = false;
  bool _isOpened = false;
  bool _isInitialized = false;

  final List<RequisitionItem> _requisitionItems = [];
  List<InventoryItem> _filteredItems = [];
  List<InventoryItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        _generateBatchCode();
        context.read<ProcessingTransferBloc>().add(
          LoadProcessingTransfers(branchId: branchId),
        );
        final orgID = await AuthCacheHelper.instance.getOrgId() ?? '';
        context.read<InventoryItemsBloc>().add(
          LoadInventoryItems(organizationId: orgID, page: 1, limit: 20),
        );
      } else {
        _showSnackBar(
          'Unable to load branch information. Please restart the app.',
          isError: true,
        );
      }
    }
  }

  void _generateBatchCode() {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyyMMdd');
    final timeFormat = DateFormat('HHmmss');
    final batchCode = 'PT${dateFormat.format(now)}${timeFormat.format(now)}';
    _batchCodeController.text = batchCode;
  }

  Future<void> _getBranchAndEmployeeData() async {
    final bId = await AuthCacheHelper.instance.getBranchID() ?? '';
    final empId = await AuthCacheHelper.instance.getEmpID() ?? '';
    final organID = await AuthCacheHelper.instance.getOrgId() ?? '';

    AppLogger.log('=== BRANCH & EMPLOYEE DATA ===');
    AppLogger.log('Branch ID: $bId');
    AppLogger.log('Employee ID: $empId');
    AppLogger.log('==============================');

    if (mounted) {
      setState(() {
        branchId = bId;
        employeeId = empId;
        orgaID = organID;
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

  void _addItemToList() {
    if (_selectedItemId == null ||
        _selectedItemName == null ||
        _quantityController.text.trim().isEmpty) {
      _showSnackBar('Please select an item and enter quantity', isError: true);
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showSnackBar('Please enter a valid quantity', isError: true);
      return;
    }

    setState(() {
      _requisitionItems.add(
        RequisitionItem(
          itemId: _selectedItemId!,
          itemName: _selectedItemName!,
          quantity: quantity,
        ),
      );
      _selectedItemId = null;
      _selectedItemName = null;
      _quantityController.clear();
      _isSearching = false;
      _isOpened = false;
    });

    _showSnackBar('Item added to transfer list', backgroundColor: Colors.green);
  }

  void _removeItem(int index) {
    setState(() {
      _requisitionItems.removeAt(index);
    });
  }

  void _submitRequisition() {
    if (!_isInitialized) {
      _showSnackBar('Please wait, loading data...', isError: true);
      return;
    }

    if (branchId.isEmpty) {
      _showSnackBar(
        'Branch information not available. Please restart the app.',
        isError: true,
      );
      return;
    }

    if (employeeId.isEmpty) {
      _showSnackBar(
        'Employee information not available. Please restart the app.',
        isError: true,
      );
      return;
    }

    if (_requisitionItems.isEmpty) {
      _showSnackBar(
        'Please add at least one item to the transfer',
        isError: true,
      );
      return;
    }

    if (_batchCodeController.text.trim().isEmpty) {
      _showSnackBar('Please enter a batch code', isError: true);
      return;
    }

    final request = ProcessingTransferRequest(
      branchId: branchId,
      batchCode: _batchCodeController.text.trim(),
      sentBy: employeeId,
      items: _requisitionItems
          .map(
            (item) => TransferItem(itemId: item.itemId, qtySent: item.quantity),
          )
          .toList(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    AppLogger.log('=== SUBMITTING Transfer ===');
    AppLogger.log('Branch ID: ${request.branchId}');
    AppLogger.log('Sent By: ${request.sentBy}');
    AppLogger.log('Batch Code: ${request.batchCode}');
    AppLogger.log('Items Count: ${request.items.length}');
    AppLogger.log('Items Detail:');
    for (var item in request.items) {
      AppLogger.log('  - Item ID: ${item.itemId}, Qty: ${item.qtySent}');
    }
    AppLogger.log('Notes: ${request.notes ?? "None"}');
    AppLogger.log('Request JSON: ${request.toJson()}');
    AppLogger.log('==============================');

    context.read<ProcessingTransferBloc>().add(
      CreateProcessingTransfer(request: request),
    );
  }

  void _completeStockRequest(String requestId) async {
    AppLogger.log('Completing stock request: $requestId');

    final repository = ProcessingTransferRepository();
    final result = await repository.completeStockRequest(requestId: requestId);

    await result.when(
      success: (data) {
        AppLogger.log('Stock request completed successfully: $data');
        _showSnackBar(
          'Stock request marked as completed!',
          backgroundColor: Colors.green,
        );
      },
      error: (error) {
        AppLogger.log('⚠️ Failed to complete stock request: $error');
      },
    );
  }

  void _showHelpBottomSheet({
    required String title,
    required String description,
    required List<String> tips,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.help_outline, color: kPrimary, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: kprimaryTextColor1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: kprimaryTextColor2,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 15,
                        color: kprimaryTextColor1,
                        height: 1.5,
                      ),
                    ),
                    if (tips.isNotEmpty) ...[
                      SizedBox(height: 24),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kPrimary.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: kPrimary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Tips',
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            ...tips.asMap().entries.map((entry) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key < tips.length - 1 ? 8 : 0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(top: 6),
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: kPrimary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: WorkSansAppTextStyles.medium
                                            .copyWith(
                                              fontSize: 13,
                                              color: kprimaryTextColor1,
                                              height: 1.4,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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
        backgroundColor: backgroundColor ?? (isError ? Colors.red : kPrimary),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 3 : 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log(widget.requestId);
    return MultiBlocListener(
      listeners: [
        BlocListener<ProcessingTransferBloc, ProcessingTransferState>(
          listener: (context, state) {
            if (state is ProcessingTransferCreated) {
              _showSnackBar(
                'Transfer submitted successfully!',
                backgroundColor: Colors.green,
              );
              if (widget.requestId != null && widget.requestId!.isNotEmpty) {
                _completeStockRequest(widget.requestId!);
              }
              setState(() {
                _requisitionItems.clear();
                _notesController.clear();
                _generateBatchCode(); // Generate new batch code
              });
              _tabController.animateTo(1);
            } else if (state is ProcessingTransferError) {
              _showSnackBar(state.error, isError: true);
            }
          },
        ),
        BlocListener<InventoryItemsBloc, InventoryItemsState>(
          listener: (context, state) {
            if (state is InventoryItemsLoaded && !state.isLoadingMore) {
              setState(() {
                _allItems = state.items;
                _filteredItems = _searchController.text.isEmpty
                    ? _allItems
                    : _allItems
                          .where(
                            (item) => item.name.toLowerCase().contains(
                              _searchController.text.toLowerCase(),
                            ),
                          )
                          .toList();
              });
            } else if (state is InventoryItemsError) {
              _showSnackBar(
                'Failed to load inventory items: ${state.error}',
                isError: true,
              );
            }
          },
        ),
      ],
      child: BlocBuilder<InventoryItemsBloc, InventoryItemsState>(
        builder: (context, stockState) {
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
                  'Send Items to Processing',
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
                        Tab(text: 'Initiate a Transfer'),
                        Tab(text: 'Pending'),
                        Tab(text: 'Completed'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCreateRequisitionTab(),
                        _buildPendingTab(),
                        _buildCompletedTab(),
                      ],
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

  Widget _buildCreateRequisitionTab() {
    return BlocBuilder<ProcessingTransferBloc, ProcessingTransferState>(
      builder: (context, state) {
        final isLoading = state is ProcessingTransferCreating;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Batch Code with Help Icon
              Row(
                children: [
                  Text(
                    'Batch Code',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showHelpBottomSheet(
                      title: 'Batch Code',
                      description:
                          'A unique identifier automatically generated for this transfer. The batch code helps track and organize stock transfers between your branch and the processing department.',
                      tips: [
                        'Format: PT + Date + Time (e.g., PT20260122143045)',
                        'Generated automatically - no manual input needed',
                        'Each transfer gets a unique code',
                        'Use this code to reference the transfer later',
                        'Helps in tracking transfer history and auditing',
                      ],
                    ),
                    child: Icon(Icons.help_outline, color: kPrimary, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code, color: kPrimary, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _batchCodeController.text,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kprimaryTextColor1,
                        ),
                      ),
                    ),
                    Icon(Icons.lock, color: kprimaryTextColor2, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Item Selection with Help Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Add Items',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kprimaryTextColor1,
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showHelpBottomSheet(
                          title: 'Add Items',
                          description:
                              'Select items from your branch inventory that you want to transfer to the processing department. You can add multiple items with different quantities.',
                          tips: [
                            'Search for items by typing their name',
                            'Enter the quantity you want to transfer',
                            'Click the + button to add to the list',
                            'You can add multiple items before submitting',
                            'Remove items by clicking the X icon',
                            'Ensure quantities don\'t exceed available stock',
                          ],
                        ),
                        child: Icon(
                          Icons.help_outline,
                          color: kPrimary,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  if (_requisitionItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_requisitionItems.length} item(s)',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              _buildItemSearchField(),
              const SizedBox(height: 12),
              _buildQuantityField(),

              if (_requisitionItems.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Items in Requisition',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kprimaryTextColor1,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_requisitionItems.length, (index) {
                  final item = _requisitionItems[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.1),
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
                                item.itemName,
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kprimaryTextColor1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Qty: ${item.quantity}',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 13,
                                  color: kprimaryTextColor2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: Colors.red,
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),

              // Notes with Help Icon
              Row(
                children: [
                  Text(
                    'Note/Instructions',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showHelpBottomSheet(
                      title: 'Notes/Instructions',
                      description:
                          'Add any additional information, special instructions, or notes about this transfer. This helps the processing department understand the context or special handling requirements.',
                      tips: [
                        'Optional field - you can leave it empty',
                        'Mention any special handling requirements',
                        'Note if items are urgent or time-sensitive',
                        'Specify any quality concerns or observations',
                        'Add context about why this transfer is needed',
                        'Keep it clear and concise for easy understanding',
                      ],
                    ),
                    child: Icon(Icons.help_outline, color: kPrimary, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _notesController,
                  cursorColor: kPrimary,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add any additional notes or instructions...',
                    hintStyle: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: kprimaryTextColor2,
                    ),
                    border: InputBorder.none,
                  ),
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: kprimaryTextColor1,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              GestureDetector(
                onTap: isLoading ? null : _submitRequisition,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isLoading ? Colors.grey : kPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isLoading
                      ? Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          'Submit Transfer',
                          textAlign: TextAlign.center,
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
        );
      },
    );
  }

  Widget _buildItemSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Item *',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kprimaryTextColor1,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _isOpened = !_isOpened;
              _isSearching = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedItemId == null && !_isSearching
                    ? Colors.grey.shade300
                    : kPrimary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: kprimaryTextColor2, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedItemName ?? 'Search and select an item',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: _selectedItemName != null
                          ? kprimaryTextColor1
                          : kprimaryTextColor2,
                    ),
                  ),
                ),
                Icon(
                  _isOpened ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                  color: kprimaryTextColor2,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (_isSearching && _isOpened) ...[
          const SizedBox(height: 12),
          _buildSearchDropdown(),
        ],
      ],
    );
  }

  Widget _buildSearchDropdown() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor1,
              ),
              decoration: InputDecoration(
                hintText: 'Type to search...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kprimaryTextColor2,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: kPrimary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No items found',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          color: kprimaryTextColor2,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredItems.length + 1, // +1 for footer
                    itemBuilder: (context, index) {
                      // Load more trigger
                      if (index == _filteredItems.length) {
                        final s = context.read<InventoryItemsBloc>().state;
                        if (s is InventoryItemsLoaded &&
                            s.hasMore &&
                            !s.isLoadingMore) {
                          // Trigger next page when user scrolls to bottom of dropdown
                          WidgetsBinding.instance.addPostFrameCallback((
                            _,
                          ) async {
                            context.read<InventoryItemsBloc>().add(
                              LoadMoreInventoryItems(organizationId: orgaID),
                            );
                          });
                        }
                        final s2 = context.read<InventoryItemsBloc>().state;
                        if (s2 is InventoryItemsLoaded && s2.isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final item = _filteredItems[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedItemId = item.id;
                            _selectedItemName = item.name;
                            _isSearching = false;
                            _isOpened = false;
                            _searchController.clear();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: kPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: kPrimary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: WorkSansAppTextStyles.medium
                                          .copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: kprimaryTextColor1,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.category,
                                      style: WorkSansAppTextStyles.medium
                                          .copyWith(
                                            fontSize: 12,
                                            color: kprimaryTextColor2,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityField() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Quantity *',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showHelpBottomSheet(
                      title: 'Quantity',
                      description:
                          'Enter the number of units you want to transfer for the selected item. Make sure the quantity doesn\'t exceed your available stock.',
                      tips: [
                        'Enter whole numbers only (no decimals)',
                        'Check your current stock before entering',
                        'Consider minimum stock levels in your branch',
                        'Transfer in batches if needed',
                        'You can add the same item multiple times if needed',
                      ],
                    ),
                    child: Icon(Icons.help_outline, color: kPrimary, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _quantityController,
                  cursorColor: kPrimary,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter quantity',
                    hintStyle: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: kprimaryTextColor2,
                    ),
                    border: InputBorder.none,
                  ),
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: kprimaryTextColor1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: GestureDetector(
            onTap: _addItemToList,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ),
      ],
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
              title: 'No Pending Transfers',
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
          title: 'No Pending Transfers',
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
          title: 'No Completed Transfer',
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
            color: Colors.black.withValues(alpha: 0.04),
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
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
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
          InkWell(
            onTap: () => _showTransferDetails(transfer, isPending),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                const Icon(Icons.arrow_forward_ios, size: 14, color: kPrimary),
              ],
            ),
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
                          'Transfer Details',
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
                                color: kPrimary.withValues(alpha: 0.1),
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
