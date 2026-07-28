import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/response_wrapper.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_details_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_details_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_details_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/add_branch_stock_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/add_branch_stock_bloc/event.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/add_branch_stock_bloc/state.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/branch_details_model.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/stock_card_model.dart'
    as stock_card;
import 'package:sandwich_ai/src/features/stock_control/data/repo/stock_card_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/stock_adjustmnt.dart';

class BranchStockDetailsScreen extends StatefulWidget {
  final String stockId;
  final String itemName;

  const BranchStockDetailsScreen({
    super.key,
    required this.stockId,
    required this.itemName,
  });

  @override
  State<BranchStockDetailsScreen> createState() =>
      _BranchStockDetailsScreenState();
}

class _BranchStockDetailsScreenState extends State<BranchStockDetailsScreen> {
  Future<ApiResponse<List<stock_card.StockBatch>>>? _batchesFuture;
  String? _batchesKey;

  @override
  void initState() {
    super.initState();
    context.read<BranchStockDetailsBloc>().add(
      LoadBranchStockDetails(stockId: widget.stockId),
    );
  }

  Future<ApiResponse<List<stock_card.StockBatch>>> _getBatchesFuture(
    BranchStockDetails details,
  ) {
    final key = '${details.branchId}:${details.itemId}';
    if (_batchesFuture == null || _batchesKey != key) {
      _batchesKey = key;
      _batchesFuture = context.read<StockCardRepositoryInterface>().getBatches(
        branchId: details.branchId,
        itemId: details.itemId,
      );
    }
    return _batchesFuture!;
  }

