import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/order_list_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_order_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/purchase_order_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/supplier_repo.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/order_list-bloc/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/porchase_order_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_order_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/bloc.dart';

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
  ];
}
