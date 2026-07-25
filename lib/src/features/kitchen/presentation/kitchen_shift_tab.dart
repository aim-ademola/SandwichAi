import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/data/repo/employee_lookup_repo.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
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
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
        appBar: AppBar(
          backgroundColor: context.modeSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Center(
              child: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Kitchen Shift Management',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Tab bar
            Container(
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
                  Tab(text: 'Schedule'),
                  Tab(text: 'History'),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  BlocProvider(
                    create: (context) => KitchenShiftBloc(
                      repository: KitchenShiftRepository(
                        employeeLookupRepository: context
                            .read<EmployeeLookupRepositoryInterface>(),
                      ),
                    ),
                    child: const KitchenShiftManagementScreen(),
                  ),
                  BlocProvider(
                    create: (context) => KitchenShiftBloc(
                      repository: KitchenShiftRepository(
                        employeeLookupRepository: context
                            .read<EmployeeLookupRepositoryInterface>(),
                      ),
                    ),
                    child: const KitchenShiftHistoryScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