  void _reloadBatches(BranchStockDetails details) {
    setState(() {
      _batchesKey = null;
      _batchesFuture = null;
    });
    _getBatchesFuture(details);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'IN_STOCK':
        return const Color(0xFF10B981);
      case 'LOW_STOCK':
        return const Color(0xFFF59E0B);
      case 'OUT_OF_STOCK':
        return const Color(0xFFEF4444);
      case 'REORDER':
        return const Color(0xFFF97316);
      default:
        return kprimaryTextColor2;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'IN_STOCK':
        return 'In Stock';
      case 'LOW_STOCK':
        return 'Low Stock';
      case 'OUT_OF_STOCK':
        return 'Out of Stock';
      case 'REORDER':
        return 'Reorder Required';
      default:
        return status;
    }
  }

  void _showDeleteConfirmation(BranchStockDetails details) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.modeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: AppIcon(
                  Icons.warning_rounded,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Stock Item?',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: dialogContext.modeTextPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${details.item.itemName}"? This action cannot be undone.',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: dialogContext.modeTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: dialogContext.modeTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AddBranchStockBloc>().add(
                DeleteBranchStock(
                  stockId: widget.stockId,
                  itemName: details.item.itemName,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustmentDialog(BranchStockDetails details) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AddBranchStockBloc>(),
        child: StockAdjustmentDialog(
          stockId: widget.stockId,
          itemName: details.item.itemName,
          currentStock: double.parse(details.currentStock),
          unit: details.item.unit,
          performedBy: 'current-user-id', // Replace with actual user ID
        ),
      ),
    );
  }

  void _showStockControlConfirmation({
    required String title,
    required String message,
    required IconData icon,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.modeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            AppIcon(icon, color: kPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: dialogContext.modeTextPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: dialogContext.modeTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: dialogContext.modeTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLockStockConfirmation(BranchStockDetails details) async {
    final reasonController = TextEditingController();
    try {
      await showDialog(
        context: context,
        builder: (dialogContext) {
          var reason = '';
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final isValid = reason.trim().length >= 5;
              return AlertDialog(
                backgroundColor: dialogContext.modeSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    const AppIcon(Icons.lock_outline, color: kPrimary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Lock Stock?',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: dialogContext.modeTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This will lock "${details.item.itemName}" and prevent stock movement until it is unlocked by an authorized user.',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: dialogContext.modeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      minLines: 2,
                      maxLines: 3,
                      onChanged: (value) =>
                          setDialogState(() => reason = value),
                      style: WorkSansAppTextStyles.medium.copyWith(
                        color: dialogContext.modeTextPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        hintText: 'Enter lock reason',
                        errorText: reason.isNotEmpty && !isValid
                            ? 'Reason must be at least 5 characters'
                            : null,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: dialogContext.modeTextSecondary),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isValid
                        ? () {
                            Navigator.pop(dialogContext);
                            context.read<AddBranchStockBloc>().add(
                              LockBranchStock(
                                stockId: widget.stockId,
                                reason: reason.trim(),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      reasonController.dispose();
    }
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
            widget.itemName,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            BlocBuilder<BranchStockDetailsBloc, BranchStockDetailsState>(
              builder: (context, state) {
                if (state is BranchStockDetailsLoaded) {
                  return PopupMenuButton<String>(
                    color: context.modeSurface,
                    icon: AppIcon(
                      Icons.more_vert,
                      color: context.modeTextPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'adjust':
                          _showAdjustmentDialog(state.details);
                          break;
                        case 'allow_negative':
                          _showStockControlConfirmation(
                            title: 'Allow Negative Stock?',
                            message:
                                'This permits stock quantity for "${state.details.item.itemName}" to go below zero. Use only when stock movement must continue before reconciliation.',
                            icon: Icons.exposure_minus_1,
                            onConfirm: () {
                              context.read<AddBranchStockBloc>().add(
                                AllowNegativeBranchStock(
                                  stockId: widget.stockId,
                                  allow: true,
                                ),
                              );
                            },
                          );
                          break;
                        case 'lock':
                          _showLockStockConfirmation(state.details);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(state.details);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'adjust',
                        child: Row(
                          children: [
                            AppIcon(
                              Icons.tune_rounded,
                              size: 20,
                              color: kPrimary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Adjust Stock',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                color: context.modeTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'allow_negative',
                        child: Row(
                          children: [
                            AppIcon(
                              Icons.exposure_minus_1,
                              size: 20,
                              color: kPrimary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Allow Negative Stock',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                color: context.modeTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'lock',
                        child: Row(
                          children: [
                            AppIcon(
                              Icons.lock_outline,
                              size: 20,
                              color: kPrimary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Lock Stock',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                color: context.modeTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const AppIcon(
                              Icons.delete_outline,
                              size: 20,
                              color: kPrimary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Delete Item',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<BranchStockDetailsBloc, BranchStockDetailsState>(
              listener: (context, state) {
                if (state is BranchStockDetailsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
            ),
            BlocListener<AddBranchStockBloc, BranchStockState>(
              listener: (context, state) {
                if (state is BranchStockSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );

                  if (state.isDelete) {
                    // Navigate back after successful delete
                    Navigator.of(context).pop();
                  } else if (state.isAdjustment || state.isControlAction) {
                    // Reload details after adjustment
                    context.read<BranchStockDetailsBloc>().add(
                      RefreshBranchStockDetails(stockId: widget.stockId),
                    );
                  }
                } else if (state is BranchStockError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
          child: BlocBuilder<BranchStockDetailsBloc, BranchStockDetailsState>(
            builder: (context, state) {
              if (state is BranchStockDetailsLoading ||
                  state is BranchStockDetailsRefreshing) {
                return _buildLoadingState();
              }

              if (state is BranchStockDetailsError) {
                return _buildErrorState(state.error);
              }

              if (state is BranchStockDetailsLoaded) {
                return _buildLoadedState(state.details);
              }

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return shimmerCatalogCard(constraints.maxWidth);
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 16,
                color: context.modeTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<BranchStockDetailsBloc>().add(
                  LoadBranchStockDetails(stockId: widget.stockId),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Widget _buildLoadedState(BranchStockDetails details) {
    final statusColor = _getStatusColor(details.status);
    final stockPercentage = details.stockPercentage;
    final isLowStock = stockPercentage <= 25;
    final isCritical = stockPercentage <= 10;
    final description = _cleanDisplayText(details.item.description);

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async {
        setState(() {
          _batchesKey = null;
          _batchesFuture = null;
        });
        context.read<BranchStockDetailsBloc>().add(
          RefreshBranchStockDetails(stockId: widget.stockId),
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Status Card with Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      statusColor.withValues(alpha: 0.1),
                      statusColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Stock',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                color: context.modeTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${details.currentStock} ${details.item.unit}',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: context.modeTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            _getStatusDisplayName(details.status),
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stock Level Progress Bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Stock Level',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 13,
                                color: context.modeTextSecondary,
                              ),
                            ),
                            Text(
                              '${stockPercentage.toStringAsFixed(1)}%',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: stockPercentage / 100,
                            minHeight: 10,
                            backgroundColor: context.modeSurfaceAlt,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (isLowStock) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCritical
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            AppIcon(
                              isCritical
                                  ? Icons.warning_rounded
                                  : Icons.info_outline,
                              color: isCritical
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF59E0B),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isCritical
                                    ? 'Critical stock level! Immediate reorder required.'
                                    : 'Stock running low. Consider reordering soon.',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isCritical
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Action Button
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: ElevatedButton.icon(
                    //     onPressed: () => _showAdjustmentDialog(details),
                    //     // icon: const AppIcon(Icons.tune_rounded, size: 20),
                    //     label: Text(
                    //       'Adjust Stock',
                    //       style: WorkSansAppTextStyles.medium.copyWith(
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.w600,
                    //         color: kWhite,
                    //       ),
                    //     ),
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: kPrimary,
                    //       foregroundColor: Colors.white,
                    //       padding: const EdgeInsets.symmetric(vertical: 16),
                    //       elevation: 0,
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stock Levels Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Stock Levels',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: context.modeSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.modeBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: context.modeTextPrimary.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStockLevelItem(
                      icon: Icons.arrow_upward_rounded,
                      iconColor: const Color(0xFF10B981),
                      label: 'Maximum Level',
                      value: '${details.maxLevel} ${details.item.unit}',
                      isFirst: true,
                    ),
                    _buildDivider(),
                    _buildStockLevelItem(
                      icon: Icons.inventory_2_outlined,
                      iconColor: kPrimary,
                      label: 'Current Stock',
                      value: '${details.currentStock} ${details.item.unit}',
                    ),
                    _buildDivider(),
                    _buildStockLevelItem(
                      icon: Icons.arrow_downward_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      label: 'Reorder Level',
                      value: '${details.reorderLevel} ${details.item.unit}',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Financial Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Financial Information',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: context.modeSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.modeBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: context.modeTextPrimary.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildFinancialItem(
                      label: 'Unit Cost',
                      value: details.formattedUnitCost,
                      icon: Icons.attach_money_rounded,
                      isFirst: true,
                    ),
                    _buildDivider(),
                    _buildFinancialItem(
                      label: 'Total Value',
                      value: details.formattedTotalValue,
                      icon: Icons.account_balance_wallet_outlined,
                      isHighlighted: true,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            _buildBatchesSection(details),

            const SizedBox(height: 24),

            // Item & Branch Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Details',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.modeTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.modeSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.modeBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: context.modeTextPrimary.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Item Name', details.item.itemName),
                    const SizedBox(height: 16),
                    _buildDetailRow('Category', details.item.category),
                    const SizedBox(height: 16),
                    _buildDetailRow('SKU', details.item.sku),
                    const SizedBox(height: 16),
                    _buildDetailRow('Unit', details.item.unit),
                    if (description != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow('Description', description),
                    ],
                    const SizedBox(height: 16),
                    _buildDetailRow('Branch', details.branch.name),
                    const SizedBox(height: 16),
                    _buildDetailRow('Branch Code', details.branch.branchCode),
                    if (details.expiryDate != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Expiry Date',
                        details.formattedExpiryDate!,
                        isWarning: details.isExpiringSoon,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Last Updated',
                      details.formattedLastUpdated,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchesSection(BranchStockDetails details) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Batches & Expiry',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh batches',
                onPressed: () => _reloadBatches(details),
                icon: AppIcon(
                  Icons.refresh_rounded,
                  color: context.modeTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<ApiResponse<List<stock_card.StockBatch>>>(
            future: _getBatchesFuture(details),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: _sectionDecoration(),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Loading batches...',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          color: context.modeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final response = snapshot.data;
              if (response == null || !response.isSuccess) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: _sectionDecoration(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppIcon(
                        Icons.error_outline,
                        color: Color(0xFFEF4444),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          response?.error?.toString() ??
                              'Could not load batch details.',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            color: context.modeTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final batches = response.data ?? const <stock_card.StockBatch>[];
              if (batches.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: _sectionDecoration(),
                  child: Row(
                    children: [
                      AppIcon(
                        Icons.inventory_2_outlined,
                        color: context.modeTextSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'No batches found for this item.',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          color: context.modeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final previewBatches = batches.take(1).toList();
              return Container(
                decoration: _sectionDecoration(),
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < previewBatches.length;
                      index++
                    ) ...[
                      _buildBatchItem(previewBatches[index], index),
                      if (index != previewBatches.length - 1 ||
                          batches.length > 1)
                        _buildDivider(),
                    ],
                    if (batches.length > 1)
                      _buildShowMoreBatchesButton(details, batches),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShowMoreBatchesButton(
    BranchStockDetails details,
    List<stock_card.StockBatch> batches,
  ) {
    return TextButton(
      onPressed: () => _showAllBatchesBottomSheet(details, batches),
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: kPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Show more batches',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kPrimary,
            ),
          ),
          const SizedBox(width: 8),
          const AppIcon(Icons.keyboard_arrow_up_rounded, size: 20),
        ],
      ),
    );
  }

  void _showAllBatchesBottomSheet(
    BranchStockDetails details,
    List<stock_card.StockBatch> batches,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.modeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Batches',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: context.modeTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${details.item.itemName} - ${batches.length} batches',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 13,
                                color: context.modeTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: AppIcon(
                          Icons.close_rounded,
                          color: context.modeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: context.modeDivider, height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: batches.length,
                    separatorBuilder: (_, _) => _buildDivider(),
                    itemBuilder: (context, index) =>
                        _buildBatchItem(batches[index], index),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBatchItem(stock_card.StockBatch batch, int index) {
    final batchName =
        _cleanDisplayText(batch.batchNumber) ?? 'Batch ${index + 1}';
    final expiryText = _formatBatchExpiry(batch.expiryDate);
    final expiryColor = _getBatchExpiryColor(batch.expiryDate);
    final status = _cleanDisplayText(batch.status);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: expiryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: AppIcon(
                Icons.qr_code_2_rounded,
                color: expiryColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batchName,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.modeTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Qty: ${_formatQuantity(batch.quantity)} ${batch.unit}',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: context.modeTextSecondary,
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.modeTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Expiry',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 12,
                  color: context.modeTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isBatchExpiringSoon(batch.expiryDate)) ...[
                    AppIcon(
                      Icons.warning_rounded,
                      size: 15,
                      color: expiryColor,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    expiryText,
                    textAlign: TextAlign.right,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: expiryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockLevelItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: isFirst ? 20 : 16,
        bottom: isLast ? 20 : 16,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: AppIcon(icon, color: iconColor, size: 22)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: context.modeTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.modeTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem({
    required String label,
    required String value,
    required IconData icon,
    bool isFirst = false,
    bool isLast = false,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: isFirst ? 20 : 16,
        bottom: isLast ? 20 : 16,
      ),
      decoration: isHighlighted
          ? BoxDecoration(
              color: kPrimary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: AppIcon(icon, color: kPrimary, size: 22)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: context.modeTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: isHighlighted ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: isHighlighted ? kPrimary : context.modeTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isWarning = false}) {
    return Row(
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
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isWarning) ...[
                const AppIcon(
                  Icons.warning_rounded,
                  size: 16,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isWarning
                        ? const Color(0xFFF59E0B)
                        : context.modeTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(color: context.modeDivider, height: 1),
    );
  }

  BoxDecoration _sectionDecoration() {
    return BoxDecoration(
      color: context.modeSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.modeBorder, width: 1),
      boxShadow: [
        BoxShadow(
          color: context.modeTextPrimary.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  String _formatBatchExpiry(DateTime? expiryDate) {
    if (expiryDate == null) return 'N/A';
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final expiryOnly = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );
    final days = expiryOnly.difference(todayOnly).inDays;
    final date = DateFormat('MMM dd, yyyy').format(expiryDate);

    if (days < 0) return '$date (${days.abs()}d ago)';
    if (days == 0) return '$date (today)';
    if (days == 1) return '$date (tomorrow)';
    return '$date (${days}d)';
  }

  bool _isBatchExpiringSoon(DateTime? expiryDate) {
    if (expiryDate == null) return false;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final expiryOnly = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );
    final days = expiryOnly.difference(todayOnly).inDays;
    return days <= 30;
  }

  Color _getBatchExpiryColor(DateTime? expiryDate) {
    if (expiryDate == null) return context.modeTextSecondary;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final expiryOnly = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );
    final days = expiryOnly.difference(todayOnly).inDays;
    if (days < 0) return const Color(0xFFEF4444);
    if (days <= 7) return const Color(0xFFF97316);
    if (days <= 30) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  String? _cleanDisplayText(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }
}
