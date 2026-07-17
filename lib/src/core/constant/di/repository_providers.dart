import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/data/repo/employee_lookup_repo.dart';
import 'package:sandwich_ai/src/core/globals/chat/data/repo/chat_repo.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/chnage_pwd_repo.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/forgot_pwd_repo.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/login_repo.dart';
import 'package:sandwich_ai/src/features/dashboard/data/repo/dashboard_contract_repo.dart';
import 'package:sandwich_ai/src/features/kitchen/data/repo/kitchen_dash_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/add_menu_repo.dart'
    as addtomenurepo;
import 'package:sandwich_ai/src/features/pos/data/repository/api_menu_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/customer_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/customer_service_feedback_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/order_statua_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/payment_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_dashboradd_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/pos_order_repo.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/tax-config_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/fetch_recipe_coml.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/processing_dashboard_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/processsing_task_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/recipe_compliance_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/recipe_forecast_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/req_stock.dart'
    as req;
import 'package:sandwich_ai/src/features/processing/data/repo/stock_request_repo.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/wasage_analysis_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/order_list_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_performance_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/procurement_order_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/purchase_order_repo.dart';
import 'package:sandwich_ai/src/features/procurement/data/repository/supplier_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/add_branch_stock.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/branch_details_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/branch_stock_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/bulk_inventory_upload_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/inventory_items_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/processing_transfer_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/procurement_req_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/reorder_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/stock_card_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/stock_movement.dart';
import 'package:sandwich_ai/src/features/stock_control/data/repo/stock_summary_repo.dart';

class RepositoryProviders {
  static List<RepositoryProvider> providers = [
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
    RepositoryProvider<BulkInventoryUploadRepositoryInterface>(
      create: (context) => BulkInventoryUploadRepository(),
    ),
    RepositoryProvider<DashboardContractRepositoryInterface>(
      create: (context) => DashboardContractRepository(),
    ),
    RepositoryProvider<EmployeeLookupRepositoryInterface>(
      create: (context) => EmployeeLookupRepository(),
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
    RepositoryProvider<StockCardRepositoryInterface>(
      create: (context) => StockCardRepository(),
    ),
    RepositoryProvider<ReorderRepositoryInterface>(
      create: (context) => ReorderRepository(),
    ),
    RepositoryProvider<OrderRepositoryInterface>(
      create: (context) => OrderRepository(),
    ),
    RepositoryProvider<PurchaseOrdersRepositoryInterface>(
      create: (context) => PurchaseOrdersRepository(),
    ),
    RepositoryProvider<ProcurementPerformanceRepositoryInterface>(
      create: (context) => ProcurementPerformanceRepository(),
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
    RepositoryProvider<CustomerServiceFeedbackRepositoryInterface>(
      create: (context) => CustomerServiceFeedbackRepository(),
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
    RepositoryProvider<TaxConfigRepositoryInterface>(
      create: (context) => TaxConfigRepository(),
    ),
  ];
}
