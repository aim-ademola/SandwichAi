import 'package:flutter/material.dart';

import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/stock_control_dashboard_body.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/stock_control_drawer.dart';

class StockControlDashboardScreen extends StatefulWidget {
  const StockControlDashboardScreen({super.key});

  @override
  State<StockControlDashboardScreen> createState() =>
      _StockControlDashboardScreenState();
}

class _StockControlDashboardScreenState
    extends State<StockControlDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        drawer: StockControlAppDrawer(),
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: _buildAppBar(context),
        body: StockControlDashboardBodyScreen(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: Text(
        'Inventory Overview',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
    );
  }
}
