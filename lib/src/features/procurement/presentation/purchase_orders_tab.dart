import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/order_form.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/order_list.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/reorder_model.dart';

class PurchaseOrdersTabScreen extends StatefulWidget {
  final int initialIndex;
  final ReorderSuggestion? reorderSuggestion;

  const PurchaseOrdersTabScreen({
    super.key,
    this.initialIndex = 0,
    this.reorderSuggestion,
  });

  @override
  State<PurchaseOrdersTabScreen> createState() =>
      _PurchaseOrdersTabScreenState();
}

class _PurchaseOrdersTabScreenState extends State<PurchaseOrdersTabScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
        appBar: AppBar(
          backgroundColor: context.modeSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Purchase Orders',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.modeTextPrimary,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: context.modeSurface,
              child: TabBar(
                controller: _tabController,
                labelColor: context.modePrimary,
                unselectedLabelColor: context.modeTextSecondary,
                indicatorColor: context.modePrimary,
                indicatorWeight: 3,
                labelStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Create PO'),
                  Tab(text: 'PO History'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            OrderFormScreen(
              showAppBar: false,
              reorderSuggestion: widget.reorderSuggestion,
            ),
            const OrdersListScreen(showAppBar: false),
          ],
        ),
      ),
    );
  }
}
