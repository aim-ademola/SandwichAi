import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/wastage_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/wastage_log_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/create_waste_log.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/wastage_log_fetch.dart';

class WasteLogsTabScreen extends StatefulWidget {
  const WasteLogsTabScreen({super.key});

  @override
  State<WasteLogsTabScreen> createState() => _WasteLogsTabScreenState();
}

class _WasteLogsTabScreenState extends State<WasteLogsTabScreen>
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
      create: (context) => WasteLogsBloc(repository: WasteLogsRepository()),
      child: DefaultTextStyle.merge(
        style: WorkSansAppTextStyles.medium,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F6F6),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Waste Logs',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: kPrimary,
                  unselectedLabelColor: kprimaryTextColor2,
                  indicatorColor: kPrimary,
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
                    Tab(text: 'Log Waste'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [CreateWasteLogScreen(), WasteLogsHistoryScreen()],
          ),
        ),
      ),
    );
  }
}
