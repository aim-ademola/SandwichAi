import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_task_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/processsing_task_repo.dart';
import 'package:sandwich_ai/src/features/processing/presentation/create_processing_task.dart';
import 'package:sandwich_ai/src/features/processing/presentation/get_processing_tasks.dart';

class ProcessingTaskTabScreen extends StatefulWidget {
  const ProcessingTaskTabScreen({super.key});

  @override
  State<ProcessingTaskTabScreen> createState() =>
      _ProcessingTaskTabScreenState();
}

class _ProcessingTaskTabScreenState extends State<ProcessingTaskTabScreen>
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
          ProcessingTaskBloc(repository: ProcessingTaskRepository()),
      child: DefaultTextStyle.merge(
        style: WorkSansAppTextStyles.medium,
        child: Scaffold(
          backgroundColor: context.modeBackground,
          appBar: AppBar(
            backgroundColor: context.modeSurface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: AppIcon(Icons.arrow_back, color: context.modeTextPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Processing Tasks',
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
                    Tab(text: 'Create Task'),
                    Tab(text: 'Task History'),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              CreateProcessingTaskScreen(),
              ProcessingTaskHistoryScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
