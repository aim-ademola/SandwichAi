import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/utils/debouncer.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/stock_reuest_model.dart'
    as stock;
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
  late final Debouncer _searchDebouncer;

  List<InventoryItem> _filteredItems = [];
  List<InventoryItem> _allItems = [];
  final List<stock.CreateStockRequestItem> _addedItems = [];
  BranchStockResponse? _branchStockData;

  String _branchId = '';
  String _branchName = '';
  String _employeeId = '';
  String _department = '';
  String _orgID = '';
  bool _isInterbranch = false;
  bool _isLoadingBranches = false;
  String? _selectedIssuingBranchId;
  List<_StockRequestBranch> _branches = [];

  @override
  void initState() {
    super.initState();
    _searchDebouncer = Debouncer(
      delay: const Duration(milliseconds: 350),
    );
    _searchController.addListener(_onSearchChanged);
    _loadUserData();

    // Load inventory items and branch stock
  }

  // Replace _loadUserData with this:
  Future<void> _loadUserData() async {
    final branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    final branchName = await AuthCacheHelper.instance.getBranchName() ?? '';
    final orgId = await AuthCacheHelper.instance.getOrgId() ?? '';
    final userData = await AuthCacheHelper.instance.getUserData();
    final department =
        await AuthCacheHelper.instance.getDepartmentName() ?? 'Kitchen';

    if (mounted) {
      setState(() {
        _branchId = branchId;
        _branchName = branchName;
        _employeeId = userData?.id ?? '';
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
        await _loadBranches();
      }
    }
  }

  bool get _canCreateInterbranch =>
      _department.trim().toLowerCase().contains('procurement');

  String get _sourceBranchId =>
      _isInterbranch ? (_selectedIssuingBranchId ?? '') : _branchId;

  String get _sourceBranchLabel {
    if (!_isInterbranch) {
      return _branchName.isEmpty ? 'your branch Stock Control' : _branchName;
    }
    final selected = _branches.where((branch) {
      return branch.id == _selectedIssuingBranchId;
    });
    if (selected.isEmpty) return 'selected issuing branch';
    return selected.first.displayName;
  }

  Future<void> _loadBranches() async {
    if (!_canCreateInterbranch) return;

    setState(() => _isLoadingBranches = true);
    final branches = await _StockRequestBranchDirectory().loadBranches(
      fallbackBranch: _StockRequestBranch(id: _branchId, name: _branchName),
    );
    if (!mounted) return;

    setState(() {
      _branches = branches
          .where((branch) => branch.id.isNotEmpty && branch.id != _branchId)
          .toList();
      _isLoadingBranches = false;
    });
  }

  void _setRequestType(bool isInterbranch) {
    if (isInterbranch && !_canCreateInterbranch) return;

    setState(() {
      _isInterbranch = isInterbranch;
      _selectedIssuingBranchId = null;
      _branchStockData = null;
      _addedItems.clear();
      _clearSelectedItem();
    });

    if (!isInterbranch && _branchId.isNotEmpty) {
      context.read<BranchStockBloc>().add(LoadBranchStock(branchId: _branchId));
    }
  }

  void _selectIssuingBranch(String? branchId) {
    if (branchId == null || branchId.isEmpty || branchId == _branchId) return;

    setState(() {
      _selectedIssuingBranchId = branchId;
      _branchStockData = null;
      _addedItems.clear();
      _clearSelectedItem();
    });

    context.read<BranchStockBloc>().add(LoadBranchStock(branchId: branchId));
  }

  void _clearSelectedItem() {
    _selectedItemId = null;
    _selectedItemName = null;
    _selectedItemUnit = null;
    _currentStock = null;
    _reorderLevel = null;
    _qtyController.clear();
    _isSearching = false;
    _isOpened = false;
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _filterInventoryItems(_allItems, query);
      }
    });

    if (_orgID.isEmpty) return;

    _searchDebouncer.cancel();
    _searchDebouncer(() {
      if (!mounted) return;
      context.read<InventoryItemsBloc>().add(
        LoadInventoryItems(
          organizationId: _orgID,
          page: 1,
          limit: 100,
          search: query,
        ),
      );
    });
  }

  List<InventoryItem> _filterInventoryItems(
    List<InventoryItem> items,
    String query,
  ) {
    return items.where((item) {
      final searchableText = [
        item.name,
        item.category,
        item.unit,
        item.sku,
        item.description,
      ].join(' ');

      return _containsSearchQuery(searchableText, query);
    }).toList();
  }

  bool _containsSearchQuery(String source, String query) {
    final normalizedSource = _normalizeSearchText(source);
    final queryTokens = _normalizeSearchText(
      query,
    ).split(' ').where((token) => token.isNotEmpty);

    return queryTokens.every(normalizedSource.contains);
  }

  String _normalizeSearchText(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  /// AUTO-FILL: Get stock data for selected item
  Future<void> _autoFillStockData(String inventoryItemId) async {
    if (_sourceBranchId.isEmpty) {
      _showSnackBar('Select a source branch first.', isError: true);
      return;
    }

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

      _showSnackBar('Stock availability loaded', isInfo: true);
    } catch (e) {
      setState(() {
        _currentStock = 0;
        _reorderLevel = 0;
        _qtyController.clear();
      });
      _showSnackBar(
        'This item is not available in $_sourceBranchLabel.',
        isError: true,
      );
    }
  }

  /// QUICK ADD: Automatically add all low stock items
  // ignore: unused_element
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
        ? (shortage * 1.2).ceilToDouble()
        : (stockItem.reorderLevelValue * 0.5).ceilToDouble();

    // Check if item already added
    if (_addedItems.any((item) => item.itemId == inventoryItem.id)) {
      return;
    }

    setState(() {
      _addedItems.add(
        stock.CreateStockRequestItem(
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
          backgroundColor: context.modeSurface,
          title: Text(
            'Quick Add Low Stock Items',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
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
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: context.modeTextSecondary,
                  ),
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
                            color: context.modeTextPrimary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current: ${stockItem.currentStock} ${stockItem.item.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.modeTextSecondary,
                              ),
                            ),
                            Text(
                              'Reorder Level: ${stockItem.reorderLevel} ${stockItem.item.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.modeError,
                              ),
                            ),
                            if (stockItem.isOutOfStock)
                              Container(
                                margin: EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.modeError.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'OUT OF STOCK',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.modeError,
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
                        activeColor: context.modePrimary,
                        checkColor: context.modeTextInverse,
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
                style: TextStyle(color: context.modeTextSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: selectedIds.isEmpty
                  ? null
                  : () => Navigator.pop(context, selectedIds.toList()),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                disabledBackgroundColor: context.modePrimary.withValues(
                  alpha: 0.3,
                ),
                foregroundColor: context.modeTextInverse,
              ),
              child: Text('Add Selected (${selectedIds.length})'),
            ),
          ],
        );
      },
    );
  }

  void _onItemSelected(InventoryItem item) {
    if (_sourceBranchId.isEmpty) {
      _showSnackBar('Select a source branch first.', isError: true);
      return;
    }

    setState(() {
      _selectedItemId = item.id;
      _selectedItemName = item.name;
      _selectedItemUnit = item.unit;
      _isSearching = false;
      _isOpened = false;
      _searchDebouncer.cancel();
      _searchController.clear();
      _filteredItems = _allItems;
    });

    // Auto-fill stock data
    _autoFillStockData(item.id);
  }

  void _addItemToList() {
    if (_selectedItemId == null) {
      _showSnackBar('Please select an item', isError: true);
      return;
    }

    if (_sourceBranchId.isEmpty) {
      _showSnackBar('Select a source branch first.', isError: true);
      return;
    }

    if (_qtyController.text.isEmpty) {
      _showSnackBar('Please enter quantity', isError: true);
      return;
    }

    final qty = double.tryParse(_qtyController.text.trim());

    if (qty == null || qty <= 0) {
      _showSnackBar('Please enter a valid quantity', isError: true);
      return;
    }

    if (_currentStock == null) {
      _showSnackBar(
        'Stock availability is still loading. Please wait.',
        isError: true,
      );
      return;
    }

    if (_currentStock != null && qty > _currentStock!) {
      _showSnackBar(
        'Only ${_currentStock!.toStringAsFixed(2)} $_selectedItemUnit available in $_sourceBranchLabel.',
        isError: true,
      );
      return;
    }

    if (_addedItems.any((item) => item.itemId == _selectedItemId)) {
      _showSnackBar('Item already added to the list', isError: true);
      return;
    }

    setState(() {
      _addedItems.add(
        stock.CreateStockRequestItem(
          itemId: _selectedItemId!,
          qtyRequested: qty,
        ),
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

    if (_employeeId.isEmpty) {
      _showSnackBar(
        'Employee ID not found. Please login again.',
        isError: true,
      );
      return;
    }

    if (_isInterbranch) {
      if (!_canCreateInterbranch) {
        _showSnackBar(
          'Only Procurement can create interbranch stock requests.',
          isError: true,
        );
        return;
      }
      if (_selectedIssuingBranchId == null ||
          _selectedIssuingBranchId!.isEmpty) {
        _showSnackBar('Please select the issuing branch.', isError: true);
        return;
      }
      if (_selectedIssuingBranchId == _branchId) {
        _showSnackBar(
          'Issuing branch must be different from your branch.',
          isError: true,
        );
        return;
      }
    }

    try {
      final request = stock.CreateStockRequestRequest(
        requestingBranchId: _branchId,
        issuingBranchId: _isInterbranch ? _selectedIssuingBranchId : null,
        requestedBy: _employeeId,
        department: _department,
        notes: _notesController.text.trim().isEmpty
            ? ''
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
            color: context.modeTextInverse,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError
            ? context.modeError
            : isInfo
            ? context.modeInfo
            : context.modeSuccess,
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
                _allItems = state.items;
                _filteredItems = _searchController.text.isEmpty
                    ? _allItems
                    : _filterInventoryItems(_allItems, _searchController.text);
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
            } else if (state is BranchStockError) {
              _showSnackBar(
                'Failed to load source stock: ${state.error}',
                isError: true,
              );
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
                backgroundColor: context.modeBackground,
                body: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: isLoadingInventory
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.modePrimary,
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
                                ), // â† ADD TOP PADDING
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

                                    _buildRequestSourceSection(screenWidth),
                                    SizedBox(
                                      height:
                                          _getSectionSpacing(screenWidth) * 3,
                                    ),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildSectionTitle(
                                          'Add Items',
                                          screenWidth,
                                        ),
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

  // ignore: unused_element
  PreferredSizeWidget _buildAppBar(double screenWidth) {
    return AppBar(
      backgroundColor: context.modeSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: AppIcon(
          Icons.arrow_back,
          color: context.modeTextPrimary,
          size: _getIconSize(screenWidth),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'New Stock Request',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getAppBarTitleFontSize(screenWidth),
          fontWeight: FontWeight.w600,
          color: context.modeTextPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: AppIcon(Icons.info_outline, color: context.modePrimary),
          onPressed: () {
            _showSnackBar(
              'ðŸ’¡ Tip: Use Quick Add to automatically add low stock items!',
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
            context.modePrimary.withValues(alpha: 0.1),
            context.modePrimary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: context.modePrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          AppIcon(Icons.auto_awesome, color: context.modePrimary, size: 24),
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
                    color: context.modePrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check source branch availability before submitting a request',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    color: context.modeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSourceSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Request Source', screenWidth),
        SizedBox(height: _getSectionSpacing(screenWidth)),
        if (_canCreateInterbranch) _buildRequestTypeSelector(screenWidth),
        if (_canCreateInterbranch && _isInterbranch) ...[
          SizedBox(height: _getSectionSpacing(screenWidth) * 2),
          _buildIssuingBranchSelector(screenWidth),
          if (_selectedIssuingBranchId != null) ...[
            SizedBox(height: _getFieldSpacing(screenWidth)),
            _buildSourceBranchNote(),
          ],
        ],
        if (!_canCreateInterbranch || !_isInterbranch) ...[
          SizedBox(height: _getFieldSpacing(screenWidth)),
          _buildSourceBranchNote(),
        ],
      ],
    );
  }

  Widget _buildRequestTypeSelector(double screenWidth) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption(
            title: 'Interdepartment',
            subtitle: 'Request from your branch Stock Control',
            icon: Icons.storefront_outlined,
            selected: !_isInterbranch,
            onTap: () => _setRequestType(false),
            screenWidth: screenWidth,
          ),
        ),
        SizedBox(width: _getFieldSpacing(screenWidth)),
        Expanded(
          child: _buildTypeOption(
            title: 'Interbranch',
            subtitle: 'Request from another branch',
            icon: Icons.sync_alt_outlined,
            selected: _isInterbranch,
            onTap: () => _setRequestType(true),
            screenWidth: screenWidth,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? context.modePrimary.withValues(alpha: 0.08)
              : context.modeSurface,
          borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
          border: Border.all(
            color: selected ? context.modePrimary : context.modeBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(
                  icon,
                  color: selected
                      ? context.modePrimary
                      : context.modeTextSecondary,
                  size: _getIconSize(screenWidth),
                ),
                const Spacer(),
                AppIcon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? context.modePrimary
                      : context.modeTextSecondary,
                  size: _getIconSize(screenWidth),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getCaptionFontSize(screenWidth),
                color: context.modeTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuingBranchSelector(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Issuing Branch *',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w500,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedIssuingBranchId,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: context.modeSurface,
            prefixIcon: AppIconSlot(
              Icons.account_tree_outlined,
              color: context.modePrimary,
              size: _getIconSize(screenWidth),
            ),
            prefixIconConstraints: AppIconSlot.constraints(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modeBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modeBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modePrimary, width: 1.5),
            ),
          ),
          hint: Text(
            _isLoadingBranches ? 'Loading branches...' : 'Select source branch',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              color: context.modeTextSecondary,
            ),
          ),
          items: _branches.map((branch) {
            return DropdownMenuItem<String>(
              value: branch.id,
              child: Text(
                branch.displayName,
                overflow: TextOverflow.ellipsis,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getInputFontSize(screenWidth),
                  color: context.modeTextPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: _branches.isEmpty ? null : _selectIssuingBranch,
          validator: (_) {
            if (_isInterbranch &&
                (_selectedIssuingBranchId == null ||
                    _selectedIssuingBranchId!.isEmpty)) {
              return 'Please select issuing branch';
            }
            return null;
          },
        ),
        if (_branches.isEmpty && !_isLoadingBranches) ...[
          const SizedBox(height: 8),
          Text(
            'No external branches found. Please confirm branch endpoint with backend.',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getCaptionFontSize(screenWidth),
              color: context.modeWarning,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSourceBranchNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder),
      ),
      child: Row(
        children: [
          AppIcon(Icons.inventory_2_outlined, color: context.modePrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Availability will be checked from $_sourceBranchLabel.',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: context.modeTextSecondary,
              ),
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
        color: context.modeTextPrimary,
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
                color: context.modeTextPrimary,
              ),
            ),
            SizedBox(width: 8),
            AppIcon(
              Icons.help_outline,
              color: context.modePrimary,
              size: _getIconSize(screenWidth) - 4,
            ),
          ],
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            if (_sourceBranchId.isEmpty) {
              _showSnackBar('Select a source branch first.', isError: true);
              return;
            }
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
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              border: Border.all(
                color: _selectedItemId == null && _isSearching == false
                    ? context.modeBorder
                    : context.modePrimary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                AppIcon(
                  Icons.search,
                  color: context.modeTextSecondary,
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
                          ? context.modeTextPrimary
                          : context.modeTextSecondary,
                    ),
                  ),
                ),
                AppIcon(
                  _isOpened ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                  color: context.modeTextSecondary,
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
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: context.modeBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.08),
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
                color: context.modeTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Type to search...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getInputFontSize(screenWidth),
                  color: context.modeTextSecondary,
                ),
                prefixIcon: AppIconSlot(
                  Icons.search,
                  color: context.modeTextSecondary,
                  size: _getIconSize(screenWidth),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: AppIcon(
                          Icons.clear,
                          color: context.modeTextSecondary,
                          size: _getIconSize(screenWidth),
                        ),
                        onPressed: () {
                          _searchDebouncer.cancel();
                          _searchController.clear();
                          setState(() => _filteredItems = _allItems);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(screenWidth),
                  ),
                  borderSide: BorderSide(color: context.modeBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(screenWidth),
                  ),
                  borderSide: BorderSide(
                    color: context.modePrimary,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: _getInputPaddingHorizontal(screenWidth),
                  vertical: _getInputPaddingVertical(screenWidth),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: context.modeDivider),
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
                          color: context.modeTextSecondary,
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
                      final branchStockItem = _branchStockForItem(item.id);
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
                                color: context.modeDivider,
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
                                  color: context.modePrimary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: AppIcon(
                                  Icons.inventory_2_outlined,
                                  color: context.modePrimary,
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
                                            color: context.modeTextPrimary,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.category} - ${item.unit}',
                                      style: WorkSansAppTextStyles.medium
                                          .copyWith(
                                            fontSize: _getCaptionFontSize(
                                              screenWidth,
                                            ),
                                            color: context.modeTextSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _availabilityLabel(
                                        branchStockItem,
                                        item.unit,
                                      ),
                                      style: WorkSansAppTextStyles.medium
                                          .copyWith(
                                            fontSize: _getCaptionFontSize(
                                              screenWidth,
                                            ),
                                            color: _availabilityColor(
                                              branchStockItem,
                                            ),
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

  BranchStockItem? _branchStockForItem(String itemId) {
    final data = _branchStockData;
    if (data == null) return null;
    for (final stockItem in data.data) {
      if (stockItem.itemId == itemId || stockItem.item.id == itemId) {
        return stockItem;
      }
    }
    return null;
  }

  String _availabilityLabel(BranchStockItem? stockItem, String fallbackUnit) {
    if (stockItem == null || stockItem.currentStockValue <= 0) {
      return 'Not available in $_sourceBranchLabel';
    }
    return 'Available: ${stockItem.currentStock} ${stockItem.item.unit.isEmpty ? fallbackUnit : stockItem.item.unit}';
  }

  Color _availabilityColor(BranchStockItem? stockItem) {
    if (stockItem == null || stockItem.currentStockValue <= 0) {
      return context.modeError;
    }
    if (stockItem.isAtOrBelowReorder || stockItem.isNearReorder) {
      return context.modeWarning;
    }
    return context.modeTextSecondary;
  }

  Widget _buildAutoFilledFields(double screenWidth) {
    final isUnavailable = _currentStock != null && _currentStock! <= 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modePrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: context.modePrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(Icons.auto_awesome, color: context.modePrimary, size: 20),
              SizedBox(width: 8),
              Text(
                'Source Availability',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.modePrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_currentStock != null && _reorderLevel != null) ...[
            if (isUnavailable)
              _buildUnavailableStockState(screenWidth)
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Current Stock',
                      '${_currentStock!.toStringAsFixed(0)} $_selectedItemUnit',
                      Icons.inventory,
                      context.modeInfo,
                      screenWidth,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      'Reorder Level',
                      '${_reorderLevel!.toStringAsFixed(0)} $_selectedItemUnit',
                      Icons.warning_amber,
                      context.modeWarning,
                      screenWidth,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildQuantityField(screenWidth),
              SizedBox(height: 16),
              _buildAddItemButton(screenWidth),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildUnavailableStockState(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: context.modeError.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: context.modeError.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.modeError.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                Icons.inventory_2_outlined,
                color: context.modeError,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Item not available',
            textAlign: TextAlign.center,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'There is no stock for this item in $_sourceBranchLabel.',
            textAlign: TextAlign.center,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getCaptionFontSize(screenWidth),
              color: context.modeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityField(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity Requested *',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w500,
            color: context.modeTextPrimary,
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _qtyController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth),
            fontWeight: FontWeight.w400,
            color: context.modeTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Enter quantity',
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              fontWeight: FontWeight.w400,
              color: context.modeTextSecondary,
            ),
            suffix: _selectedItemUnit != null
                ? Text(
                    _selectedItemUnit!,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getInputFontSize(screenWidth),
                      color: context.modeTextSecondary,
                    ),
                  )
                : null,
            filled: true,
            fillColor: context.modeSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modeBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modeBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modePrimary, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: _getInputPaddingHorizontal(screenWidth),
              vertical: _getInputPaddingVertical(screenWidth),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter quantity';
            }
            final qty = double.tryParse(value);
            if (qty == null || qty <= 0) {
              return 'Please enter a valid quantity';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAddItemButton(double screenWidth) {
    return SizedBox(
      width: double.infinity,
      height: _getButtonHeight(screenWidth) - 8,
      child: OutlinedButton.icon(
        onPressed: _addItemToList,
        icon: AppIcon(
          Icons.add_circle_outline,
          size: _getIconSize(screenWidth),
          color: context.modePrimary,
        ),
        label: Text(
          'Add Item to Request',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getButtonFontSize(screenWidth),
            fontWeight: FontWeight.w600,
            color: context.modePrimary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.modePrimary,
          side: BorderSide(color: context.modePrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
          ),
        ),
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
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon, color: color, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 11,
                    color: context.modeTextSecondary,
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
              color: context.modeTextPrimary,
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
            color: context.modeTextPrimary,
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
                color: context.modeSurface,
                borderRadius: BorderRadius.circular(
                  _getBorderRadius(screenWidth),
                ),
                border: Border.all(color: context.modeBorder, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: _getIconSize(screenWidth) + 8,
                    height: _getIconSize(screenWidth) + 8,
                    decoration: BoxDecoration(
                      color: context.modePrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AppIcon(
                      Icons.inventory_2,
                      color: context.modePrimary,
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
                            color: context.modeTextPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Quantity: ${item.qtyRequested} ${itemInfo.unit}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getCaptionFontSize(screenWidth),
                            color: context.modeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: AppIcon(
                      Icons.delete_outline,
                      color: context.modeError,
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
            color: context.modeTextPrimary,
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth),
            fontWeight: FontWeight.w400,
            color: context.modeTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Add any additional notes for this request',
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              fontWeight: FontWeight.w400,
              color: context.modeTextSecondary,
            ),
            filled: true,
            fillColor: context.modeSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modeBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modeBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modePrimary, width: 1.5),
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
              backgroundColor: context.modePrimary,
              disabledBackgroundColor: context.modePrimary.withValues(
                alpha: 0.6,
              ),
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.modeTextInverse,
                      ),
                    ),
                  )
                : Text(
                    'Submit Stock Request',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getButtonFontSize(screenWidth),
                      fontWeight: FontWeight.w600,
                      color: context.modeTextInverse,
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

class _StockRequestBranch {
  const _StockRequestBranch({
    required this.id,
    required this.name,
    this.code = '',
    this.city = '',
  });

  final String id;
  final String name;
  final String code;
  final String city;

  String get displayName {
    final details = [
      if (code.isNotEmpty) code,
      if (city.isNotEmpty) city,
    ].join(' - ');
    if (details.isEmpty) return name.isEmpty ? id : name;
    return '${name.isEmpty ? id : name} ($details)';
  }

  factory _StockRequestBranch.fromJson(Map<String, dynamic> json) {
    return _StockRequestBranch(
      id: _parseString(json['id'] ?? json['branchId'] ?? json['branch_id']),
      name: _parseString(json['name'] ?? json['branchName'] ?? json['branch']),
      code: _parseString(
        json['code'] ?? json['branchCode'] ?? json['branch_code'],
      ),
      city: _parseString(json['city']),
    );
  }
}

class _StockRequestBranchDirectory {
  final ApiClient _apiClient = ApiClient.instance;

  Future<List<_StockRequestBranch>> loadBranches({
    required _StockRequestBranch fallbackBranch,
  }) async {
    final candidates = <({String path, Map<String, dynamic>? query})>[
      (path: 'Branches/active', query: null),
      (
        path: 'Branches',
        query: {
          'isActive': true,
          'limit': 100,
          'sortBy': 'name',
          'sortOrder': 'asc',
        },
      ),
    ];

    for (final candidate in candidates) {
      try {
        final response = await _apiClient
            .get<dynamic>(candidate.path, queryParameters: candidate.query)
            .timeout(const Duration(seconds: 8));

        if (!response.isSuccess || response.data == null) continue;

        final branches = _parseBranches(response.data);
        if (branches.isNotEmpty) {
          return _mergeFallback(branches, fallbackBranch);
        }
      } catch (_) {
        continue;
      }
    }

    return fallbackBranch.id.isEmpty ? const [] : [fallbackBranch];
  }

  List<_StockRequestBranch> _parseBranches(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map(
            (item) =>
                _StockRequestBranch.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((branch) => branch.id.isNotEmpty)
          .toList();
    }

    if (payload is Map) {
      final json = Map<String, dynamic>.from(payload);
      final possibleLists = [
        json['data'],
        json['branches'],
        if (json['data'] is Map) (json['data'] as Map)['branches'],
        if (json['data'] is Map) (json['data'] as Map)['items'],
      ];

      for (final value in possibleLists) {
        if (value is List) return _parseBranches(value);
      }

      final branch = _StockRequestBranch.fromJson(json);
      if (branch.id.isNotEmpty) return [branch];
    }

    return const [];
  }

  List<_StockRequestBranch> _mergeFallback(
    List<_StockRequestBranch> branches,
    _StockRequestBranch fallbackBranch,
  ) {
    if (fallbackBranch.id.isEmpty) return branches;
    if (branches.any((branch) => branch.id == fallbackBranch.id)) {
      return branches;
    }
    return [fallbackBranch, ...branches];
  }
}

String _parseString(dynamic value) {
  if (value == null || value is Map) return '';
  return value.toString();
}
