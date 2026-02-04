import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/procurement_req_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/procurement_req_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/procurement_req_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/procurement_req_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/inventory_items_repo.dart';

class StockProcurementRequestScreen extends StatefulWidget {
  const StockProcurementRequestScreen({super.key});

  @override
  State<StockProcurementRequestScreen> createState() =>
      _StockProcurementRequestScreenState();
}

class _StockProcurementRequestScreenState
    extends State<StockProcurementRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _minLevelController = TextEditingController();
  final _qtyNeededController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _itemNotesController = TextEditingController();
  final _notesController = TextEditingController();
  final _expectedDeliveryController = TextEditingController();
  final _urgencyReasonController = TextEditingController();

  String? _selectedItemId;
  String? _selectedItemName;
  String? _selectedItemUnit;
  String? _selectedItemCategory;
  DateTime? _selectedDeliveryDate;
  String _selectedPriority = 'NORMAL';
  String _selectedUrgencyLevel = 'NORMAL';
  String _selectedPrimaryCategory = 'PROTEIN';
  bool _isSearching = false;
  bool _isOpened = false;
  List<InventoryItem> _filteredItems = [];
  List<InventoryItem> _allItems = [];
  List<ProcurementRequestItem> _addedItems = [];
  BranchStockResponse? _branchStockData;

  String _branchId = '';
  String _employeeId = '';
  String _requestingDepartment = '';

  // Categories list
  final List<String> _categories = [
    'PROTEIN',
    'VEGETABLES',
    'DAIRY',
    'GRAINS',
    'BEVERAGES',
    'CONDIMENTS',
    'PACKAGING',
    'CLEANING',
    'OTHER',
  ];

  // Urgency reason suggestions
  final List<String> _urgencyReasonSuggestions = [
    'Stock running critically low',
    'Upcoming event or promotion',
    'High customer demand',
    'Seasonal requirement',
    'Supplier delivery delay',
    'Quality issues with current stock',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadUserData();
    _setDefaultDeliveryDate();

    // Load inventory items
    context.read<InventoryItemsBloc>().add(
      LoadInventoryItems(organizationId: ''),
    );
    context.read<BranchStockBloc>().add(LoadBranchStock(branchId: ''));
  }

  Future<void> _loadUserData() async {
    final branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    final userData = await AuthCacheHelper.instance.getUserData();
    final department = await AuthCacheHelper.instance.getDepartmentName() ?? '';

    setState(() {
      _branchId = branchId;
      _employeeId = userData?.id ?? '';
      _requestingDepartment = department.isNotEmpty ? department : 'KITCHEN';
    });
  }

  void _setDefaultDeliveryDate() {
    // Auto-set delivery date based on urgency (default 7 days)
    final defaultDate = DateTime.now().add(const Duration(days: 7));
    setState(() {
      _selectedDeliveryDate = defaultDate;
      _expectedDeliveryController.text = _formatDateForApi(defaultDate);
    });
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _currentStockController.dispose();
    _minLevelController.dispose();
    _qtyNeededController.dispose();
    _unitCostController.dispose();
    _itemNotesController.dispose();
    _notesController.dispose();
    _expectedDeliveryController.dispose();
    _urgencyReasonController.dispose();
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

  /// AUTO-FILL LOGIC: Get stock data for selected item
  Future<void> _autoFillStockData(String inventoryItemId) async {
    if (_branchStockData == null) {
      _showSnackBar('Loading stock data...', isError: false);
      return;
    }

    try {
      // Find the branch stock item that matches this inventory item
      final stockItem = _branchStockData!.data.firstWhere(
        (item) => item.itemId == inventoryItemId,
        orElse: () => throw Exception('Item not found in branch stock'),
      );

      setState(() {
        // Auto-fill current stock
        _currentStockController.text = stockItem.currentStockValue.toString();

        // Auto-fill reorder level as minimum level
        _minLevelController.text = stockItem.reorderLevelValue.toString();

        // Auto-calculate quantity needed based on stock level
        final shortage =
            stockItem.reorderLevelValue - stockItem.currentStockValue;

        if (shortage > 0) {
          // Add 20% buffer to bring stock comfortably above reorder level
          final recommendedQty = (shortage * 1.2).ceil();
          _qtyNeededController.text = recommendedQty.toString();
        } else {
          // Stock is adequate, suggest maintaining level
          final maintainQty = (stockItem.reorderLevelValue * 0.5).ceil();
          _qtyNeededController.text = maintainQty.toString();
        }

        // Auto-fill unit cost if available
        if (stockItem.unitCostValue > 0) {
          _unitCostController.text = stockItem.unitCostValue.toStringAsFixed(2);
        }

        // Add helpful note about stock status
        if (stockItem.isAtOrBelowReorder) {
          _itemNotesController.text = 'URGENT: Stock below reorder level';
        } else if (stockItem.isNearReorder) {
          _itemNotesController.text = 'Stock approaching reorder level';
        }
      });

      _showSnackBar('Stock data auto-filled successfully');
    } catch (e) {
      // If item not found in branch stock, user can enter manually
      _showSnackBar(
        'Stock data not available. Please enter manually.',
        isError: false,
      );
    }
  }

  /// QUICK ADD LOW STOCK ITEMS
  Future<void> _quickAddLowStockItems() async {
    if (_branchStockData == null) {
      _showSnackBar(
        'Please wait, loading stock data...',
        isError: false,
        isInfo: true,
      );
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
    // Calculate shortage
    final shortage = stockItem.reorderLevelValue - stockItem.currentStockValue;
    final qtyNeeded = shortage > 0
        ? (shortage * 1.2).ceil()
        : (stockItem.reorderLevelValue * 0.5).ceil();

    // Determine notes based on urgency
    String notes = '';
    if (stockItem.isOutOfStock) {
      notes = 'CRITICAL: Out of stock';
    } else if (stockItem.isAtOrBelowReorder) {
      notes = 'URGENT: Below reorder level';
    } else if (stockItem.isNearReorder) {
      notes = 'Approaching reorder level';
    }

    setState(() {
      _addedItems.add(
        ProcurementRequestItem(
          itemId: inventoryItem.id,
          currentStock: stockItem.currentStockValue,
          minLevel: stockItem.reorderLevelValue,
          qtyNeeded: qtyNeeded,
          unitCost: stockItem.unitCostValue > 0 ? stockItem.unitCostValue : 0,
          notes: notes,
        ),
      );

      // Auto-set primary category if first item
      if (_addedItems.length == 1) {
        _selectedPrimaryCategory = inventoryItem.category.toUpperCase();
      }
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
                  'Select items to add to procurement request:',
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
                disabledBackgroundColor: kPrimary.withOpacity(0.3),
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
      _selectedItemCategory = item.category;
      _isSearching = false;
      _isOpened = false;
      _searchController.clear();
    });

    // Auto-fill stock data
    _autoFillStockData(item.id);
  }

  void _onUrgencyLevelChanged(String urgency) {
    setState(() {
      _selectedUrgencyLevel = urgency;
      _selectedPriority = urgency; // Sync priority with urgency

      // Auto-adjust delivery date based on urgency
      DateTime newDate;
      switch (urgency) {
        case 'URGENT':
          newDate = DateTime.now().add(const Duration(days: 2));
          break;
        case 'HIGH':
          newDate = DateTime.now().add(const Duration(days: 4));
          break;
        default:
          newDate = DateTime.now().add(const Duration(days: 7));
      }

      _selectedDeliveryDate = newDate;
      _expectedDeliveryController.text = _formatDateForApi(newDate);
    });

    _showSnackBar('Delivery date adjusted to $urgency priority');
  }

  void _showHelpBottomSheet({
    required String title,
    required String description,
    required List<String> tips,
    required double screenWidth,
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
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_getBorderRadius(screenWidth) * 2),
          ),
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
              padding: EdgeInsets.all(_getHorizontalPadding(screenWidth)),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        _getBorderRadius(screenWidth),
                      ),
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: kPrimary,
                      size: _getIconSize(screenWidth) + 4,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getSectionTitleFontSize(screenWidth),
                        fontWeight: FontWeight.w600,
                        color: kprimaryTextColor1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: kprimaryTextColor2,
                      size: _getIconSize(screenWidth),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(_getHorizontalPadding(screenWidth)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getInputFontSize(screenWidth),
                        color: kprimaryTextColor1,
                        height: 1.5,
                      ),
                    ),
                    if (tips.isNotEmpty) ...[
                      SizedBox(height: 24),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(
                            _getBorderRadius(screenWidth),
                          ),
                          border: Border.all(
                            color: kPrimary.withOpacity(0.1),
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
                                  size: _getIconSize(screenWidth) - 2,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Tips',
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: _getLabelFontSize(screenWidth),
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
                                              fontSize:
                                                  _getCaptionFontSize(
                                                    screenWidth,
                                                  ) +
                                                  1,
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

  Future<void> _selectDate(BuildContext context, double screenWidth) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeliveryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              onSurface: kprimaryTextColor1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDeliveryDate) {
      setState(() {
        _selectedDeliveryDate = picked;
        _expectedDeliveryController.text = _formatDateForApi(picked);
      });
    }
  }

  void _addItemToList() {
    if (_selectedItemId == null) {
      _showSnackBar('Please select an item', isError: true);
      return;
    }

    if (_currentStockController.text.isEmpty ||
        _minLevelController.text.isEmpty ||
        _qtyNeededController.text.isEmpty ||
        _unitCostController.text.isEmpty) {
      _showSnackBar('Please fill in all required item fields', isError: true);
      return;
    }

    final currentStock = double.tryParse(_currentStockController.text.trim());
    final minLevel = double.tryParse(_minLevelController.text.trim());
    final qtyNeeded = int.tryParse(_qtyNeededController.text.trim());
    final unitCost = double.tryParse(_unitCostController.text.trim());

    if (currentStock == null || currentStock < 0) {
      _showSnackBar('Please enter a valid current stock', isError: true);
      return;
    }

    if (minLevel == null || minLevel < 0) {
      _showSnackBar('Please enter a valid minimum level', isError: true);
      return;
    }

    if (qtyNeeded == null || qtyNeeded <= 0) {
      _showSnackBar('Please enter a valid quantity', isError: true);
      return;
    }

    if (unitCost == null || unitCost < 0) {
      _showSnackBar('Please enter a valid unit cost', isError: true);
      return;
    }

    if (_addedItems.any((item) => item.itemId == _selectedItemId)) {
      _showSnackBar('Item already added to the list', isError: true);
      return;
    }

    setState(() {
      _addedItems.add(
        ProcurementRequestItem(
          itemId: _selectedItemId!,
          currentStock: currentStock,
          minLevel: minLevel,
          qtyNeeded: qtyNeeded,
          unitCost: unitCost,
          notes: _itemNotesController.text.trim(),
        ),
      );

      // Auto-set primary category if first item
      if (_addedItems.length == 1 && _selectedItemCategory != null) {
        _selectedPrimaryCategory = _selectedItemCategory!.toUpperCase();
      }

      _selectedItemId = null;
      _selectedItemName = null;
      _selectedItemUnit = null;
      _selectedItemCategory = null;
      _currentStockController.clear();
      _minLevelController.clear();
      _qtyNeededController.clear();
      _unitCostController.clear();
      _itemNotesController.clear();
      _isSearching = false;
      _isOpened = false;
    });

    _showSnackBar('Item added to procurement list');
  }

  void _removeItemFromList(int index) {
    setState(() {
      _addedItems.removeAt(index);
    });
    _showSnackBar('Item removed from list');
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar(
        'Please fill in all required fields correctly',
        isError: true,
      );
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

    try {
      final request = CreateProcurementRequest(
        branchId: _branchId,
        requestedBy: _employeeId,
        requestingDepartment: _requestingDepartment,
        priority: _selectedPriority,
        urgencyLevel: _selectedUrgencyLevel,
        urgencyReason: _urgencyReasonController.text.trim(),
        expectedDelivery: _expectedDeliveryController.text.trim(),
        primaryCategory: _selectedPrimaryCategory,
        budgetId: null,
        notes: _notesController.text.trim(),
        items: _addedItems,
      );

      context.read<ProcurementRequestBloc>().add(
        CreateProcurementRequestEvent(request: request),
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

  double _calculateTotalAmount() {
    return _addedItems.fold(
      0.0,
      (sum, item) => sum + (item.qtyNeeded * item.unitCost),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProcurementRequestBloc, ProcurementRequestState>(
          listener: (context, state) {
            if (state is ProcurementRequestSuccess) {
              _showSnackBar(state.message);
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) {
                  Navigator.pop(context, true);
                }
              });
            } else if (state is ProcurementRequestError) {
              _showSnackBar(state.error, isError: true);
            }
          },
        ),
        BlocListener<InventoryItemsBloc, InventoryItemsState>(
          listener: (context, state) {
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
                backgroundColor: const Color(0xFFF8F6F6),
                appBar: _buildAppBar(screenWidth),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: _getVerticalPadding(screenWidth),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                    'Request Information',
                                    screenWidth,
                                  ),
                                  SizedBox(
                                    height: _getSectionSpacing(screenWidth),
                                  ),
                                  _buildPriorityDropdown(screenWidth),
                                  SizedBox(
                                    height: _getFieldSpacing(screenWidth),
                                  ),
                                  _buildUrgencyLevelDropdown(screenWidth),
                                  SizedBox(
                                    height: _getFieldSpacing(screenWidth),
                                  ),
                                  _buildUrgencyReasonField(screenWidth),
                                  SizedBox(
                                    height: _getFieldSpacing(screenWidth),
                                  ),
                                  _buildPrimaryCategoryDropdown(screenWidth),
                                  SizedBox(
                                    height: _getFieldSpacing(screenWidth),
                                  ),
                                  _buildDateField(screenWidth),
                                  SizedBox(
                                    height: _getFieldSpacing(screenWidth),
                                  ),
                                  _buildTextFieldWithHelp(
                                    controller: _notesController,
                                    label: 'General Notes',
                                    hint:
                                        'Any additional information about this request',
                                    screenWidth: screenWidth,
                                    maxLines: 3,
                                    isRequired: false,
                                    helpTitle: 'General Notes',
                                    helpDescription:
                                        'Add any additional context or special instructions for this entire procurement request.',
                                    helpTips: [
                                      'Mention preferred suppliers if any',
                                      'Note any quality specifications',
                                      'Include delivery preferences',
                                    ],
                                  ),
                                  SizedBox(
                                    height: _getSectionSpacing(screenWidth) * 2,
                                  ),

                                  // QUICK ADD SECTION
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildSectionTitle(
                                        'Add Items',
                                        screenWidth,
                                      ),
                                      TextButton.icon(
                                        onPressed: _quickAddLowStockItems,
                                        icon: Icon(
                                          Icons.flash_on,
                                          size: 18,
                                          color: kPrimary,
                                        ),
                                        label: Text(
                                          'Quick Add Low Stock',
                                          style: WorkSansAppTextStyles.medium
                                              .copyWith(
                                                color: kPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(
                                    height: _getSectionSpacing(screenWidth),
                                  ),
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
                                    height: _getSectionSpacing(screenWidth) * 2,
                                  ),
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
        'New Procurement Request',
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

  // Continue in next part...
  Widget _buildUrgencyReasonField(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Urgency Reason *',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getLabelFontSize(screenWidth),
                fontWeight: FontWeight.w500,
                color: kprimaryTextColor1,
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showHelpBottomSheet(
                title: 'Urgency Reason',
                description:
                    'Provide a clear explanation for why this procurement request needs priority attention.',
                tips: [
                  'Be specific about the impact',
                  'Mention upcoming events if relevant',
                  'Explain customer or operational impact',
                ],
                screenWidth: screenWidth,
              ),
              child: Icon(
                Icons.help_outline,
                color: kPrimary,
                size: _getIconSize(screenWidth) - 4,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Smart suggestion chips
        if (_urgencyReasonController.text.isEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _urgencyReasonSuggestions.map((suggestion) {
              return ActionChip(
                label: Text(
                  suggestion,
                  style: TextStyle(fontSize: 11, color: kPrimary),
                ),
                backgroundColor: kPrimary.withOpacity(0.1),
                side: BorderSide(color: kPrimary.withOpacity(0.3)),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: () {
                  setState(() {
                    _urgencyReasonController.text = suggestion;
                  });
                },
              );
            }).toList(),
          ),
          SizedBox(height: 12),
        ],

        TextFormField(
          controller: _urgencyReasonController,
          maxLines: 2,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth),
            fontWeight: FontWeight.w400,
            color: kprimaryTextColor1,
          ),
          decoration: InputDecoration(
            hintText: 'Explain why this request is urgent',
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please provide an urgency reason';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAutoFilledFields(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: kPrimary.withOpacity(0.2)),
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

          _buildTextFieldWithHelp(
            controller: _currentStockController,
            label: 'Current Stock',
            hint: 'Current quantity in inventory',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            screenWidth: screenWidth,
            helpTitle: 'Current Stock',
            helpDescription: 'Auto-filled from your branch inventory.',
            helpTips: ['You can edit this if needed'],
          ),
          SizedBox(height: _getFieldSpacing(screenWidth)),

          _buildTextFieldWithHelp(
            controller: _minLevelController,
            label: 'Minimum Level',
            hint: 'Minimum stock threshold',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            screenWidth: screenWidth,
            helpTitle: 'Minimum Level',
            helpDescription: 'Auto-filled from reorder level settings.',
            helpTips: ['Adjust if needed based on demand'],
          ),
          SizedBox(height: _getFieldSpacing(screenWidth)),

          _buildTextFieldWithHelp(
            controller: _qtyNeededController,
            label: 'Quantity Needed',
            hint: 'Quantity to procure',
            keyboardType: TextInputType.number,
            screenWidth: screenWidth,
            helpTitle: 'Quantity Needed',
            helpDescription: 'Auto-calculated based on shortage + 20% buffer.',
            helpTips: ['Adjust based on upcoming demand'],
            suffix: _selectedItemUnit != null
                ? Text(
                    _selectedItemUnit!,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getInputFontSize(screenWidth),
                      color: kprimaryTextColor2,
                    ),
                  )
                : null,
          ),
          SizedBox(height: _getFieldSpacing(screenWidth)),

          _buildTextFieldWithHelp(
            controller: _unitCostController,
            label: 'Unit Cost',
            hint: 'Cost per unit',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText: '₦ ',
            screenWidth: screenWidth,
            helpTitle: 'Unit Cost',
            helpDescription:
                'Auto-filled from last purchase price if available.',
            helpTips: ['Update with current market price if different'],
          ),
          SizedBox(height: _getFieldSpacing(screenWidth)),

          _buildTextFieldWithHelp(
            controller: _itemNotesController,
            label: 'Item Notes',
            hint: 'Specific notes for this item',
            screenWidth: screenWidth,
            maxLines: 2,
            isRequired: false,
            helpTitle: 'Item Notes',
            helpDescription: 'Add specific instructions for this item.',
            helpTips: ['Quality requirements', 'Preferred brands', 'Packaging'],
          ),
          SizedBox(height: _getFieldSpacing(screenWidth)),

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
                'Add Item to List',
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

  // Add remaining widget methods (dropdowns, search field, etc.)
  // Due to length, I'll provide the key automation widgets above
  // The rest follows the same pattern as your original code

  Widget _buildPriorityDropdown(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Priority *',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getLabelFontSize(screenWidth),
                fontWeight: FontWeight.w500,
                color: kprimaryTextColor1,
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showHelpBottomSheet(
                title: 'Priority',
                description:
                    'Indicates the overall importance of this procurement request.',
                tips: [
                  'NORMAL: Standard procurement process',
                  'HIGH: Needs faster processing',
                  'URGENT: Critical shortage, expedite immediately',
                ],
                screenWidth: screenWidth,
              ),
              child: Icon(
                Icons.help_outline,
                color: kPrimary,
                size: _getIconSize(screenWidth) - 4,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _selectedPriority,
          decoration: InputDecoration(
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
          items: ['NORMAL', 'HIGH', 'URGENT'].map((String priority) {
            return DropdownMenuItem<String>(
              value: priority,
              child: Text(
                priority,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getInputFontSize(screenWidth),
                  color: kprimaryTextColor1,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedPriority = newValue;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildUrgencyLevelDropdown(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Urgency Level *',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getLabelFontSize(screenWidth),
                fontWeight: FontWeight.w500,
                color: kprimaryTextColor1,
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showHelpBottomSheet(
                title: 'Urgency Level',
                description:
                    'Specifies how quickly this procurement needs to be fulfilled.',
                tips: [
                  'NORMAL: Regular lead time acceptable',
                  'Affects delivery date automatically',
                  'Should match your urgency reason',
                ],
                screenWidth: screenWidth,
              ),
              child: Icon(
                Icons.help_outline,
                color: kPrimary,
                size: _getIconSize(screenWidth) - 4,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _selectedUrgencyLevel,
          decoration: InputDecoration(
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
          items: ['NORMAL', 'HIGH', 'URGENT'].map((String level) {
            return DropdownMenuItem<String>(
              value: level,
              child: Text(
                level,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getInputFontSize(screenWidth),
                  color: kprimaryTextColor1,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              _onUrgencyLevelChanged(newValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPrimaryCategoryDropdown(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Primary Category *',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getLabelFontSize(screenWidth),
                fontWeight: FontWeight.w500,
                color: kprimaryTextColor1,
              ),
            ),
            SizedBox(width: 8),
            if (_addedItems.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Auto-set from first item',
                  style: TextStyle(
                    fontSize: 10,
                    color: kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _categories.contains(_selectedPrimaryCategory)
              ? _selectedPrimaryCategory
              : null,
          items: _categories.toSet().map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getInputFontSize(screenWidth),
                  color: kprimaryTextColor1,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedPrimaryCategory = newValue!;
            });
          },
        ),
      ],
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
            GestureDetector(
              onTap: () => _showHelpBottomSheet(
                title: 'Select Item',
                description:
                    'Search and select an item. Stock data will be auto-filled!',
                tips: [
                  'Type to search by item name',
                  'Stock levels auto-filled from inventory',
                  'Quantities calculated automatically',
                ],
                screenWidth: screenWidth,
              ),
              child: Icon(
                Icons.help_outline,
                color: kPrimary,
                size: _getIconSize(screenWidth) - 4,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
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
                    : kPrimary.withOpacity(0.3),
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
                SizedBox(width: 20),
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
                _isOpened
                    ? Icon(
                        Icons.arrow_drop_down,
                        color: kprimaryTextColor2,
                        size: _getIconSize(screenWidth) + 4,
                      )
                    : Transform.rotate(
                        angle: -90 * 3.14159 / 180,
                        child: Icon(
                          Icons.arrow_drop_down,
                          color: kprimaryTextColor2,
                          size: _getIconSize(screenWidth) + 4,
                        ),
                      ),
              ],
            ),
          ),
        ),
        if (_isSearching) ...[
          SizedBox(height: 20),
          _isOpened ? _buildSearchDropdown(screenWidth) : SizedBox(),
        ],
      ],
    );
  }

  Widget _buildSearchDropdown(double screenWidth) {
    return Container(
      constraints: BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
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
                                  color: kPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: kPrimary,
                                  size: _getIconSize(screenWidth) - 4,
                                ),
                              ),
                              SizedBox(width: 10),
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

  Widget _buildAddedItemsList(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Added Items (${_addedItems.length})',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getSectionTitleFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            Text(
              'Total: ₦${_calculateTotalAmount().toStringAsFixed(2)}',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getLabelFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: kPrimary,
              ),
            ),
          ],
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
                      color: kPrimary.withOpacity(0.1),
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
                          'Current: ${item.currentStock} | Min: ${item.minLevel}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getCaptionFontSize(screenWidth),
                            color: kprimaryTextColor2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Qty: ${item.qtyNeeded} ${itemInfo.unit} • ₦${item.unitCost.toStringAsFixed(2)} per unit',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getCaptionFontSize(screenWidth),
                            color: kprimaryTextColor2,
                          ),
                        ),
                        if (item.notes.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(
                            'Note: ${item.notes}',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: _getCaptionFontSize(screenWidth),
                              color: kprimaryTextColor2,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        SizedBox(height: 2),
                        Text(
                          'Total: ₦${(item.qtyNeeded * item.unitCost).toStringAsFixed(2)}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: _getCaptionFontSize(screenWidth),
                            fontWeight: FontWeight.w600,
                            color: kPrimary,
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

  Widget _buildTextFieldWithHelp({
    required TextEditingController controller,
    required String label,
    required String hint,
    required double screenWidth,
    required String helpTitle,
    required String helpDescription,
    required List<String> helpTips,
    TextInputType? keyboardType,
    String? prefixText,
    Widget? suffix,
    int maxLines = 1,
    bool isRequired = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isRequired ? '$label *' : label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getLabelFontSize(screenWidth),
                fontWeight: FontWeight.w500,
                color: kprimaryTextColor1,
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showHelpBottomSheet(
                title: helpTitle,
                description: helpDescription,
                tips: helpTips,
                screenWidth: screenWidth,
              ),
              child: Icon(
                Icons.help_outline,
                color: kPrimary,
                size: _getIconSize(screenWidth) - 4,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth),
            fontWeight: FontWeight.w400,
            color: kprimaryTextColor1,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              fontWeight: FontWeight.w400,
              color: kprimaryTextColor2,
            ),
            prefixText: prefixText,
            prefixStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
            suffix: suffix,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: const BorderSide(
                color: Color(0xFFE53935),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: const BorderSide(
                color: Color(0xFFE53935),
                width: 1.5,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: _getInputPaddingHorizontal(screenWidth),
              vertical: _getInputPaddingVertical(screenWidth),
            ),
          ),
          validator: validator,
          inputFormatters:
              keyboardType == TextInputType.number ||
                  keyboardType ==
                      const TextInputType.numberWithOptions(decimal: true)
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
              : null,
        ),
      ],
    );
  }

  Widget _buildDateField(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Expected Delivery Date *',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getLabelFontSize(screenWidth),
                fontWeight: FontWeight.w500,
                color: kprimaryTextColor1,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Auto-adjusted',
                style: TextStyle(
                  fontSize: 10,
                  color: kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        GestureDetector(
          onTap: () => _selectDate(context, screenWidth),
          child: AbsorbPointer(
            child: TextFormField(
              controller: _expectedDeliveryController,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                fontWeight: FontWeight.w400,
                color: kprimaryTextColor1,
              ),
              decoration: InputDecoration(
                hintText: 'Select expected delivery date',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getInputFontSize(screenWidth),
                  fontWeight: FontWeight.w400,
                  color: kprimaryTextColor2,
                ),
                suffixIcon: Icon(
                  Icons.calendar_today,
                  color: kPrimary,
                  size: _getIconSize(screenWidth),
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(screenWidth),
                  ),
                  borderSide: const BorderSide(
                    color: Color(0xFFE53935),
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(screenWidth),
                  ),
                  borderSide: const BorderSide(
                    color: Color(0xFFE53935),
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: _getInputPaddingHorizontal(screenWidth),
                  vertical: _getInputPaddingVertical(screenWidth),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select expected delivery date';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(double screenWidth) {
    return BlocBuilder<ProcurementRequestBloc, ProcurementRequestState>(
      builder: (context, state) {
        final isLoading = state is ProcurementRequestLoading;

        return SizedBox(
          width: double.infinity,
          height: _getButtonHeight(screenWidth),
          child: ElevatedButton(
            onPressed: isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              disabledBackgroundColor: kPrimary.withOpacity(0.6),
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
                    'Submit Procurement Request',
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
