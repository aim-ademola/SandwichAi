import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/sandwich_app_bar.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';

import 'package:sandwich_ai/src/features/stock_control/presentation/add_items_catalogue_screen.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/branch_stock.dart';

class StockCatalogScreen extends StatefulWidget {
  const StockCatalogScreen({super.key});

  @override
  State<StockCatalogScreen> createState() => _StockCatalogScreenState();
}

class _StockCatalogScreenState extends State<StockCatalogScreen> {
  bool _isTableView = false;
  String branchid = '';

  @override
  void initState() {
    super.initState();
    _getBranchId();
  }

  void _getBranchId() async {
    final id = await AuthCacheHelper.instance.getBranchID() ?? '';
    if (mounted) {
      setState(() {
        branchid = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
        appBar: _buildAppBar(context),
        body: InventoryBody(isTableView: _isTableView),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return SandwichAppBar(
      title: 'Stock Catalog',
      actions: [
        IconButton(
          icon: Icon(
            _isTableView ? Icons.grid_view : Icons.table_chart,
            color: context.modeTextPrimary,
          ),
          onPressed: () {
            setState(() {
              _isTableView = !_isTableView;
            });
          },
          tooltip: _isTableView ? 'Card View' : 'Table View',
        ),
        IconButton(
          icon: Icon(Icons.add, color: context.modeTextPrimary),
          onPressed: () async {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => AddEditStockScreen(branchId: branchid),
              ),
            );
          },
        ),
      ],
    );
  }
}
