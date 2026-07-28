import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_good_received_repo.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/create_good_recieved_proc.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/goods_recieved_history.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/goods_received_overview.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/goods_received_advanced_cubit/goods_received_advanced_cubit.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/good_received_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/reorder_repo.dart';

class GoodsReceivedTabScreen extends StatefulWidget {
  final int initialIndex;

  const GoodsReceivedTabScreen({super.key, this.initialIndex = 0});

  @override
  State<GoodsReceivedTabScreen> createState() => _GoodsReceivedTabScreenState();
}

class _GoodsReceivedTabScreenState extends State<GoodsReceivedTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      initialIndex: widget.initialIndex.clamp(0, 2),
      vsync: this,
    );
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
          create: (context) => GoodsReceivedAdvancedCubit(
            goodsReceivedRepository: context
                .read<GoodsReceivedRepositoryInterface>(),
            reorderRepository: context.read<ReorderRepositoryInterface>(),
          ),
        ),
      ],
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
              'Goods Received',
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
                    Tab(text: 'Overview'),
                    Tab(text: 'Log Receipt'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              const GoodsReceivedOverviewScreen(),
              BlocProvider(
                create: (context) => GoodsReceivedBloc(
                  repository: context.read<GoodsReceivedRepositoryInterface>(),
                ),
                child: const CreateGoodsReceivedScreen(),
              ),
              BlocProvider(
                create: (context) => GoodsReceivedBloc(
                  repository: context.read<GoodsReceivedRepositoryInterface>(),
                ),
                child: const GoodsReceivedHistoryScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
