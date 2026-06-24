// presentation/product_intake_tab_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/bloc/employee_bloc/employee_bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/product_intake_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/employee_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/product_intake_repo.dart';
import 'package:sandwich_ai/src/features/processing/presentation/create_product_intake.dart';
import 'package:sandwich_ai/src/features/processing/presentation/product_intake_history.dart';

import 'package:sandwich_ai/src/features/stock_control/data/repo/inventory_items_repo.dart';

class ProductIntakeTabScreen extends StatefulWidget {
  const ProductIntakeTabScreen({super.key});

  @override
  State<ProductIntakeTabScreen> createState() => _ProductIntakeTabScreenState();
}

class _ProductIntakeTabScreenState extends State<ProductIntakeTabScreen>
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              ProductIntakeBloc(repository: ProductIntakeRepository()),
        ),
        BlocProvider(
          create: (context) =>
              InventoryItemsBloc(repository: InventoryItemsRepository()),
        ),
        BlocProvider(
          create: (context) => EmployeeBloc(repository: EmployeeRepository()),
        ),
      ],
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
              'Product Intake',
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
                    Tab(text: 'Create Intake'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              CreateProductIntakeScreen(),
              ProductIntakeHistoryScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
