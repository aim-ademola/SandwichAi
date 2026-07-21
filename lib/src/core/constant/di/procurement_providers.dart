import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/order_list_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_performance_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_order_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/purchase_order_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/supplier_repo.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/goods_received_advanced_cubit/goods_received_advanced_cubit.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/order_list-bloc/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/porchase_order_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_performance_cubit/procurement_performance_cubit.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_order_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/purchase_order_actions_cubit/purchase_order_actions_cubit.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_good_received_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/reorder_repo.dart';

class ProcurementProviders {
  static List<BlocProvider> providers = [
    BlocProvider<ProcurementBloc>(
      create: (context) => ProcurementBloc(
        repository: context.read<ProcurementRepositoryInterface>(),
      ),
    ),
    BlocProvider<SupplierBloc>(
      create: (context) =>
          SupplierBloc(repository: context.read<SupplierRepositoryInterface>()),
    ),
    BlocProvider<OrderBloc>(
      create: (context) =>
          OrderBloc(repository: context.read<OrderRepositoryInterface>()),
    ),
    BlocProvider<OrdersListBloc>(
      create: (context) => OrdersListBloc(
        repository: context.read<PurchaseOrdersRepositoryInterface>(),
      ),
    ),
    BlocProvider<PurchaseOrderActionsCubit>(
      create: (context) => PurchaseOrderActionsCubit(
        orderRepository: context.read<OrderRepositoryInterface>(),
        ordersRepository: context.read<PurchaseOrdersRepositoryInterface>(),
      ),
    ),
    BlocProvider<ProcurementPerformanceCubit>(
      create: (context) => ProcurementPerformanceCubit(
        repository: context.read<ProcurementPerformanceRepositoryInterface>(),
      ),
    ),
    BlocProvider<GoodsReceivedAdvancedCubit>(
      create: (context) => GoodsReceivedAdvancedCubit(
        goodsReceivedRepository: context
            .read<GoodsReceivedRepositoryInterface>(),
        reorderRepository: context.read<ReorderRepositoryInterface>(),
      ),
    ),
  ];
}
