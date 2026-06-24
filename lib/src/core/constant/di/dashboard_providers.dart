import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/globals/chat/chatroom_bloc/bloc.dart';
import 'package:sandwich_ai/src/core/globals/chat/data/repo/chat_repo.dart';
import 'package:sandwich_ai/src/features/dashboard/bloc/dashboard_contract_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/dashboard/data/repo/dashboard_contract_repo.dart';

class DashboardProviders {
  static List<BlocProvider> providers = [
    BlocProvider<DashboardContractBloc>(
      create: (context) => DashboardContractBloc(
        repository: context.read<DashboardContractRepositoryInterface>(),
      ),
    ),
    BlocProvider<ChatBloc>(
      create: (context) =>
          ChatBloc(repository: context.read<ChatRepositoryInterface>()),
    ),
  ];
}
