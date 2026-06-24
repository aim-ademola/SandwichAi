import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/get_recipe_compl.dart/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_dash_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_task_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_compliance_bloc.dart/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_forecast_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/req_stock/req_stock_bloc.dart'
    as breq;
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/wastage_analysis_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/fetch_recipe_coml.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/processing_dashboard_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/processsing_task_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/recipe_compliance_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/recipe_forecast_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/req_stock.dart'
    as req;
import 'package:sandwich_ai/src/features/processing/data/repo/stock_request_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/wasage_analysis_repo.dart';

class ProcessingProviders {
  static List<BlocProvider> providers = [
    BlocProvider<ProcessingDashboardBloc>(
      create: (context) => ProcessingDashboardBloc(
        repository: context.read<ProcessingDashboardRepositoryInterface>(),
      ),
    ),
    BlocProvider<RecipeComplianceBloc>(
      create: (context) => RecipeComplianceBloc(
        repository: context.read<RecipeComplianceRepositoryInterface>(),
      ),
    ),
    BlocProvider<RecipeComplianceHistoryBloc>(
      create: (context) => RecipeComplianceHistoryBloc(
        repository: context.read<RecipeComplianceHistoryRepositoryInterface>(),
      ),
    ),
    BlocProvider<RecipeForecastBloc>(
      create: (context) => RecipeForecastBloc(
        repository: context.read<RecipeForecastRepositoryInterface>(),
      ),
    ),
    BlocProvider<WastageAnalysisBloc>(
      create: (context) => WastageAnalysisBloc(
        repository: context.read<WastageAnalysisRepositoryInterface>(),
      ),
    ),
    BlocProvider<ProcessingTaskBloc>(
      create: (context) => ProcessingTaskBloc(
        repository: context.read<ProcessingTaskRepositoryInterface>(),
      ),
    ),
    BlocProvider<StockRequestBloc>(
      create: (context) => StockRequestBloc(
        repository: context.read<StockRequestRepositoryInterface>(),
      ),
    ),
    BlocProvider<breq.StockRequestBloc>(
      create: (context) => breq.StockRequestBloc(
        repository: context.read<req.StockRequestRepositoryInterface>(),
      ),
    ),
  ];
}
