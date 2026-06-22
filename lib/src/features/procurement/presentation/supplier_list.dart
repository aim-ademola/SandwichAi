import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/supplier_model.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/supplier_repo.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/supplier_product_screen.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/state.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedType;

  // Cache the suppliers locally to prevent loss on navigation
  List<dynamic> _cachedSuppliers = [];
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  void _loadSuppliers() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentState = context.read<SupplierBloc>().state;

        // Check if we have cached suppliers
        if (_cachedSuppliers.isNotEmpty && _hasLoadedOnce) {
          // Don't reload if we have cached data
          return;
        }

        // Load if state is not already loaded
        if (currentState is! SupplierListLoaded ||
            (currentState.suppliers.isEmpty)) {
          context.read<SupplierBloc>().add(LoadSuppliers());
        } else // Cache the existing suppliers
          setState(() {
            _cachedSuppliers = currentState.suppliers;
            _hasLoadedOnce = true;
          });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildSearchAndFilters(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Suppliers',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      actions: [
        // IconButton(
        //   icon: const Icon(Icons.filter_list, color: Colors.black87),
        //   onPressed: _showFilterSheet,
        // ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.black),
          onPressed: () {
            context.read<SupplierBloc>().add(LoadSuppliers());
          },
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            cursorColor: kPrimary,
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search suppliers...',
              hintStyle: WorkSansAppTextStyles.medium.copyWith(
                color: const Color(0xFF9E9E9E),
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF757575)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF757575)),
                      onPressed: () {
                        _searchController.clear();
                        context.read<SupplierBloc>().add(LoadSuppliers());
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              if (value.length >= 3 || value.isEmpty) {
                context.read<SupplierBloc>().add(SearchSuppliers(value));
              }
            },
          ),
          if (_selectedStatus != null || _selectedType != null) ...[
            const SizedBox(height: 12),
            _buildActiveFilters(),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Wrap(
      spacing: 8,
      children: [
        if (_selectedStatus != null)
          Chip(
            label: Text(
              _selectedStatus!.replaceAll('_', ' '),
              style: WorkSansAppTextStyles.medium.copyWith(fontSize: 12),
            ),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () {
              setState(() => _selectedStatus = null);
              context.read<SupplierBloc>().add(LoadSuppliers());
            },
          ),
        if (_selectedType != null)
          Chip(
            label: Text(
              _selectedType!,
              style: WorkSansAppTextStyles.medium.copyWith(fontSize: 12),
            ),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () {
              setState(() => _selectedType = null);
              context.read<SupplierBloc>().add(LoadSuppliers());
            },
          ),
      ],
    );
  }

  Widget _buildBody() {
    return BlocConsumer<SupplierBloc, SupplierState>(
      listener: (context, state) {
        // Update cache when suppliers are loaded
        if (state is SupplierListLoaded) {
          setState(() {
            _cachedSuppliers = state.suppliers;
            _hasLoadedOnce = true;
          });
        }
      },
      builder: (context, state) {
        // Show loading only on first load
        if (state is SupplierLoading && _cachedSuppliers.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimary),
          );
        }

        // Determine which suppliers to show
        List<dynamic> suppliersToShow = [];

        if (state is SupplierListLoaded) {
          suppliersToShow = state.suppliers;
        } else if (state is SupplierRefreshing) {
          suppliersToShow = state.currentSuppliers;
        } else if (_cachedSuppliers.isNotEmpty) {
          // Use cached suppliers if available
          suppliersToShow = _cachedSuppliers;
        }

        // Show empty state if no suppliers
        if (suppliersToShow.isEmpty && state is SupplierEmpty) {
          return _buildEmptyState();
        }

        // Show error state
        if (state is SupplierError && _cachedSuppliers.isEmpty) {
          return _buildErrorState(state);
        }

        // Show suppliers list (either from state or cache)
        if (suppliersToShow.isNotEmpty) {
          return RefreshIndicator(
            color: kPrimary,
            onRefresh: () async {
              context.read<SupplierBloc>().add(LoadSuppliers());
              // Wait for the refresh to complete
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              key: const PageStorageKey('supplier_list'),
              padding: const EdgeInsets.all(16),
              itemCount: suppliersToShow.length,
              itemBuilder: (context, index) {
                final supplier = suppliersToShow[index] as SupplierResponse;
                return _buildSupplierCard(supplier);
              },
            ),
          );
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildSupplierCard(SupplierResponse supplier) {
    final statusColor = _getStatusColor(supplier.status ?? '');

    return GestureDetector(
      onTap: () async {
        // Navigate and wait for result
        await Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => SupplierProductsScreen(supplier: supplier),
          ),
        );
        // State should be preserved when coming back
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: supplier.logo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              supplier.logo!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.business,
                                  size: 32,
                                  color: Colors.grey[400],
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.business,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                supplier.businessName ?? '',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (supplier.isVerified ?? false)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4CAF50,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          supplier.supplierType?.replaceAll('_', ' ') ?? '',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: const Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${supplier.city}, ${supplier.state}',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 12,
                                color: const Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6F6),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.access_time,
                      label: '${supplier.deliveryLeadTime} days',
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.shopping_cart,
                      label: '${supplier.totalOrders} orders',
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      supplier.status?.replaceAll('_', ' ') ?? '',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
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
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No suppliers found',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(SupplierError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.error,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: const Color(0xFF757575),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SupplierBloc>().add(LoadSuppliers());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Suppliers',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildFilterDropdown(
                    label: 'Status',
                    value: _selectedStatus,
                    items: [
                      'ACTIVE',
                      'INACTIVE',
                      'SUSPENDED',
                      'PENDING_APPROVAL',
                      'BLACKLISTED',
                    ],
                    onChanged: (value) {
                      setModalState(() => _selectedStatus = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFilterDropdown(
                    label: 'Supplier Type',
                    value: _selectedType,
                    items: [
                      'MANUFACTURER',
                      'DISTRIBUTOR',
                      'WHOLESALER',
                      'IMPORTER',
                      'LOCAL_PRODUCER',
                      'BROKER',
                    ],
                    onChanged: (value) {
                      setModalState(() => _selectedType = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedStatus = null;
                              _selectedType = null;
                            });
                            context.read<SupplierBloc>().add(LoadSuppliers());
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: kBlack),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            context.read<SupplierBloc>().add(
                              FilterSuppliers(
                                status: _selectedStatus,
                                supplierType: _selectedType,
                              ),
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(color: kWhite),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          hint: Text('Select $label'),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item.replaceAll('_', ' ')),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF4CAF50);
      case 'PENDING_APPROVAL':
        return const Color(0xFFFF9800);
      case 'SUSPENDED':
        return const Color(0xFFF44336);
      case 'INACTIVE':
        return const Color(0xFF9E9E9E);
      case 'BLACKLISTED':
        return const Color(0xFF000000);
      default:
        return const Color(0xFF757575);
    }
  }
}

class SupplierListWrapper extends StatelessWidget {
  const SupplierListWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => SupplierBloc(repository: SupplierRepository()),
      child: const SupplierListScreen(),
    );
  }
}
