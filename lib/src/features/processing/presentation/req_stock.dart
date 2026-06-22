import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/processing/bloc/req_stock/req_stock_bloc.dart';
import 'package:sandwich_ai/src/features/processing/data/model/req_stock_model.dart'
    as req;
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/inventory_items_repo.dart';

class RequestStockScreen extends StatefulWidget {
  const RequestStockScreen({super.key});

  @override
  State<RequestStockScreen> createState() => _RequestStockScreenState();
}

class _RequestStockScreenState extends State<RequestStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedItemId;
  String? _selectedItemName;
  String? _selectedItemUnit;
  double? _currentStock;
  double? _reorderLevel;
  bool _isSearching = false;
  bool _isOpened = false;

  List<InventoryItem> _filteredItems = [];
  List<InventoryItem> _allItems = [];
  List<req.StockRequestItemInput> _addedItems = [];
  BranchStockResponse? _branchStockData;

  String _branchId = '';
  String _department = '';
  String _orgID = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadUserData();

    // Load inventory items and branch stock
  }

  // Replace _loadUserData with this:
  Future<void> _loadUserData() async {
    final branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    final orgId = await AuthCacheHelper.instance.getOrgId() ?? '';
    final department =
        await AuthCacheHelper.instance.getDepartmentName() ?? 'Kitchen';

    if (mounted) {
      setState(() {
        _branchId = branchId;
        _department = department;
        _orgID = orgId;
      });

      // Fire AFTER we have the real orgId, with a higher limit
      if (orgId.isNotEmpty) {
        context.read<InventoryItemsBloc>().add(
          LoadInventoryItems(organizationId: orgId, page: 1, limit: 100),
        );
        context.read<BranchStockBloc>().add(
          LoadBranchStock(branchId: branchId),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
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

  /// AUTO-FILL: Get stock data for selected item
  Future<void> _autoFillStockData(String inventoryItemId) async {
    if (_branchStockData == null) {
      _showSnackBar('Loading stock data...', isError: false);
      return;
    }

    try {
      final stockItem = _branchStockData!.data.firstWhere(
        (item) => item.itemId == inventoryItemId,
        orElse: () => throw Exception('Item not found in branch stock'),
      );

      setState(() {
        _currentStock = stockItem.currentStockValue;
        _reorderLevel = stockItem.reorderLevelValue;

        // Auto-calculate quantity needed
        final shortage = _reorderLevel! - _currentStock!;

        if (shortage > 0) {
          // Request enough to reach reorder level + 20% buffer
          final recommendedQty = (shortage * 1.2).ceil();
          _qtyController.text = recommendedQty.toString();
        } else {
          // Stock is adequate, suggest maintaining level
          final maintainQty = (_reorderLevel! * 0.5).ceil();
          _qtyController.text = maintainQty.toString();
        }
      });

      _showSnackBar('Stock data auto-filled successfully');
    } catch (e) {
      _showSnackBar(
        'Stock data not available. Please enter manually.',
        isError: false,
      );
    }
  }

  /// QUICK ADD: Automatically add all low stock items
  Future<void> _quickAddLowStockItems() async {
    if (_branchStockData == null) {
      _showSnackBar('Loading stock data...', isError: false, isInfo: true);
      return;
    }

    // Get all low stock and out of stock items
    final lowStockItems = _branchStockData!.data.where((item) {
      return item.isAtOrBelowReorder || item.isOutOfStock;
    }).toList();

    if (lowStockItems.isEmpty) {
      _showSnackBar(
        'No low stock items found. All items are adequately stocked!',
      );
      return;
    }

    final selectedItems = await showDialog<List<String>>(
      context: context,
      builder: (context) => _buildLowStockSelectionDialog(lowStockItems),
    );

    if (selectedItems != null && selectedItems.isNotEmpty) {
      int addedCount = 0;

      for (var itemId in selectedItems) {
        final stockItem = lowStockItems.firstWhere(
          (item) => item.itemId == itemId,
        );

        // Find matching inventory item
        final inventoryItem = _allItems.firstWhere(
          (item) => item.id == itemId,
          orElse: () => InventoryItem(
            id: '',
            itemName: 'Unknown',
            category: '',
            unit: '',
            description: '',
            sku: '',
            organizationId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (inventoryItem.id.isNotEmpty) {
          _autoAddItemToList(stockItem, inventoryItem);
          addedCount++;
        }
      }

      _showSnackBar('$addedCount items added automatically!');
    }
  }

  void _autoAddItemToList(
    BranchStockItem stockItem,
    InventoryItem inventoryItem,
  ) {
    // Calculate shortage and recommended quantity
    final shortage = stockItem.reorderLevelValue - stockItem.currentStockValue;
    final qtyNeeded = shortage > 0
        ? (shortage * 1.2).ceil()
        : (stockItem.reorderLevelValue * 0.5).ceil();

    // Check if item already added
    if (_addedItems.any((item) => item.itemId == inventoryItem.id)) {
      return;
    }

    setState(() {
      _addedItems.add(
        req.StockRequestItemInput(
          itemId: inventoryItem.id,
          qtyRequested: qtyNeeded,
        ),
      );
    });
  }

  Widget _buildLowStockSelectionDialog(List<BranchStockItem> lowStockItems) {
    final selectedIds = <String>{};

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(
            'Quick Add Low Stock Items',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select items to add to stock request:',
                  style: WorkSansAppTextStyles.medium.copyWith(fontSize: 14),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: lowStockItems.length,
                    itemBuilder: (context, index) {
                      final stockItem = lowStockItems[index];
                      final isSelected = selectedIds.contains(stockItem.itemId);

                      return CheckboxListTile(
                        title: Text(
                          stockItem.item.itemName,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current: ${stockItem.currentStock} ${stockItem.item.unit}',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Reorder Level: ${stockItem.reorderLevel} ${stockItem.item.unit}',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                            if (stockItem.isOutOfStock)
                              Container(
                                margin: EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'OUT OF STOCK',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedIds.add(stockItem.itemId);
                            } else {
                              selectedIds.remove(stockItem.itemId);
                            }
                          });
                        },
                        activeColor: kPrimary,
                        checkColor: Colors.white,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: kprimaryTextColor2),
              ),
            ),
            ElevatedButton(
              onPressed: selectedIds.isEmpty
                  ? null
                  : () => Navigator.pop(context, selectedIds.toList()),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                disabledBackgroundColor: kPrimary.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
              ),
              child: Text('Add Selected (${selectedIds.length})'),
            ),
          ],
        );
      },
    );
  }

  void _onItemSelected(InventoryItem item) {
    setState(() {
      _selectedItemId = item.id;
      _selectedItemName = item.name;
      _selectedItemUnit = item.unit;
      _isSearching = false;
      _isOpened = false;
      _searchController.clear();
    });

    // Auto-fill stock data
    _autoFillStockData(item.id);
  }

  void _addItemToList() {
    if (_selectedItemId == null) {
      _showSnackBar('Please select an item', isError: true);
      return;
    }

    if (_qtyController.text.isEmpty) {
      _showSnackBar('Please enter quantity', isError: true);
      return;
    }

    final qty = int.tryParse(_qtyController.text.trim());

    if (qty == null || qty <= 0) {
      _showSnackBar('Please enter a valid quantity', isError: true);
      return;
    }

    if (_addedItems.any((item) => item.itemId == _selectedItemId)) {
      _showSnackBar('Item already added to the list', isError: true);
      return;
    }

    setState(() {
      _addedItems.add(
        req.StockRequestItemInput(itemId: _selectedItemId!, qtyRequested: qty),
      );

      _selectedItemId = null;
      _selectedItemName = null;
      _selectedItemUnit = null;
      _currentStock = null;
      _reorderLevel = null;
      _qtyController.clear();
      _isSearching = false;
      _isOpened = false;
    });

    _showSnackBar('Item added to request');
  }

  void _removeItemFromList(int index) {
    setState(() {
      _addedItems.removeAt(index);
    });
    _showSnackBar('Item removed from list');
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    if (_addedItems.isEmpty) {
      _showSnackBar('Please add at least one item', isError: true);
      return;
    }

    if (_branchId.isEmpty) {
      _showSnackBar('Branch ID not found. Please login again.', isError: true);
      return;
    }

    try {
      final request = req.CreateStockRequestRequest(
        requestingBranchId: _branchId,
        requestedBy: _department,
        department: _department,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        items: _addedItems,
      );

      context.read<StockRequestBloc>().add(
        CreateStockRequest(request: request),
      );
    } catch (e) {
      _showSnackBar('Invalid input: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isInfo = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: WorkSansAppTextStyles.medium.copyWith(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : isInfo
            ? kBlue
            : kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<StockRequestBloc, StockRequestState>(
          listener: (context, state) {
            if (state is StockRequestCreated) {
              _showSnackBar('Stock request created successfully!');
              Future.delayed(const Duration(milliseconds: 1500), () {
                // if (mounted) {
                //   Navigator.pop(context, true);
                // }
              });
            } else if (state is StockRequestError) {
              _showSnackBar(state.error, isError: true);
            }
          },
        ),
        BlocListener<InventoryItemsBloc, InventoryItemsState>(
          listener: (context, state) {
            if (state is InventoryItemsLoaded && !state.isLoadingMore) {
              setState(() {
                _allItems =
                    state.items; // bloc already holds full appended list
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
            if (state is InventoryItemsLoaded) {
              setState(() {
                _allItems = state.items;
                _filteredItems = state.items;
              });
            } else if (state is InventoryItemsError) {
              _showSnackBar(
                'Failed to load inventory items: ${state.error}',
                isError: true,
              );
            }
          },
        ),
        BlocListener<BranchStockBloc, BranchStockState>(
          listener: (context, state) {
            if (state is BranchStockLoaded) {
              setState(() {
                _branchStockData = state.response;
              });
            }
          },
        ),
      ],
      child: BlocBuilder<InventoryItemsBloc, InventoryItemsState>(
        builder: (context, inventoryState) {
          final isLoadingInventory = inventoryState is InventoryItemsLoading;

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final horizontalPadding = _getHorizontalPadding(screenWidth);
              final maxContentWidth = _getMaxContentWidth(screenWidth);

              return Scaffold(
                resizeToAvoidBottomInset: true,
                backgroundColor: const Color(0xFFF8F6F6),
                // appBar: _buildAppBar(screenWidth),
                body: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: isLoadingInventory
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                kPrimary,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: EdgeInsets.zero,
                            // ADD THIS:
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: horizontalPadding,
                                right: horizontalPadding,
                                top: _getVerticalPadding(
                                  screenWidth,
                                ), // ← ADD TOP PADDING
                                bottom: _getVerticalPadding(screenWidth),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Info banner
                                    _buildInfoBanner(screenWidth),
                                    SizedBox(
                                      height:
                                          _getSectionSpacing(screenWidth) * 3,
                                    ),

                                    // Quick Add Section
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildSectionTitle(
                                          'Add Items',
                                          screenWidth,
                                        ),
                                        // TextButton.icon(
                                        //   onPressed: _quickAddLowStockItems,
                                        //   icon: Icon(
                                        //     Icons.flash_on,
                                        //     size: 18,
                                        //     color: kPrimary,
                                        //   ),
                                        //   label: Text(
                                        //     'Quick Add Low Stock',
                                        //     style: WorkSansAppTextStyles.medium
                                        //         .copyWith(
                                        //           color: kPrimary,
                                        //           fontSize: 13,
                                        //           fontWeight: FontWeight.w600,
                                        //         ),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: _getSectionSpacing(screenWidth),
                                    ),

                                    // Item selection
                                    _buildItemSearchField(screenWidth),

                                    if (_selectedItemId != null) ...[
                                      SizedBox(
                                        height: _getFieldSpacing(screenWidth),
                                      ),
                                      _buildAutoFilledFields(screenWidth),
                                    ],

                                    if (_addedItems.isNotEmpty) ...[
                                      SizedBox(
                                        height:
                                            _getSectionSpacing(screenWidth) * 2,
                                      ),
                                      _buildAddedItemsList(screenWidth),
                                    ],

                                    SizedBox(
                                      height:
                                          _getSectionSpacing(screenWidth) * 2,
                                    ),

                                    // Notes field
                                    _buildNotesField(screenWidth),

                                    SizedBox(
                                      height:
                                          _getSectionSpacing(screenWidth) * 2,
                                    ),

                                    // Submit button
                                    _buildSubmitButton(screenWidth),
                                    SizedBox(
                                      height: _getVerticalPadding(screenWidth),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(double screenWidth) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: kprimaryTextColor1,
          size: _getIconSize(screenWidth),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'New Stock Request',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getAppBarTitleFontSize(screenWidth),
          fontWeight: FontWeight.w600,
          color: kprimaryTextColor1,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline, color: kPrimary),
          onPressed: () {
            _showSnackBar(
              '💡 Tip: Use Quick Add to automatically add low stock items!',
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoBanner(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimary.withValues(alpha: 0.1),
            kPrimary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: kPrimary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automated Stock Request',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Stock levels and quantities are auto-calculated based on your inventory',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    color: kprimaryTextColor2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, double screenWidth) {
    return Text(
      title,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: _getSectionTitleFontSize(screenWidth),
        fontWeight: FontWeight.w600,
        color: kprimaryTextColor1,
      ),
    );
  }

  Widget _buildItemSearchField(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Select Item *',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getLabelFontSize(screenWidth),
                fontWeight: FontWeight.w500,
                color: kprimaryTextColor1,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.help_outline,
              color: kPrimary,
              size: _getIconSize(screenWidth) - 4,
            ),
          ],
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            setState(() {
              _isOpened = !_isOpened;
              _isSearching = true;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getInputPaddingHorizontal(screenWidth),
              vertical: _getInputPaddingVertical(screenWidth),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              border: Border.all(
                color: _selectedItemId == null && _isSearching == false
                    ? const Color(0xFFE0E0E0)
                    : kPrimary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: kprimaryTextColor2,
                  size: _getIconSize(screenWidth),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedItemName ?? 'Search and select an item',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getInputFontSize(screenWidth),
                      fontWeight: FontWeight.w400,
                      color: _selectedItemName != null
                          ? kprimaryTextColor1
                          : kprimaryTextColor2,
                    ),
                  ),
                ),
                Icon(
                  _isOpened ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                  color: kprimaryTextColor2,
                  size: _getIconSize(screenWidth) + 4,
                ),
              ],
            ),
          ),
        ),
        if (_isSearching && _isOpened) ...[
          SizedBox(height: 12),
          _buildSearchDropdown(screenWidth),
        ],
      ],
    );
  }

  Widget _buildSearchDropdown(double screenWidth) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
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
            padding: EdgeInsets.all(_getInputPaddingHorizontal(screenWidth)),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                color: kprimaryTextColor1,
              ),
              decoration: InputDecoration(
                hintText: 'Type to search...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getInputFontSize(screenWidth),
                  color: kprimaryTextColor2,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: kprimaryTextColor2,
                  size: _getIconSize(screenWidth),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: kprimaryTextColor2,
                          size: _getIconSize(screenWidth),
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(screenWidth),
                  ),
                  borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(screenWidth),
                  ),
                  borderSide: BorderSide(color: kPrimary, width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: _getInputPaddingHorizontal(screenWidth),
                  vertical: _getInputPaddingVertical(screenWidth),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(
                        _getInputPaddingHorizontal(screenWidth),
                      ),
                      child: Text(
                        'No items found',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: _getInputFontSize(screenWidth),
                          color: kprimaryTextColor2,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredItems.length + 1, // +1 for footer
                    itemBuilder: (context, index) {
                      if (index == _filteredItems.length) {
                        final s = context.read<InventoryItemsBloc>().state;
                        if (s is InventoryItemsLoaded &&
                            s.hasMore &&
                            !s.isLoadingMore) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.read<InventoryItemsBloc>().add(
                              LoadMoreInventoryItems(organizationId: _orgID),
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
                        onTap: () => _onItemSelected(item),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _getInputPaddingHorizontal(screenWidth),
                            vertical: _getInputPaddingVertical(screenWidth),
                          ),
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
                                width: _getIconSize(screenWidth) + 8,
                                height: _getIconSize(screenWidth) + 8,
                                decoration: BoxDecoration(
                                  color: kPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: kPrimary,
                                  size: _getIconSize(screenWidth) - 4,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: WorkSansAppTextStyles.medium
                                          .copyWith(
                                            fontSize: _getInputFontSize(
                                              screenWidth,
                                            ),
                                            fontWeight: FontWeight.w600,
                                            color: kprimaryTextColor1,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.category} • ${item.unit}',
                                      style: WorkSansAppTextStyles.medium
                                          .copyWith(
                                            fontSize: _getCaptionFontSize(
                                              screenWidth,
                                            ),
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

  Widget _buildAutoFilledFields(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: kPrimary, size: 20),
              SizedBox(width: 8),
              Text(
                'Auto-filled Data',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Stock info display
          if (_currentStock != null && _reorderLevel != null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Current Stock',
                    '${_currentStock!.toStringAsFixed(0)} $_selectedItemUnit',
                    Icons.inventory,
                    Colors.blue,
                    screenWidth,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Reorder Level',
                    '${_reorderLevel!.toStringAsFixed(0)} $_selectedItemUnit',
                    Icons.warning_amber,
                    Colors.orange,
                    screenWidth,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],

          // Quantity field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quantity Requested *',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getLabelFontSize(screenWidth),
                  fontWeight: FontWeight.w500,
                  color: kprimaryTextColor1,
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getInputFontSize(screenWidth),
                  fontWeight: FontWeight.w400,
                  color: kprimaryTextColor1,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter quantity',
                  hintStyle: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getInputFontSize(screenWidth),
                    fontWeight: FontWeight.w400,
                    color: kprimaryTextColor2,
                  ),
                  suffix: _selectedItemUnit != null
                      ? Text(
                          _selectedItemUnit!,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getInputFontSize(screenWidth),
                            color: kprimaryTextColor2,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      _getBorderRadius(screenWidth),
                    ),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      _getBorderRadius(screenWidth),
                    ),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      _getBorderRadius(screenWidth),
                    ),
                    borderSide: BorderSide(color: kPrimary, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: _getInputPaddingHorizontal(screenWidth),
                    vertical: _getInputPaddingVertical(screenWidth),
                  ),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
            ],
          ),
          SizedBox(height: 16),

          // Add button
          SizedBox(
            width: double.infinity,
            height: _getButtonHeight(screenWidth) - 8,
            child: OutlinedButton.icon(
              onPressed: _addItemToList,
              icon: Icon(
                Icons.add_circle_outline,
                size: _getIconSize(screenWidth),
              ),
              label: Text(
                'Add Item to Request',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getButtonFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: BorderSide(color: kPrimary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(screenWidth),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double screenWidth,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 11,
                    color: kprimaryTextColor2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddedItemsList(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items in Request (${_addedItems.length})',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getSectionTitleFontSize(screenWidth),
            fontWeight: FontWeight.w600,
            color: kprimaryTextColor1,
          ),
        ),
        SizedBox(height: _getSectionSpacing(screenWidth)),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _addedItems.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _addedItems[index];
            final itemInfo = _allItems.firstWhere(
              (inv) => inv.id == item.itemId,
              orElse: () => InventoryItem(
                id: '',
                itemName: 'Unknown',
                category: '',
                unit: '',
                description: '',
                sku: '',
                organizationId: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

            return Container(
              padding: EdgeInsets.all(_getInputPaddingHorizontal(screenWidth)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  _getBorderRadius(screenWidth),
                ),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: _getIconSize(screenWidth) + 8,
                    height: _getIconSize(screenWidth) + 8,
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: kPrimary,
                      size: _getIconSize(screenWidth) - 4,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemInfo.name,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getInputFontSize(screenWidth),
                            fontWeight: FontWeight.w600,
                            color: kprimaryTextColor1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Quantity: ${item.qtyRequested} ${itemInfo.unit}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getCaptionFontSize(screenWidth),
                            color: kprimaryTextColor2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: const Color(0xFFE53935),
                      size: _getIconSize(screenWidth),
                    ),
                    onPressed: () => _removeItemFromList(index),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotesField(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w500,
            color: kprimaryTextColor1,
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth),
            fontWeight: FontWeight.w400,
            color: kprimaryTextColor1,
          ),
          decoration: InputDecoration(
            hintText: 'Add any additional notes for this request',
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              fontWeight: FontWeight.w400,
              color: kprimaryTextColor2,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: kPrimary, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: _getInputPaddingHorizontal(screenWidth),
              vertical: _getInputPaddingVertical(screenWidth),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(double screenWidth) {
    return BlocBuilder<StockRequestBloc, StockRequestState>(
      builder: (context, state) {
        final isLoading = state is StockRequestCreating;

        return SizedBox(
          width: double.infinity,
          height: _getButtonHeight(screenWidth),
          child: ElevatedButton(
            onPressed: isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              disabledBackgroundColor: kPrimary.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  _getBorderRadius(screenWidth),
                ),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? SizedBox(
                    height: _getIconSize(screenWidth),
                    width: _getIconSize(screenWidth),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Submit Stock Request',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getButtonFontSize(screenWidth),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }

  // Responsive sizing functions
  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 32;
    return 48;
  }

  double _getMaxContentWidth(double width) {
    if (width < 600) return double.infinity;
    if (width < 900) return 600;
    return 700;
  }

  double _getVerticalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getSectionSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getFieldSpacing(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getAppBarTitleFontSize(double width) {
    if (width < 360) return 17;
    if (width < 600) return 18;
    return 19;
  }

  double _getSectionTitleFontSize(double width) {
    if (width < 360) return 16;
    if (width < 600) return 17;
    return 18;
  }

  double _getLabelFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getInputFontSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }

  double _getCaptionFontSize(double width) {
    if (width < 360) return 11;
    if (width < 600) return 12;
    return 13;
  }

  double _getButtonFontSize(double width) {
    if (width < 360) return 15;
    if (width < 600) return 16;
    return 17;
  }

  double _getIconSize(double width) {
    if (width < 360) return 20;
    if (width < 600) return 22;
    return 24;
  }

  double _getButtonHeight(double width) {
    if (width < 360) return 48;
    if (width < 600) return 52;
    return 56;
  }

  double _getBorderRadius(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getInputPaddingHorizontal(double width) {
    if (width < 360) return 14;
    if (width < 600) return 16;
    return 18;
  }

  double _getInputPaddingVertical(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }
}
