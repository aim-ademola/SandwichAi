import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/add_branch_stock_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_details_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/bulk_inventory_upload_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/processing_transfrer_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/procurement_req_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock-movement_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_control_reports_cubit/stock_control_reports_cubit.dart';
import 'package:sandwich_ai/src/features/stock_control/bloc/stock_summary_bloc/bloc.dart';
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

class StockProviders {
  static List<BlocProvider> providers = [
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
    BlocProvider<BulkInventoryUploadBloc>(
      create: (context) => BulkInventoryUploadBloc(
        repository: context.read<BulkInventoryUploadRepositoryInterface>(),
      ),
    ),
    BlocProvider<ProcessingTransferBloc>(
      create: (context) => ProcessingTransferBloc(
        repository: context.read<ProcessingTransferRepositoryInterface>(),
      ),
    ),
    BlocProvider<InventoryItemsBloc>(
      create: (context) => InventoryItemsBloc(
        repository: context.read<InventoryItemsRepository>(),
      ),
    ),
    BlocProvider<ProcurementRequestBloc>(
      create: (context) => ProcurementRequestBloc(
        repository: context.read<ProcurementRequestRepositoryInterface>(),
      ),
    ),
    BlocProvider<StockControlReportsCubit>(
      create: (context) => StockControlReportsCubit(
        stockCardRepository: context.read<StockCardRepositoryInterface>(),
        branchStockRepository: context
            .read<AddBranchStockRepositoryInterface>(),
        reorderRepository: context.read<ReorderRepositoryInterface>(),
      ),
    ),
  ];
}
