import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/add_branch_stock_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/add_branch_stock_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/add_branchstock.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/add_branch_stock_bloc/state.dart'
    as addbranchstock;

import 'package:sandwich_ai/src/features/stock_control/data/repo/inventory_items_repo.dart';

class AddEditStockScreen extends StatefulWidget {
  final String? itemId;
  final String branchId;

  const AddEditStockScreen({super.key, this.itemId, required this.branchId});

  @override
  State<AddEditStockScreen> createState() => _AddEditStockScreenState();
}

class _AddEditStockScreenState extends State<AddEditStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _maxLevelController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _expiryDateController = TextEditingController();

  String? _selectedItemId;
  String? _selectedItemName;
  DateTime? _selectedExpiryDate;
  bool _isSearching = false;
  bool _isOpened = false;
  List<InventoryItem> _filteredItems = [];
  List<InventoryItem> _allItems = [];
  String _orgId = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadOrgAndInventory();

    if (widget.itemId != null) {
      _selectedItemId = widget.itemId;
      _loadItemData();
    }
  }

  Future<void> _loadOrgAndInventory() async {
    final orgId = await AuthCacheHelper.instance.getOrgId() ?? '';
    if (mounted && orgId.isNotEmpty) {
      setState(() => _orgId = orgId);
      context.read<InventoryItemsBloc>().add(
        LoadInventoryItems(organizationId: orgId, page: 1, limit: 100),
      );
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _currentStockController.dispose();
    _reorderLevelController.dispose();
    _maxLevelController.dispose();
    _unitCostController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  void _loadItemData() {
    // Load existing item data for editing
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems
            .where(
              (item) => item.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });

    if (_orgId.isEmpty) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      context.read<InventoryItemsBloc>().add(
        LoadInventoryItems(
          organizationId: _orgId,
          page: 1,
          limit: 100,
          search: query,
        ),
      );
    });
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
            // Drag handle
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(_getHorizontalPadding(screenWidth)),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(_getHorizontalPadding(screenWidth)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
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

                      // Tips section
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(
                            _getBorderRadius(screenWidth),
                          ),
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
          _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
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

    if (picked != null && picked != _selectedExpiryDate) {
      setState(() {
        _selectedExpiryDate = picked;
        _expiryDateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _submitForm() {
    AppLogger.log("Submit called!");

    if (!_formKey.currentState!.validate()) {
      _showSnackBar(
        'Please fill in all required fields correctly',
        isError: true,
      );
      return;
    }

    if (_selectedItemId == null) {
      _showSnackBar('Please select an item', isError: true);
      return;
    }

    try {
      final currentStock = double.tryParse(_currentStockController.text.trim());
      final reorderLevel = double.tryParse(_reorderLevelController.text.trim());
      final maxLevel = double.tryParse(_maxLevelController.text.trim());
      final unitCost = double.tryParse(_unitCostController.text.trim());

      if (currentStock == null ||
          reorderLevel == null ||
          maxLevel == null ||
          unitCost == null) {
        _showSnackBar('Please enter valid numeric values', isError: true);
        return;
      }

      if (maxLevel < reorderLevel) {
        _showSnackBar(
          'Max level must be greater than reorder level',
          isError: true,
        );
        return;
      }

      if (currentStock > maxLevel) {
        _showSnackBar('Current stock cannot exceed max level', isError: true);
        return;
      }

      final request = BranchStockRequest(
        itemId: _selectedItemId!,
        branchId: widget.branchId,
        currentStock: currentStock,
        reorderLevel: reorderLevel,
        maxLevel: maxLevel,
        unitCost: unitCost,
        expiryDate: _expiryDateController.text.trim(),
      );

      AppLogger.log("Dispatching event with request: ${request.toJson()}");

      if (widget.itemId == null) {
        context.read<AddBranchStockBloc>().add(
          CreateBranchStock(request: request),
        );
      } else {
        context.read<AddBranchStockBloc>().add(
          UpdateBranchStock(stockId: widget.itemId!, request: request),
        );
      }
    } catch (e) {
      AppLogger.log("Error in _submitForm: $e");
      _showSnackBar('Invalid input: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: WorkSansAppTextStyles.medium.copyWith(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError ? const Color(0xFFE53935) : kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AddBranchStockBloc, addbranchstock.BranchStockState>(
          listener: (context, state) {
            if (state is addbranchstock.BranchStockSuccess) {
              _showSnackBar(
                'Stock item ${widget.itemId == null ? 'added' : 'updated'} successfully!',
              );

              // Refresh the branch stock list
              context.read<BranchStockBloc>().add(
                LoadBranchStock(branchId: widget.branchId),
              );

              // Navigate back after a short delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  Navigator.pop(context, true);
                }
              });
            } else if (state is addbranchstock.BranchStockError) {
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
                                    'Item Information',
                                    screenWidth,
                                  ),
                                  SizedBox(
                                    height: _getSectionSpacing(screenWidth),
                                  ),
                                  _buildItemSearchField(screenWidth),
                                  SizedBox(
                                    height: _getFieldSpacing(screenWidth),
                                  ),

                                  _buildSectionTitle(
                                    'Stock Levels',
                                    screenWidth,
                                  ),
                                  SizedBox(
                                    height: _getSectionSpacing(screenWidth),
                                  ),
                                  _buildTextField(
                                    controller: _currentStockController,
                                    label: 'Current Stock',
                                    hint: 'Enter current stock quantity',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    screenWidth: screenWidth,
                                    onHelpTap: () => _showHelpBottomSheet(
                                      title: 'Current Stock',
                                      description:
                                          'This is the actual quantity of items you currently have in your branch inventory. It represents the physical count of items available for sale or use.',
                                      tips: [
                                        'Count all units physically present in your branch',
                                        'Include items on shelves and in storage',
                                        'Exclude damaged or expired items',
                                        'Update this regularly after sales or restocking',
                                      ],
                                      screenWidth: screenWidth,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter current stock';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Please enter a valid number';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(
                                    height: _getFieldSpacing(screenWidth),
                                  ),
                                  _buildTextField(
                                    controller: _reorderLevelController,
                                    label: 'Reorder Level',
                                    hint: 'Minimum stock before reorder',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    screenWidth: screenWidth,
                                    onHelpTap: () => _showHelpBottomSheet(
                                      title: 'Reorder Level',
                                      description:
                                          'The reorder level is the minimum quantity of stock that triggers a reorder alert. When your current stock reaches this level, it\'s time to order more inventory to avoid running out.',
                                      tips: [
                                        'Set this based on your average daily usage',
                                        'Consider delivery lead time from suppliers',
                                        'Higher reorder levels prevent stockouts',
                                        'Lower levels reduce storage costs',
                                        'Review and adjust based on sales patterns',
                                      ],
                                      screenWidth: screenWidth,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter reorder level';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Please enter a valid number';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(
                                    height: _getFieldSpacing(screenWidth),
                                  ),
                                  _buildTextField(
                                    controller: _maxLevelController,
                                    label: 'Maximum Level',
                                    hint: 'Maximum stock capacity',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    screenWidth: screenWidth,
                                    onHelpTap: () => _showHelpBottomSheet(
                                      title: 'Maximum Level',
                                      description:
                                          'The maximum level is the highest quantity of stock you should maintain for this item. This helps prevent overstocking and ensures efficient use of storage space and capital.',
                                      tips: [
                                        'Consider your storage space limitations',
                                        'Factor in the item\'s shelf life or expiry date',
                                        'Balance between having enough stock and avoiding waste',
                                        'Must be greater than your reorder level',
                                        'Review seasonally for seasonal items',
                                      ],
                                      screenWidth: screenWidth,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter maximum level';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Please enter a valid number';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(
                                    height: _getFieldSpacing(screenWidth),
                                  ),

                                  _buildSectionTitle(
                                    'Pricing & Expiry',
                                    screenWidth,
                                  ),
                                  SizedBox(
                                    height: _getSectionSpacing(screenWidth),
                                  ),
                                  _buildTextField(
                                    controller: _unitCostController,
                                    label: 'Unit Cost',
                                    hint: 'Cost per unit',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    prefixText: '₦ ',
                                    screenWidth: screenWidth,
                                    onHelpTap: () => _showHelpBottomSheet(
                                      title: 'Unit Cost',
                                      description:
                                          'The unit cost is the price you paid to acquire one unit of this item. This is your cost price (not the selling price) and is used to calculate inventory value and profit margins.',
                                      tips: [
                                        'Enter the cost from your supplier or purchase invoice',
                                        'Include any direct costs like shipping per unit if applicable',
                                        'This helps track your inventory investment',
                                        'Update when supplier prices change',
                                        'Accurate cost tracking ensures proper profit calculation',
                                      ],
                                      screenWidth: screenWidth,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter unit cost';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Please enter a valid amount';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(
                                    height: _getFieldSpacing(screenWidth),
                                  ),
                                  _buildDateField(screenWidth),
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
        widget.itemId == null ? 'Add Stock Item' : 'Edit Stock Item',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: _getAppBarTitleFontSize(screenWidth),
          fontWeight: FontWeight.w600,
          color: kprimaryTextColor1,
        ),
      ),
      centerTitle: true,
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
            GestureDetector(
              onTap: () => _showHelpBottomSheet(
                title: 'Select Item',
                description:
                    'Choose the inventory item you want to add to your branch stock. This should be an item that already exists in your organization\'s master inventory list.',
                tips: [
                  'Search by typing the item name',
                  'You can only add items that exist in the master inventory',
                  'Contact your administrator if an item is missing',
                  'Once selected, this cannot be changed (you\'ll need to create a new entry)',
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
          onTap: widget.itemId == null
              ? () {
                  setState(() {
                    _isOpened = !_isOpened;
                    _isSearching = true;
                  });
                }
              : null,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getInputPaddingHorizontal(screenWidth),
              vertical: _getInputPaddingVertical(screenWidth),
            ),
            decoration: BoxDecoration(
              color: widget.itemId != null
                  ? const Color(0xFFF5F5F5)
                  : Colors.white,
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
                if (widget.itemId == null)
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
                    itemCount: _filteredItems.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _filteredItems.length) {
                        final s = context.read<InventoryItemsBloc>().state;
                        if (s is InventoryItemsLoaded &&
                            s.hasMore &&
                            !s.isLoadingMore) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.read<InventoryItemsBloc>().add(
                              LoadMoreInventoryItems(organizationId: _orgId),
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
                                      '${item.category} • ${item.storage}',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required double screenWidth,
    TextInputType? keyboardType,
    String? prefixText,
    VoidCallback? onHelpTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$label *',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getLabelFontSize(screenWidth),
                fontWeight: FontWeight.w500,
                color: kprimaryTextColor1,
              ),
            ),
            if (onHelpTap != null) ...[
              SizedBox(width: 8),
              GestureDetector(
                onTap: onHelpTap,
                child: Icon(
                  Icons.help_outline,
                  color: kPrimary,
                  size: _getIconSize(screenWidth) - 4,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 20),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
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
              'Expiry Date *',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getLabelFontSize(screenWidth),
                fontWeight: FontWeight.w500,
                color: kprimaryTextColor1,
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showHelpBottomSheet(
                title: 'Expiry Date',
                description:
                    'The expiry date is the date when this item will no longer be safe or suitable for use or sale. This is crucial for perishable items and helps prevent selling expired products.',
                tips: [
                  'Always check the manufacturer\'s expiry date on the product',
                  'For items without expiry dates, estimate based on shelf life',
                  'Set alerts to review stock before expiry dates',
                  'Use FIFO (First In, First Out) to manage expiring stock',
                  'Items nearing expiry can be marked down for quick sale',
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
          onTap: () => _selectDate(context, screenWidth),
          child: AbsorbPointer(
            child: TextFormField(
              controller: _expiryDateController,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                fontWeight: FontWeight.w400,
                color: kprimaryTextColor1,
              ),
              decoration: InputDecoration(
                hintText: 'Select expiry date',
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
                  return 'Please select an expiry date';
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
    return BlocBuilder<AddBranchStockBloc, addbranchstock.BranchStockState>(
      builder: (context, state) {
        final isLoading = state is addbranchstock.BranchStockLoading;

        return SizedBox(
          width: double.infinity,
          height: _getButtonHeight(screenWidth),
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    AppLogger.log('Hit');
                    _submitForm();
                  },
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
                    widget.itemId == null
                        ? 'Add Stock Item'
                        : 'Update Stock Item',
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
