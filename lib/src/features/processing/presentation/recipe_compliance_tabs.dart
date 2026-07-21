import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
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
            'Recipe Compliance',
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
