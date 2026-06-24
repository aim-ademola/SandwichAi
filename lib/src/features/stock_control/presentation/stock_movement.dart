import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock-movement_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock-movement_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock-movement_bloc/state.dart';

import 'package:sandwich_ai/src/features/stock_control/data/model/stock_movement_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/stock_movement.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart'
    show shimmerCatalogCard;

class InventoryMovementScreen extends StatefulWidget {
  const InventoryMovementScreen({super.key});

  @override
  State<InventoryMovementScreen> createState() =>
      _InventoryMovementScreenState();
}

class _InventoryMovementScreenState extends State<InventoryMovementScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedMovementType;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial data
    context.read<StockMovementBloc>().add(
      LoadStockMovements(
        query: StockMovementQuery(
          branchId: context.read<StockMovementBloc>().branchId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<StockMovementBloc>().add(const LoadMoreStockMovements());
    }
  }

  void _showMovementDetails(StockMovementItem movement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Movement Details',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('Item', movement.item.itemName),
                  _buildDetailRow('Quantity', movement.quantityDisplay),
                  _buildDetailRow('Type', movement.movementType.displayName),
                  _buildDetailRow(
                    'Quantity Before',
                    '${movement.balanceBefore} ${movement.item.unit}',
                  ),
                  _buildDetailRow(
                    'Quantity After',
                    '${movement.balanceAfter} ${movement.item.unit}',
                  ),
                  _buildDetailRow('Date', movement.formattedDate),
                  if (movement.note != null)
                    _buildDetailRow('Note', movement.note!),
                  if (movement.reference != null)
                    _buildDetailRow('Reference', movement.reference!),
                  _buildDetailRow('Performed By', movement.performedBy),
                  _buildDetailRow('Branch', movement.branch.name),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Close',
                        textAlign: TextAlign.center,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Type',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 20),
            _buildFilterChip('All', null, bottomSheetContext),
            _buildFilterChip('Received', 'INFLOW', bottomSheetContext),
            _buildFilterChip('Outbound', 'OUTFLOW', bottomSheetContext),
            _buildFilterChip('Spoilage', 'SPOILAGE', bottomSheetContext),
            _buildFilterChip('Transfer', 'TRANSFER', bottomSheetContext),
            _buildFilterChip('Adjustment', 'ADJUSTMENT', bottomSheetContext),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? value,
    BuildContext bottomSheetContext,
  ) {
    final isSelected = _selectedMovementType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMovementType = value;
        });
        context.read<StockMovementBloc>().add(
          FilterByMovementType(movementType: value),
        );
        Navigator.pop(bottomSheetContext);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimary.withValues(alpha: 0.1)
              : const Color(0xFFF8F6F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? kPrimary : kprimaryTextColor1,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: kprimaryTextColor2,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Inventory Movement',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          centerTitle: true,
          // actions: [
          //   IconButton(
          //     icon: const Icon(Icons.filter_list, color: kprimaryTextColor1),
          //     onPressed: _showFilterBottomSheet,
          //   ),
          // ],
        ),
        body: BlocConsumer<StockMovementBloc, StockMovementState>(
          listener: (context, state) {
            if (state is StockMovementError) {}
          },
          builder: (context, state) {
            if (state is StockMovementLoading ||
                state is StockMovementRefreshing) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return shimmerCatalogCard(constraints.maxWidth);
                },
              );
            }

            if (state is StockMovementError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        color: kprimaryTextColor2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<StockMovementBloc>().add(
                          LoadStockMovements(
                            query: StockMovementQuery(
                              branchId: context
                                  .read<StockMovementBloc>()
                                  .branchId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
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

            if (state is StockMovementLoaded) {
              return RefreshIndicator(
                color: kPrimary,
                onRefresh: () async {
                  context.read<StockMovementBloc>().add(
                    const RefreshStockMovements(),
                  );
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Summary Cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSummaryItem(
                                icon: Icons.local_shipping,
                                iconColor: kPrimary,
                                iconBgColor: kPrimary.withValues(alpha: 0.1),
                                title: 'Received',
                                value: '${state.totalReceived} KG',
                              ),
                              const SizedBox(height: 16),
                              Divider(color: Colors.grey.shade200, height: 1),
                              const SizedBox(height: 16),
                              _buildSummaryItem(
                                icon: Icons.inventory_2,
                                iconColor: kPrimary,
                                iconBgColor: kPrimary.withValues(alpha: 0.1),
                                title: 'Outbound',
                                value: '${state.totalConsumed} KG',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Movement List Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Movements',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: kprimaryTextColor1,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${state.filteredItems.length} items',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Movement Items
                      if (state.filteredItems.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48.0),
                            child: Text(
                              'No movements found',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 16,
                                color: kprimaryTextColor2,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.filteredItems.length,
                          itemBuilder: (context, index) {
                            final movement = state.filteredItems[index];
                            return GestureDetector(
                              onTap: () => _showMovementDetails(movement),
                              child: _buildMovementCard(movement),
                            );
                          },
                        ),

                      // Loading more indicator
                      if (state.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildMovementCard(StockMovementItem movement) {
    final isInflow = movement.movementType == MovementType.INFLOW;
    final iconData = isInflow ? Icons.local_shipping : Icons.inventory_2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: kPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${movement.movementType.displayName} ${movement.quantityDisplay}',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kprimaryTextColor1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  movement.item.itemName,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: kprimaryTextColor2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  movement.formattedDate,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: kprimaryTextColor2,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: kprimaryTextColor2, size: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kprimaryTextColor2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kprimaryTextColor1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
