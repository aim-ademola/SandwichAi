import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_good_received_repo.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/create_good_recieved_proc.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/goods_recieved_history.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/good_received_bloc/bloc.dart';

class GoodsReceivedTabScreen extends StatefulWidget {
  const GoodsReceivedTabScreen({super.key});

  @override
  State<GoodsReceivedTabScreen> createState() => _GoodsReceivedTabScreenState();
}

class _GoodsReceivedTabScreenState extends State<GoodsReceivedTabScreen>
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
          GoodsReceivedBloc(repository: GoodsReceivedRepository()),
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
              'Goods Received',
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
                    Tab(text: 'Log Receipt'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              CreateGoodsReceivedScreen(),
              GoodsReceivedHistoryScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
