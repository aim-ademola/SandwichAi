import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/globals/chat/chatroom_bloc/bloc.dart';
import 'package:sandwich_ai/src/core/globals/chat/data/repo/chat_repo.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/chnage_pwd_repo.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/forgot_pwd_repo.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/login_repo.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/bloc/bloc.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/cnage_pwd_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/reset_pwd_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/auth/login_bloc/login_bloc.dart';
import 'package:sandwich_ai/src/features/kitchen/blocs/kitchen-dash_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/kitchen/data/repo/kitchen_dash_repo.dart';
import 'package:sandwich_ai/src/features/pos/bloc/api_menu_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_cubit.dart';
import 'package:sandwich_ai/src/features/pos/bloc/order_status_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/payment_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_dashboard_state_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/api_menu_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/customer_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/order_statua_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/payment_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_dashboradd_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_order_repo.dart';
import 'package:sandwich_ai/src/features/processing/bloc/get_recipe_compl.dart/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_dash_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_task_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_compliance_bloc.dart/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_forecast_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/stock_request_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/wastage_analysis_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/data/model/stock_reuest_model.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/fetch_recipe_coml.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/processing_dashboard_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/processsing_task_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/recipe_compliance_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/recipe_forecast_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/stock_request_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/wasage_analysis_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/procurement_order_model.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_model.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/order_list_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_order_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/purchase_order_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/supplier_repo.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/order_list-bloc/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/porchase_order_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/procurement_order_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/procurement/procurement_blocs/supplier_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/add_branch_stock_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_details_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/processing_transfrer_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/procurement_req_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock-movement_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_summary_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/add_menu_repo.dart'
    as addtomenurepo;
import 'package:sandwich_ai/src/features/stock_control/data/repo/add_branch_stock.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/branch_details_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/branch_stock_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/inventory_items_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/processing_transfer_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/procurement_req_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/stock_movement.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/stock_summary_repo.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/bloc.dart'
    as addtomenu;

import 'package:sandwich_ai/src/features/processing/data/repo/req_stock.dart'
    as req;
import 'package:sandwich_ai/src/features/processing/bloc/req_stock/req_stock_bloc.dart'
    as breq;

class AppBlocProviders extends StatelessWidget {
  final Widget child;

  AppBlocProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // Repositories
        RepositoryProvider<LoginRepositoryInterface>(
          create: (context) => LoginRepository(),
        ),
        RepositoryProvider<BranchStockRepositoryInterface>(
          create: (context) => BranchStockRepository(),
        ),
        RepositoryProvider<BranchStockSummaryRepositoryInterface>(
          create: (context) => BranchStockSummaryRepository(),
        ),
        RepositoryProvider<AddBranchStockRepositoryInterface>(
          create: (context) => AddBranchStockRepository(),
        ),
        RepositoryProvider<StockMovementRepositoryInterface>(
          create: (context) => StockMovementRepository(),
        ),
        RepositoryProvider<BranchStockDetailsRepositoryInterface>(
          create: (context) => BranchStockDetailsRepository(),
        ),
        RepositoryProvider<ProcessingDashboardRepositoryInterface>(
          create: (context) => ProcessingDashboardRepository(),
        ),
        RepositoryProvider<RecipeComplianceRepositoryInterface>(
          create: (context) => RecipeComplianceRepository(),
        ),
        RepositoryProvider<RecipeComplianceHistoryRepositoryInterface>(
          create: (context) => RecipeComplianceHistoryRepository(),
        ),
        RepositoryProvider<ProcessingTransferRepositoryInterface>(
          create: (context) => ProcessingTransferRepository(),
        ),
        RepositoryProvider<MenuItemsRepositoryInterface>(
          create: (context) => MenuItemsRepository(),
        ),
        RepositoryProvider<addtomenurepo.MenuItemsRepositoryInterface>(
          create: (context) => addtomenurepo.MenuItemsRepository(),
        ),
        RepositoryProvider<KitchenOrdersRepositoryInterface>(
          create: (context) => KitchenOrdersRepository(),
        ),
        RepositoryProvider<RecipeForecastRepositoryInterface>(
          create: (context) => RecipeForecastRepository(),
        ),
        RepositoryProvider<WastageAnalysisRepositoryInterface>(
          create: (context) => WastageAnalysisRepository(),
        ),
        RepositoryProvider<InventoryItemsRepository>(
          create: (context) => InventoryItemsRepository(),
        ),
        RepositoryProvider<ProcurementRepositoryInterface>(
          create: (context) => ProcurementRepository(),
        ),
        RepositoryProvider<ProcessingTaskRepositoryInterface>(
          create: (context) => ProcessingTaskRepository(),
        ),
        RepositoryProvider<StockRequestRepositoryInterface>(
          create: (context) => StockRequestRepository(),
        ),
        RepositoryProvider<SupplierRepositoryInterface>(
          create: (context) => SupplierRepository(),
        ),
        RepositoryProvider<ProcurementRequestRepositoryInterface>(
          create: (context) => ProcurementRequestRepository(),
        ),
        RepositoryProvider<OrderRepositoryInterface>(
          create: (context) => OrderRepository(),
        ),
        RepositoryProvider<PurchaseOrdersRepositoryInterface>(
          create: (context) => PurchaseOrdersRepository(),
        ),
        RepositoryProvider<KitchenDashboardRepositoryInterface>(
          create: (context) => KitchenDashboardRepository(),
        ),
        RepositoryProvider<PosOrderRepositoryInterface>(
          create: (context) => PosOrderRepository(),
        ),
        RepositoryProvider<DashboardRepositoryInterface>(
          create: (context) => DashboardRepository(),
        ),
        RepositoryProvider<CustomerRepositoryInterface>(
          create: (context) => CustomerRepository(),
        ),
        RepositoryProvider<req.StockRequestRepositoryInterface>(
          create: (context) => req.StockRequestRepository(),
        ),
        RepositoryProvider<ForgotPasswordRepositoryInterface>(
          create: (context) => ForgotPasswordRepository(),
        ),
        RepositoryProvider<PaymentRepositoryInterface>(
          create: (context) => PaymentRepository(),
        ),
        RepositoryProvider<ChangePasswordRepositoryInterface>(
          create: (context) => ChangePasswordRepository(),
        ),
        RepositoryProvider<ChatRepositoryInterface>(
          create: (context) => ChatRepository(),
        ),
      ],

      child: MultiBlocProvider(
        providers: [
          // Auth & User-related BLoCs
          BlocProvider<LoginBloc>(
            create: (context) => LoginBloc(
              loginRepository: context.read<LoginRepositoryInterface>(),
            ),
          ),
          BlocProvider<BranchStockBloc>(
            create: (context) => BranchStockBloc(
              repository: context.read<BranchStockRepositoryInterface>(),
            ),
          ),
          BlocProvider<BranchStockSummaryBloc>(
            create: (context) => BranchStockSummaryBloc(
              repository: context.read<BranchStockSummaryRepositoryInterface>(),
            ),
          ),
          BlocProvider<AddBranchStockBloc>(
            create: (context) => AddBranchStockBloc(
              repository: context.read<AddBranchStockRepositoryInterface>(),
            ),
          ),
          BlocProvider<StockMovementBloc>(
            create: (context) => StockMovementBloc(
              repository: context.read<StockMovementRepositoryInterface>(),
            ),
          ),
          BlocProvider<BranchStockDetailsBloc>(
            create: (context) => BranchStockDetailsBloc(
              repository: context.read<BranchStockDetailsRepositoryInterface>(),
            ),
          ),
          BlocProvider<ProcessingDashboardBloc>(
            create: (context) => ProcessingDashboardBloc(
              repository: context
                  .read<ProcessingDashboardRepositoryInterface>(),
            ),
          ),
          BlocProvider<RecipeComplianceBloc>(
            create: (context) => RecipeComplianceBloc(
              repository: context.read<RecipeComplianceRepositoryInterface>(),
            ),
          ),
          BlocProvider<RecipeComplianceHistoryBloc>(
            create: (context) => RecipeComplianceHistoryBloc(
              repository: context
                  .read<RecipeComplianceHistoryRepositoryInterface>(),
            ),
          ),
          BlocProvider<ProcessingTransferBloc>(
            create: (context) => ProcessingTransferBloc(
              repository: context.read<ProcessingTransferRepositoryInterface>(),
            ),
          ),
          BlocProvider<MenuItemsBloc>(
            create: (context) => MenuItemsBloc(
              repository: context.read<MenuItemsRepositoryInterface>(),
            ),
          ),
          BlocProvider<addtomenu.MenuItemsBloc>(
            create: (context) => addtomenu.MenuItemsBloc(
              repository: context
                  .read<addtomenurepo.MenuItemsRepositoryInterface>(),
            ),
          ),
          BlocProvider<KitchenOrdersBloc>(
            create: (context) => KitchenOrdersBloc(
              repository: context.read<KitchenOrdersRepositoryInterface>(),
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
          BlocProvider<InventoryItemsBloc>(
            create: (context) => InventoryItemsBloc(
              repository: context.read<InventoryItemsRepository>(),
            ),
          ),
          BlocProvider<ProcurementBloc>(
            create: (context) => ProcurementBloc(
              repository: context.read<ProcurementRepositoryInterface>(),
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
          BlocProvider<SupplierBloc>(
            create: (context) => SupplierBloc(
              repository: context.read<SupplierRepositoryInterface>(),
            ),
          ),
          BlocProvider<ProcurementRequestBloc>(
            create: (context) => ProcurementRequestBloc(
              repository: context.read<ProcurementRequestRepositoryInterface>(),
            ),
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
          BlocProvider<KitchenDashboardBloc>(
            create: (context) => KitchenDashboardBloc(
              repository: context.read<KitchenDashboardRepositoryInterface>(),
            ),
          ),
          BlocProvider<PosOrderBloc>(
            create: (context) => PosOrderBloc(
              repository: context.read<PosOrderRepositoryInterface>(),
            ),
          ),
          BlocProvider<DashboardBloc>(
            create: (context) => DashboardBloc(
              repository: context.read<DashboardRepositoryInterface>(),
            ),
          ),
          BlocProvider<CustomerBloc>(
            create: (context) => CustomerBloc(
              repository: context.read<CustomerRepositoryInterface>(),
            ),
          ),
          BlocProvider<breq.StockRequestBloc>(
            create: (context) => breq.StockRequestBloc(
              repository: context.read<req.StockRequestRepositoryInterface>(),
            ),
          ),
          BlocProvider<ForgotPasswordBloc>(
            create: (context) => ForgotPasswordBloc(
              repository: context.read<ForgotPasswordRepositoryInterface>(),
            ),
          ),
          BlocProvider<ResetPasswordBloc>(
            create: (context) => ResetPasswordBloc(
              repository: context.read<ForgotPasswordRepositoryInterface>(),
            ),
          ),
          BlocProvider<OrderSessionCubit>(
            create: (context) => OrderSessionCubit(),
          ),
          BlocProvider<PaymentBloc>(
            create: (context) => PaymentBloc(
              repository: context.read<PaymentRepositoryInterface>(),
            ),
          ),
          BlocProvider<ChangePasswordBloc>(
            create: (context) => ChangePasswordBloc(
              repository: context.read<ChangePasswordRepositoryInterface>(),
            ),
          ),
          BlocProvider<ChatBloc>(
            create: (context) =>
                ChatBloc(repository: context.read<ChatRepositoryInterface>()),
          ),
        ],
        child: child,
      ),
    );
  }
}
