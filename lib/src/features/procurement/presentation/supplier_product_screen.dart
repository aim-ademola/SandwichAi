import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/supplier_model.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/event.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/state.dart';

class SupplierProductsScreen extends StatefulWidget {
  final SupplierResponse supplier;

  const SupplierProductsScreen({super.key, required this.supplier});

  @override
  State<SupplierProductsScreen> createState() => _SupplierProductsScreenState();
}

class _SupplierProductsScreenState extends State<SupplierProductsScreen> {
  String? _selectedCategory;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();

    context.read<SupplierBloc>().add(
      LoadSupplierProducts(supplierId: widget.supplier.id ?? ''),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildSupplierHeader()),
            SliverToBoxAdapter(child: _buildFilters()),
            _buildProductsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: context.modeSurface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.modePrimary,
                context.modePrimary.withValues(alpha: 0.74),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: context.modeTextInverse,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: widget.supplier.logo != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.supplier.logo!,
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
                                    widget.supplier.businessName ?? '',
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: context.modeTextInverse,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.supplier.isVerified ?? false)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: context.modeTextInverse.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: AppIcon(
                                      Icons.verified,
                                      size: 18,
                                      color: context.modeTextInverse,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.supplier.supplierType?.replaceAll(
                                    '_',
                                    ' ',
                                  ) ??
                                  '',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 13,
                                color: context.modeTextInverse.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modeBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supplier Information',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.location_on,
            label: 'Location',
            value: '${widget.supplier.city}, ${widget.supplier.state}',
            color: context.modeInfo,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.phone,
            label: 'Phone',
            value: widget.supplier.phone ?? '',
            color: context.modeSuccess,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.email,
            label: 'Email',
            value: widget.supplier.email ?? '',
            color: context.modeWarning,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Lead Time',
            value: '${widget.supplier.deliveryLeadTime} days',
            color: context.modePrimaryAlt,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.payments,
            label: 'Min Order',
            value:
                '${widget.supplier.defaultCurrency} ${widget.supplier.minimumOrderValue?.toStringAsFixed(2)}',
            color: context.modeError,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppIcon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 12,
                  color: context.modeTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
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
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              label: 'Category',
              value: _selectedCategory,
              onTap: () => _showCategoryFilter(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterChip(
              label: 'Status',
              value: _selectedStatus,
              onTap: () => _showStatusFilter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value != null
              ? context.modeInfo.withValues(alpha: 0.1)
              : context.modeSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value != null ? context.modeInfo : context.modeBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value ?? label,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: value != null
                      ? context.modeInfo
                      : context.modeTextSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppIcon(
              Icons.arrow_drop_down,
              size: 20,
              color: value != null
                  ? context.modeInfo
                  : context.modeTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return BlocBuilder<SupplierBloc, SupplierState>(
      builder: (context, state) {
        if (state is SupplierLoading) {
          return SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: context.modePrimary),
            ),
          );
        }

        if (state is SupplierEmpty) {
          return SliverFillRemaining(child: _buildEmptyState());
        }

        if (state is SupplierError) {
          return SliverFillRemaining(child: _buildErrorState(state));
        }

        if (state is SupplierProductsLoaded) {
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product =
                    state.products[index] as SupplierProductResponse;
                return _buildProductCard(product);
              }, childCount: state.products.length),
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox());
      },
    );
  }

  Widget _buildProductCard(SupplierProductResponse product) {
    final statusColor = _getStatusColor(product.status ?? '');

    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.modeBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: context.modeSurfaceAlt,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: product.primaryImage != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            product.primaryImage!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: AppIcon(
                                  Icons.fastfood,
                                  size: 40,
                                  color: context.modeTextMuted,
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: AppIcon(
                            Icons.fastfood,
                            size: 40,
                            color: context.modeTextMuted,
                          ),
                        ),
                ),
                if (product.isFeatured)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.modeWarning,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(
                            Icons.star,
                            size: 12,
                            color: context.modeTextInverse,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Featured',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: context.modeTextInverse,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName ?? '',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.modeTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category?.replaceAll('_', ' ') ?? '',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 11,
                        color: context.modeTextSecondary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${product.currency} ${product.baseUnitPrice}',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.modePrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            'No products available',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.modeTextSecondary,
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
              state.error,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
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
              onPressed: () {
                context.read<SupplierBloc>().add(
                  LoadSupplierProducts(supplierId: widget.supplier.id ?? ''),
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: context.modeSurface,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Category',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...[
                'PROTEIN',
                'GRAIN',
                'SPICE',
                'VEGETABLE',
                'DAIRY',
                'BEVERAGE',
                'OIL',
                'SEASONING',
                'OTHERS',
              ].map((category) {
                return ListTile(
                  title: Text(
                    category.replaceAll('_', ' '),
                    style: TextStyle(color: context.modeTextPrimary),
                  ),
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    context.read<SupplierBloc>().add(
                      LoadSupplierProducts(
                        supplierId: widget.supplier.id ?? '',
                        category: category,
                      ),
                    );
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: context.modeSurface,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Status',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.modeTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...[
                'AVAILABLE',
                'LOW_STOCK',
                'OUT_OF_STOCK',
                'DISCONTINUED',
                'SEASONAL',
              ].map((status) {
                return ListTile(
                  title: Text(
                    status.replaceAll('_', ' '),
                    style: TextStyle(color: context.modeTextPrimary),
                  ),
                  onTap: () {
                    setState(() => _selectedStatus = status);
                    context.read<SupplierBloc>().add(
                      LoadSupplierProducts(
                        supplierId: widget.supplier.id ?? '',
                        status: status,
                      ),
                    );
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showProductDetails(SupplierProductResponse product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: context.modeSurface,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.modeDivider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // if (product.primaryImage != null)
                  //   ClipRRect(
                  //     borderRadius: BorderRadius.circular(16),
                  //     child: Image.network(
                  //       product.primaryImage!,
                  //       width: double.infinity,
                  //       height: 200,
                  //       fit: BoxFit.cover,
                  //     ),
                  //   ),
                  const SizedBox(height: 24),
                  Text(
                    product.productName ?? '',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: context.modeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description ?? '',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: context.modeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('Product Code', product.productCode ?? ''),
                  _buildDetailRow('Category', product.category ?? ''),
                  _buildDetailRow(
                    'Price',
                    '${product.currency} ${product.baseUnitPrice}',
                  ),
                  _buildDetailRow('Unit Type', product.unitType ?? ''),
                  _buildDetailRow('Packaging', product.packagingType ?? ''),
                  _buildDetailRow(
                    'Min Order Qty',
                    product.minimumOrderQty ?? '',
                  ),
                  _buildDetailRow(
                    'Available Stock',
                    product.availableStock ?? '',
                  ),
                  _buildDetailRow('Lead Time', '${product.leadTime} days'),
                  _buildDetailRow('Shelf Life', '${product.shelfLife} days'),
                  if (product.brand != null)
                    _buildDetailRow('Brand', product.brand!),
                  if (product.origin != null)
                    _buildDetailRow('Origin', product.origin!),
                  const SizedBox(height: 24),
                  if (product.certifications.isNotEmpty) ...[
                    Text(
                      'Certifications',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.modeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.certifications
                          .map(
                            (cert) => Chip(
                              label: Text(cert ?? ''),
                              backgroundColor: context.modeSuccess.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return context.modeSuccess;
      case 'LOW_STOCK':
        return context.modeWarning;
      case 'OUT_OF_STOCK':
        return context.modeError;
      case 'DISCONTINUED':
        return context.modeTextMuted;
      case 'SEASONAL':
        return context.modeInfo;
      default:
        return context.modeTextSecondary;
    }
  }
}
