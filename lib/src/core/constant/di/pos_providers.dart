import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/bloc.dart'
    as addtomenu;
import 'package:sandwich_ai/src/features/pos/bloc/api_menu_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_cubit.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_dashboard_state_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/tax-config-bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/add_menu_repo.dart'
    as addtomenurepo;
import 'package:sandwich_ai/src/features/pos/data/repository/api_menu_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/customer_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/payment_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_dashboradd_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_order_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/tax-config_repo.dart';

class PosProviders {
  static List<BlocProvider> providers = [
    BlocProvider<MenuItemsBloc>(
      create: (context) => MenuItemsBloc(
        repository: context.read<MenuItemsRepositoryInterface>(),
      ),
    ),
    BlocProvider<addtomenu.MenuItemsBloc>(
      create: (context) => addtomenu.MenuItemsBloc(
        repository: context.read<addtomenurepo.MenuItemsRepositoryInterface>(),
      ),
    ),
    BlocProvider<PosOrderBloc>(
      create: (context) =>
          PosOrderBloc(repository: context.read<PosOrderRepositoryInterface>()),
    ),
    BlocProvider<DashboardBloc>(
      create: (context) => DashboardBloc(
        repository: context.read<DashboardRepositoryInterface>(),
      ),
    ),
    BlocProvider<CustomerBloc>(
      create: (context) =>
          CustomerBloc(repository: context.read<CustomerRepositoryInterface>()),
    ),
    BlocProvider<OrderSessionCubit>(create: (context) => OrderSessionCubit()),
    BlocProvider<PaymentBloc>(
      create: (context) =>
          PaymentBloc(repository: context.read<PaymentRepositoryInterface>()),
    ),
    BlocProvider<TaxConfigBloc>(
      create: (context) => TaxConfigBloc(
        repository: context.read<TaxConfigRepositoryInterface>(),
      ),
    ),
  ];
}
