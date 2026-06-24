import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen-dash_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/kitchen/data/repo/kitchen_dash_repo.dart';
import 'package:sandwich_ai/src/features/pos/bloc/order_status_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/order_statua_repo.dart';

class KitchenProviders {
  static List<BlocProvider> providers = [
    BlocProvider<KitchenOrdersBloc>(
      create: (context) => KitchenOrdersBloc(
        repository: context.read<KitchenOrdersRepositoryInterface>(),
      ),
    ),
    BlocProvider<KitchenDashboardBloc>(
      create: (context) => KitchenDashboardBloc(
        repository: context.read<KitchenDashboardRepositoryInterface>(),
      ),
    ),
  ];
}
