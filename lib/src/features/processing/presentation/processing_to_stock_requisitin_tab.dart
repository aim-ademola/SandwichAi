import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/stock_request_repo.dart';
import 'package:sandwich_ai/src/features/processing/presentation/req_stock.dart';
import 'package:sandwich_ai/src/features/processing/presentation/stock_req_history.dart';

class ProcesssingToStockRequisitionTabScreen extends StatefulWidget {
  final String dpt;
  const ProcesssingToStockRequisitionTabScreen({super.key, required this.dpt});

  @override
  State<ProcesssingToStockRequisitionTabScreen> createState() =>
      _ProcesssingToStockRequisitionTabScreenState();
}

class _ProcesssingToStockRequisitionTabScreenState
    extends State<ProcesssingToStockRequisitionTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          StockRequestBloc(repository: StockRequestRepository()),
      child: DefaultTextStyle.merge(
        style: WorkSansAppTextStyles.medium,
        child: Scaffold(
          backgroundColor: context.modeBackground,
          appBar: AppBar(
            backgroundColor: context.modeSurface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Stock Requisition',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.modeTextPrimary,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
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
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Create Stock Requisition'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              RequestStockScreen(),
              const StockRequestsScreen(branchId: ''),
            ],
          ),
        ),
      ),
    );
  }
}
