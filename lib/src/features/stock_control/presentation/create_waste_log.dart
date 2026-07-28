import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/utils/debouncer.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';

import 'package:sandwich_ai/src/features/stock_control/bloc/wastage_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/wastage_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/wastage_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/wastage_log.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/inventory_items_repo.dart';

class CreateWasteLogScreen extends StatefulWidget {
  const CreateWasteLogScreen({super.key});

  @override
  State<CreateWasteLogScreen> createState() => _CreateWasteLogScreenState();
}

class _CreateWasteLogScreenState extends State<CreateWasteLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();
  final _valueLostController = TextEditingController();
  final _notesController = TextEditingController();
  final _recordedByController = TextEditingController();

  String? _selectedItemId;
  String? _selectedItemName;
  String? _selectedItemUnit;
  WasteReason? _selectedReason;
  bool _isSearching = false;
  bool _isOpened = false;
  List<InventoryItem> _filteredItems = [];
  List<InventoryItem> _allItems = [];
  // Add field:
  String _orgId = '';
  late final Debouncer _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _searchDebouncer = Debouncer(
      delay: const Duration(milliseconds: 350),
    );
    _searchController.addListener(_onSearchChanged);
    _loadOrgAndInventory();
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
    _searchDebouncer.dispose();
    _searchController.dispose();
    _quantityController.dispose();
    _valueLostController.dispose();
    _notesController.dispose();
    _recordedByController.dispose();
    super.dispose();
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
    _searchDebouncer.cancel();
    _searchDebouncer(() {
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

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    if (_selectedItemId == null) {
      _showSnackBar('Please select an item', isError: true);
      return;
    }

    if (_selectedReason == null) {
      _showSnackBar('Please select a waste reason', isError: true);
      return;
    }

    try {
      final quantity = double.parse(_quantityController.text.trim());
      final valueLost = double.parse(_valueLostController.text.trim());
      final empId = await AuthCacheHelper.instance.getEmpID() ?? '';
      final bid = await AuthCacheHelper.instance.getBranchID() ?? '';
      if (!mounted) return;

      final request = WasteLogRequest(
        branchId: bid,
        itemName: _selectedItemName!,
        itemId: _selectedItemId!,
        quantity: quantity,
        unit: _selectedItemUnit ?? 'KG',
        reason: _selectedReason!.value,
        valueLost: valueLost,
        notes: _notesController.text.trim(),
        recordedBy: empId,
      );

      context.read<WasteLogsBloc>().add(CreateWasteLog(request: request));
    } catch (e) {
      _showSnackBar('Invalid input: ${e.toString()}', isError: true);
    }
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
          color: context.modeSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: context.modeBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.modePrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppIcon(
                      Icons.help_outline,
                      color: context.modePrimary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.modeTextPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: AppIcon(
                      Icons.close,
                      color: context.modeTextSecondary,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: context.modeDivider),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      description,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 15,
                        color: context.modeTextPrimary,
                        height: 1.5,
                      ),
                    ),

                    if (tips.isNotEmpty) ...[
                      SizedBox(height: 24),

                      // Tips section
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.modePrimary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.modePrimary.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppIcon(
                                  Icons.lightbulb_outline,
                                  color: context.modePrimary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Tips',
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.modePrimary,
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
                                        color: context.modePrimary,
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
                                              color: context.modeTextPrimary,
                                              height: 1.4,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
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

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: WorkSansAppTextStyles.medium.copyWith(
            color: context.modeTextInverse,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError ? context.modeError : context.modeSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<WasteLogsBloc, WasteLogsState>(
          listener: (context, state) {
            if (state is WasteLogCreated) {
              _showSnackBar('Waste log created successfully!');
              _resetForm();
            } else if (state is WasteLogCreateError) {
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

              return SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 700),
                    child: isLoadingInventory
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.modePrimary,
                              ),
                            ),
                          )
                        : Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Item Information'),
                                SizedBox(height: 16),
                                _buildItemSearchField(screenWidth),
                                SizedBox(height: 24),

                                _buildSectionTitle('Waste Details'),
                                SizedBox(height: 16),
                                _buildReasonDropdown(),
                                SizedBox(height: 20),
                                _buildTextField(
                                  controller: _quantityController,
                                  label: 'Quantity',
                                  hint: 'Enter quantity',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onHelpTap: () => _showHelpBottomSheet(
                                    title: 'Quantity',
                                    description:
                                        'Enter the exact amount of the item that has been wasted. This should reflect the actual quantity lost, which will be deducted from your inventory.',
                                    tips: [
                                      'Be as accurate as possible with measurements',
                                      'Use whole numbers for countable items',
                                      'For bulk items, measure carefully before entering',
                                      'This quantity will reduce your inventory count',
                                      'Double-check before submitting as this affects stock levels',
                                    ],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter quantity';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20),
                                _buildTextField(
                                  controller: _valueLostController,
                                  label: 'Value Lost',
                                  hint: 'Enter estimated value lost',
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  prefixText: '₦ ',
                                  onHelpTap: () => _showHelpBottomSheet(
                                    title: 'Value Lost',
                                    description:
                                        'The monetary value of the wasted items. This represents the financial loss to your business and is calculated based on the cost price of the wasted quantity.',
                                    tips: [
                                      'Use the unit cost price × quantity wasted',
                                      'Include any processing costs if applicable',
                                      'This helps track waste impact on profitability',
                                      'Regularly review to identify cost-saving opportunities',
                                      'Used in financial reports and waste analysis',
                                      'Be accurate for proper accounting',
                                    ],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter value lost';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Please enter a valid amount';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20),
                                _buildTextField(
                                  controller: _notesController,
                                  label: 'Notes',
                                  hint: 'Additional details about the waste',
                                  maxLines: 3,
                                  onHelpTap: () => _showHelpBottomSheet(
                                    title: 'Notes',
                                    description:
                                        'Provide detailed information about the waste incident. This helps identify patterns, prevent future waste, and provides context for audits and reviews.',
                                    tips: [
                                      'Describe what happened and when it occurred',
                                      'Mention any contributing factors or circumstances',
                                      'Note if corrective actions were taken',
                                      'Include batch numbers or lot codes if applicable',
                                      'Be specific but concise',
                                      'This information is valuable for waste reduction strategies',
                                    ],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter notes';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 32),
                                _buildSubmitButton(),
                                SizedBox(height: 20),
                              ],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: 17,
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.modeTextPrimary,
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showHelpBottomSheet(
                title: 'Select Item',
                description:
                    'Choose the inventory item that has been wasted from your available stock. This should be an item that exists in your inventory catalog.',
                tips: [
                  'Search by typing the item name',
                  'Only items in your inventory will appear',
                  'Select the exact item that was wasted',
                  'Make sure you choose the correct item before proceeding',
                  'If an item is missing, contact your administrator',
                ],
              ),
              child: AppIcon(
                Icons.help_outline,
                color: context.modePrimary,
                size: 18,
              ),
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(10),
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
                  size: 22,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedItemName ?? 'Search and select an item',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: _selectedItemName != null
                          ? context.modeTextPrimary
                          : context.modeTextSecondary,
                    ),
                  ),
                ),
                AppIcon(
                  _isOpened ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: context.modeTextSecondary,
                  size: 26,
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
      constraints: BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(10),
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
            padding: EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 15,
                color: context.modeTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Type to search...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 15,
                  color: context.modeTextSecondary,
                ),
                prefixIcon: AppIconSlot(
                  Icons.search,
                  color: context.modeTextSecondary,
                  size: 22,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.modeBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: context.modePrimary,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: context.modeDivider),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Text(
                      'No items found',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: context.modeTextSecondary,
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
                            _selectedItemUnit = item.unit;
                            _isSearching = false;
                            _isOpened = false;
                            _searchDebouncer.cancel();
                            _searchController.clear();
                            _filteredItems = _allItems;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
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
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: context.modePrimary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: AppIcon(
                                  Icons.inventory_2_outlined,
                                  color: context.modePrimary,
                                  size: 18,
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
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: context.modeTextPrimary,
                                          ),
                                    ),
                                    Text(
                                      '${item.category} • ${item.storage}',
                                      style: WorkSansAppTextStyles.medium
                                          .copyWith(
                                            fontSize: 12,
                                            color: context.modeTextSecondary,
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

  Widget _buildReasonDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Waste Reason *',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.modeTextPrimary,
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showHelpBottomSheet(
                title: 'Waste Reason',
                description:
                    'Select the primary reason why this item was wasted. Understanding waste patterns helps identify areas for improvement and cost reduction in your operations.',
                tips: [
                  'Choose the most accurate reason for the waste',
                  'Expired: Items past their safe consumption date',
                  'Spoilage: Items that deteriorated due to improper storage or handling',
                  'Damage: Physical damage during handling, storage, or transport',
                  'Over Production: Made too much and couldn\'t sell in time',
                  'Contamination: Items exposed to contaminants',
                  'Other: Any reason not covered by the above categories',
                ],
              ),
              child: AppIcon(
                Icons.help_outline,
                color: context.modePrimary,
                size: 18,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        DropdownButtonFormField<WasteReason>(
          initialValue: _selectedReason,
          decoration: InputDecoration(
            hintText: 'Select reason for waste',
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 15,
              color: context.modeTextSecondary,
            ),
            filled: true,
            fillColor: context.modeSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.modeBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.modeBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.modePrimary, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: WasteReason.values.map((reason) {
            return DropdownMenuItem(
              value: reason,
              child: Text(
                reason.displayName,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 15,
                  color: context.modeTextPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedReason = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a waste reason';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.modeTextPrimary,
              ),
            ),
            if (onHelpTap != null) ...[
              SizedBox(width: 8),
              GestureDetector(
                onTap: onHelpTap,
                child: AppIcon(
                  Icons.help_outline,
                  color: context.modePrimary,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 15,
            color: context.modeTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 15,
              color: context.modeTextSecondary,
            ),
            prefixText: prefixText,
            prefixStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
            filled: true,
            fillColor: context.modeSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.modeBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.modeBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.modePrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.modeError, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
          inputFormatters:
              keyboardType == TextInputType.number ||
                  keyboardType == TextInputType.numberWithOptions(decimal: true)
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
              : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<WasteLogsBloc, WasteLogsState>(
      builder: (context, state) {
        final isLoading = state is WasteLogCreating;

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.modePrimary,
              disabledBackgroundColor: context.modePrimary.withValues(
                alpha: 0.6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.modeTextInverse,
                      ),
                    ),
                  )
                : Text(
                    'Log Waste',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.modeTextInverse,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _quantityController.clear();
    _valueLostController.clear();
    _notesController.clear();
    _recordedByController.clear();
    setState(() {
      _selectedItemId = null;
      _selectedItemName = null;
      _selectedItemUnit = null;
      _selectedReason = null;
      _isSearching = false;
      _isOpened = false;
    });
  }
}
