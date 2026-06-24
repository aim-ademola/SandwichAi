import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/di/auth_providers.dart';
import 'package:sandwich_ai/src/core/constant/di/dashboard_providers.dart';
import 'package:sandwich_ai/src/core/constant/di/kitchen_providers.dart';
import 'package:sandwich_ai/src/core/constant/di/pos_providers.dart';
import 'package:sandwich_ai/src/core/constant/di/processing_providers.dart';
import 'package:sandwich_ai/src/core/constant/di/procurement_providers.dart';
import 'package:sandwich_ai/src/core/constant/di/repository_providers.dart';
import 'package:sandwich_ai/src/core/constant/di/stock_providers.dart';
import 'package:sandwich_ai/src/core/constant/di/theme_providers.dart';

class AppBlocProviders extends StatelessWidget {
  final Widget child;

  const AppBlocProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [...RepositoryProviders.providers],
      child: MultiBlocProvider(
        providers: [
          ...ThemeProviders.providers,
          ...AuthProviders.providers,
          ...DashboardProviders.providers,
          ...StockProviders.providers,
          ...ProcurementProviders.providers,
          ...ProcessingProviders.providers,
          ...PosProviders.providers,
          ...KitchenProviders.providers,
        ],
        child: child,
      ),
    );
  }
}
