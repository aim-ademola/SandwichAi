import 'package:flutter/material.dart';

import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/globals/notifications/notification_bell.dart';
import 'package:sandwich_ai/src/core/globals/sandwich_app_bar.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
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
        backgroundColor: context.modeBackground,
        appBar: _buildAppBar(context),
        body: StockControlDashboardBodyScreen(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return SandwichAppBar(
      title: '',
      centerTitle: false,
      onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      actions: const [NotificationBellAction()],
    );
  }
}
