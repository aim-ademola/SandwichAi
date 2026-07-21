import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
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
        } else {
          // Cache the existing suppliers
          setState(() {
            _cachedSuppliers = currentState.suppliers;
            _hasLoadedOnce = true;
          });
        }
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
        backgroundColor: context.modeBackground,
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
      backgroundColor: context.modeSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: Text(
        'Suppliers',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: context.modeTextPrimary,
        ),
      ),
      actions: [
        // IconButton(
        //   icon: const AppIcon(Icons.filter_list, color: Colors.black87),
        //   onPressed: _showFilterSheet,
        // ),
        IconButton(
          icon: AppIcon(Icons.refresh, color: context.modeTextPrimary),
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
      color: context.modeSurface,
      child: Column(
        children: [
          TextField(
            cursorColor: context.modePrimary,
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search suppliers...',
              hintStyle: WorkSansAppTextStyles.medium.copyWith(
                color: context.modeTextMuted,
              ),
              prefixIcon: AppIcon(Icons.search, color: context.modeTextMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: AppIcon(Icons.clear, color: context.modeTextMuted),
                      onPressed: () {
                        _searchController.clear();
                        context.read<SupplierBloc>().add(LoadSuppliers());
                      },
                    )
                  : null,
              filled: true,
              fillColor: context.modeSurfaceAlt,
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
            deleteIcon: const AppIcon(Icons.close, size: 16),
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
            deleteIcon: const AppIcon(Icons.close, size: 16),
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
          return Center(
            child: CircularProgressIndicator(color: context.modePrimary),
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
            color: context.modePrimary,
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
          color: context.modeSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.modeBorder, width: 1),
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
                      color: context.modeSurfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: supplier.logo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              supplier.logo!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return AppIcon(
                                  Icons.business,
                                  size: 32,
                                  color: context.modeTextMuted,
                                );
                              },
                            ),
                          )
                        : AppIcon(
                            Icons.business,
                            size: 32,
                            color: context.modeTextMuted,
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
                                  color: context.modeTextPrimary,
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
                                  color: context.modeSuccess.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: AppIcon(
                                  Icons.verified,
                                  size: 16,
                                  color: context.modeSuccess,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          supplier.supplierType?.replaceAll('_', ' ') ?? '',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: context.modeTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            AppIcon(
                              Icons.location_on,
                              size: 14,
                              color: context.modeTextMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${supplier.city}, ${supplier.state}',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 12,
                                color: context.modeTextSecondary,
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
                color: context.modeSurfaceAlt,
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
                      color: context.modeInfo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.shopping_cart,
                      label: '${supplier.totalOrders} orders',
                      color: context.modeWarning,
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
          AppIcon(icon, size: 14, color: color),
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
          AppIcon(
            Icons.inventory_2_outlined,
            size: 80,
            color: context.modeTextMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No suppliers found',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.modeTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: context.modeTextMuted,
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
            AppIcon(Icons.error_outline, size: 80, color: context.modeError),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.error,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SupplierBloc>().add(LoadSuppliers());
              },
              icon: const AppIcon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                foregroundColor: context.modeTextInverse,
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

  // Widget _buildFilterDropdown({
  //   required String label,
  //   required String? value,
  //   required List<String> items,
  //   required ValueChanged<String?> onChanged,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: WorkSansAppTextStyles.medium.copyWith(
  //           fontSize: 14,
  //           fontWeight: FontWeight.w600,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       DropdownButtonFormField<String>(
  //         initialValue: value,
  //         decoration: InputDecoration(
  //           filled: true,
  //           fillColor: context.modeSurfaceAlt,
  //           border: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(12),
  //             borderSide: BorderSide.none,
  //           ),
  //         ),
  //         hint: Text('Select $label'),
  //         items: items
  //             .map(
  //               (item) => DropdownMenuItem(
  //                 value: item,
  //                 child: Text(item.replaceAll('_', ' ')),
  //               ),
  //             )
  //             .toList(),
  //         onChanged: onChanged,
  //       ),
  //     ],
  //   );
  // }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return context.modeSuccess;
      case 'PENDING_APPROVAL':
        return context.modeWarning;
      case 'SUSPENDED':
        return context.modeError;
      case 'INACTIVE':
        return context.modeTextMuted;
      case 'BLACKLISTED':
        return context.modeTextPrimary;
      default:
        return context.modeTextSecondary;
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
