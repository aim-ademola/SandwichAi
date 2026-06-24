import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/presentation/compliance_history.dart';
import 'package:sandwich_ai/src/features/processing/presentation/recipe_compliance.dart';

class RecipeComplianceTabScreen extends StatefulWidget {
  const RecipeComplianceTabScreen({super.key});

  @override
  State<RecipeComplianceTabScreen> createState() =>
      _RecipeComplianceTabScreenState();
}

class _RecipeComplianceTabScreenState extends State<RecipeComplianceTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
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
            'Recipe Compliance',
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
                  Tab(text: 'Resolve Recipe Compliance'),
                  Tab(text: 'Compliance History'),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  RecipeComplianceScreen(),
                  RecipeComplianceHistoryScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
