import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen_shift_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/kitchen/data/repo/kitchn_shift_repo.dart';
import 'package:sandwich_ai/src/features/kitchen/presentation/kitchen_history.dart';
import 'package:sandwich_ai/src/features/kitchen/presentation/kitchen_staff_shift.dart';

class KitchenShiftTabScreen extends StatefulWidget {
  const KitchenShiftTabScreen({super.key});

  @override
  State<KitchenShiftTabScreen> createState() => _KitchenShiftTabScreenState();
}

class _KitchenShiftTabScreenState extends State<KitchenShiftTabScreen>
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
          KitchenShiftBloc(repository: KitchenShiftRepository()),
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
              'Kitchen Shift Management',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Tab bar
              Container(
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
                    Tab(text: 'Schedule'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    KitchenShiftManagementScreen(),
                    KitchenShiftHistoryScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
