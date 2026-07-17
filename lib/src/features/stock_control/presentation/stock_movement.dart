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
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: const BorderRadius.only(
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
                color: context.modeBorder,
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
                      color: context.modeTextPrimary,
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
                        color: context.modePrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Close',
                        textAlign: TextAlign.center,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.modeTextInverse,
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
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: const BorderRadius.only(
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
                color: context.modeTextPrimary,
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
              ? context.modePrimary.withValues(alpha: 0.1)
              : context.modeSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? context.modePrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? context.modePrimary : context.modeTextPrimary,
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
              color: context.modeTextSecondary,
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
                color: context.modeTextPrimary,
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
        backgroundColor: context.modeBackground,
        appBar: AppBar(
          backgroundColor: context.modeSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Inventory Movement',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton.filledTonal(
                icon: Icon(Icons.tune_rounded, color: context.modePrimary),
                style: IconButton.styleFrom(
                  backgroundColor: context.modePrimary.withValues(alpha: 0.1),
                ),
                onPressed: _showFilterBottomSheet,
                tooltip: 'Filter movements',
              ),
            ),
          ],
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
                      color: context.modeTextMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        color: context.modeTextSecondary,
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
                        backgroundColor: context.modePrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          color: context.modeTextInverse,
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
                color: context.modePrimary,
                onRefresh: () async {
                  context.read<StockMovementBloc>().add(
                    const RefreshStockMovements(),
                  );
                },
                child: _buildLoadedMovements(state),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildLoadedMovements(StockMovementLoaded state) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryHeader(state),
          const SizedBox(height: 18),
          _buildQuickFilters(),
          const SizedBox(height: 24),
          _buildMovementListHeader(state.filteredItems.length),
          const SizedBox(height: 10),
          if (state.filteredItems.isEmpty)
            _buildEmptyMovementState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.filteredItems.length,
              itemBuilder: (context, index) {
                final movement = state.filteredItems[index];
                return _buildMovementCard(movement);
              },
            ),
          if (state.isLoadingMore)
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Center(
                child: CircularProgressIndicator(color: context.modePrimary),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(StockMovementLoaded state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modePrimary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: context.modePrimary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.modeTextInverse.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: context.modeTextInverse,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Flow Summary',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.modeTextInverse,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Track incoming and outgoing inventory',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.modeTextInverse.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  icon: Icons.south_west_rounded,
                  title: 'Received',
                  value: '${state.totalReceived} KG',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryMetric(
                  icon: Icons.north_east_rounded,
                  title: 'Outbound',
                  value: '${state.totalConsumed} KG',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.modeTextInverse.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.modeTextInverse.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.modeTextInverse, size: 19),
          const SizedBox(height: 10),
          Text(
            title,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.modeTextInverse.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: context.modeTextInverse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    final filters = [
      ('All', null),
      ('Received', 'INFLOW'),
      ('Outbound', 'OUTFLOW'),
      ('Spoilage', 'SPOILAGE'),
      ('Transfer', 'TRANSFER'),
      ('Adjustment', 'ADJUSTMENT'),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedMovementType == filter.$2;
          return ChoiceChip(
            label: Text(filter.$1),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => _applyMovementFilter(filter.$2),
            selectedColor: context.modePrimary,
            backgroundColor: context.modeSurface,
            side: BorderSide(
              color: isSelected ? context.modePrimary : context.modeBorder,
            ),
            labelStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? context.modeTextInverse
                  : context.modeTextSecondary,
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: filters.length,
      ),
    );
  }

  void _applyMovementFilter(String? value) {
    setState(() {
      _selectedMovementType = value;
    });
    context.read<StockMovementBloc>().add(
      FilterByMovementType(movementType: value),
    );
  }

  Widget _buildMovementListHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Recent Movements',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.modeTextPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: context.modePrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count item${count == 1 ? '' : 's'}',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: context.modePrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMovementState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.modeBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: context.modeTextMuted),
          const SizedBox(height: 10),
          Text(
            'No movements found',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try changing the movement filter.',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: context.modeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementCard(StockMovementItem movement) {
    final accent = _movementAccent(movement.movementType);
    final iconData = _movementIcon(movement.movementType);

    return InkWell(
      onTap: () => _showMovementDetails(movement),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.modeBorder.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.16
                    : 0.04,
              ),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: accent, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          movement.item.itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.modeTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        movement.quantityDisplay,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildMovementBadge(
                        movement.movementType.displayName,
                        accent,
                      ),
                      Text(
                        movement.formattedDate,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 12,
                          color: context.modeTextMuted,
                        ),
                      ),
                      Text(
                        '${movement.balanceBefore} → ${movement.balanceAfter}',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 12,
                          color: context.modeTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: context.modeTextMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Color _movementAccent(MovementType type) {
    switch (type) {
      case MovementType.INFLOW:
        return context.modeSuccess;
      case MovementType.OUTFLOW:
        return context.modePrimary;
      case MovementType.SPOILAGE:
        return context.modeError;
      case MovementType.TRANSFER:
        return context.modePrimaryBlue;
      case MovementType.ADJUSTMENT:
        return context.modeWarning;
    }
  }

  IconData _movementIcon(MovementType type) {
    switch (type) {
      case MovementType.INFLOW:
        return Icons.south_west_rounded;
      case MovementType.OUTFLOW:
        return Icons.north_east_rounded;
      case MovementType.SPOILAGE:
        return Icons.warning_amber_rounded;
      case MovementType.TRANSFER:
        return Icons.swap_horiz_rounded;
      case MovementType.ADJUSTMENT:
        return Icons.tune_rounded;
    }
  }
}
