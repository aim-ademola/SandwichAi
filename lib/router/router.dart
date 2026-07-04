import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/router/notfound.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/globals/navbars/kitchen_nav.dart';
import 'package:sandwich_ai/src/core/globals/navbars/pos_navbar.dart';
import 'package:sandwich_ai/src/core/globals/navbars/processing_nav.dart';
import 'package:sandwich_ai/src/core/globals/navbars/procuremnt_navbar.dart';
import 'package:sandwich_ai/src/core/globals/navbars/stock_control_nav.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/login_repo.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/presentation/forgot_pwd.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/presentation/reset_pwd.dart';

import 'package:sandwich_ai/src/features/auth/login/presentation/employee_login.dart';
import 'package:sandwich_ai/src/features/auth/login_bloc/login_bloc.dart';
import 'package:sandwich_ai/src/features/kitchen/presentation/kitchen_order_details.dart';
import 'package:sandwich_ai/src/features/kitchen/presentation/kitchen_shift_tab.dart';
import 'package:sandwich_ai/src/features/pos/bloc/pos_order_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/presentation/compaints.dart';
import 'package:sandwich_ai/src/features/pos/presentation/customer_base.dart';
import 'package:sandwich_ai/src/features/pos/presentation/customer_details.dart';
import 'package:sandwich_ai/src/features/pos/presentation/my_task.dart';
import 'package:sandwich_ai/src/features/pos/presentation/order_session_entry.dart';
import 'package:sandwich_ai/src/features/pos/presentation/order_summary.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_dashboard.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_requisition.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_staff_screen.dart';
import 'package:sandwich_ai/src/features/pos/presentation/table_view.dart';
import 'package:sandwich_ai/src/features/processing/presentation/output_ver_tabs.dart';
import 'package:sandwich_ai/src/features/processing/presentation/processing_vaidate_stock_trf.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/order_list.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/processing_requsition.dart';
import 'package:sandwich_ai/src/features/processing/presentation/recipe_compliance_tabs.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/order_form.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/procurement_dash.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/procurement_request.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/procuremnt_purchase_req.dart';
import 'package:sandwich_ai/src/features/splash/splash.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => const NotFoundScreen(),

    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash-screen',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const AppSplashScreen(),
          );
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          return BlocProvider(
            key: UniqueKey(),
            create: (context) => LoginBloc(
              loginRepository: context.read<LoginRepositoryInterface>(),
            ),
            child: const EmployeeLoginScreen(),
          );
        },
      ),
      // GoRoute(
      //   path: '/',
      //   name: 'login',
      //   pageBuilder: (context, state) {
      //     return CupertinoPage(
      //       key: state.pageKey,
      //       child: const EmployeeLoginScreen(),
      //     );
      //   },
      // ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const ForgotPasswordScreen(),
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          if (extra == null ||
              !extra.containsKey('email') ||
              !extra.containsKey('organizationCode')) {
            // Redirect to login if invalid
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: kPrimary)),
            );
          }

          return ResetPasswordScreen(
            email: extra['email'] as String,
            organizationCode: extra['organizationCode'] as String,
          );
        },
      ),

      // ! ---------------------------- PROCESSING --------------------------------------------
      GoRoute(
        path: '/Processing-nav',
        name: 'Processing-nav',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const ProcessingControlMainScreen(),
          );
        },
      ),
      GoRoute(
        path: '/processing-req',
        name: 'processing-req',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const ValidateStockTransferToProcessingcreen(),
          );
        },
      ),
      GoRoute(
        path: '/output-ver-proc',
        name: 'output-ver-proc',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: OutputVerificationTabScreen(),
          );
        },
      ),
      GoRoute(
        path: '/recipe-compl',
        name: 'recipe-compl',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const RecipeComplianceTabScreen(),
          );
        },
      ),
      // ! ---------------------------- POS --------------------------------------------
      GoRoute(
        path: '/Pos-nav',
        name: 'Pos-nav',
        pageBuilder: (context, state) {
          final index = state.extra as int?;
          return CupertinoPage(
            key: state.pageKey,
            child: POSMainScreen(initialIndex: index),
          );
        },
      ),

      GoRoute(
        path: '/customer-dtls',
        name: 'customer-dtls',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const CreateEditCustomerScreen(),
          );
        },
      ),
      GoRoute(
        path: '/customer-list',
        name: 'customer-list',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const CustomersListScreen(),
          );
        },
      ),

      GoRoute(
        path: '/pos-dash',
        name: 'pos-dash',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const PosDashboardScreen(),
          );
        },
      ),
      // GoRoute(
      //   path: '/payment-method',
      //   name: 'payment-method',
      //   pageBuilder: (context, state) {
      //     return CupertinoPage(
      //       key: state.pageKey,
      //       child: const PaymentMethodScreen(),
      //     );
      //   },
      // ),
      GoRoute(
        path: '/pos-request',
        name: 'pos-request',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const POSRequisitionScreen(),
          );
        },
      ),
      GoRoute(
        path: '/my-task',
        name: 'my-task',
        pageBuilder: (context, state) {
          return CupertinoPage(key: state.pageKey, child: const MyTaskScreen());
        },
      ),

      GoRoute(
        path: '/order-screen',
        name: 'order-screen',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const OrderSessionEntryScreen(),
          );
        },
      ),
      GoRoute(
        path: '/order-summary',
        name: 'order-summary',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          return BlocProvider<PosOrderBloc>.value(
            value: extra['posOrderBloc'] as PosOrderBloc,
            child: OrderSummaryScreen(
              orderItems: extra['orderItems'] as Map<ApiMenuItem, int>,
              specialRequests: extra['specialRequests'] as Map<String, String>,
              orderType: extra['orderType'] as String,
              tableNumber: extra['tableNumber'] as String?,
              customerName: extra['customerName'] as String?,
              customerPhone: extra['customerPhone'] as String?,
              discount: (extra['discount'] as num?)?.toDouble() ?? 0.0,
              specialInstructions: extra['specialInstructions'] as String?,
            ),
          );
        },
      ),

      GoRoute(
        path: '/pos-staff-screen',
        name: 'pos-staff-screen',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const PosStaffScreen(),
          );
        },
      ),
      GoRoute(
        path: '/complaints',
        name: 'complaints',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const ComplaintsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/table-mgt',
        name: 'table-mgt',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const TableManagementScreen(),
          );
        },
      ),

      // ! ---------------------------- Procurement --------------------------------------------
      GoRoute(
        path: '/Procurement-nav',
        name: 'procuremnt-nav',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const ProcurementMainScreen(),
          );
        },
      ),
      GoRoute(
        path: '/procuremnt-dash',
        name: 'procuremnt-dash',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const ProcurementDashboardScreen(),
          );
        },
      ),
      GoRoute(
        path: '/order-form',
        name: 'order-form',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const OrderFormScreen(),
          );
        },
      ),
      GoRoute(
        path: '/order-list',
        name: 'order-list',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const OrdersListScreen(),
          );
        },
      ),
      GoRoute(
        path: '/procurement_orders',
        name: 'procurement_orders',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const ProcurementOrdersScreen(),
          );
        },
      ),
      GoRoute(
        path: '/procurement_requests',
        name: 'procurement_requests',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const ProcurementRequestsScreen(),
          );
        },
      ),

      // ! ---------------------------- Stock Control --------------------------------------------
      GoRoute(
        path: '/Stock-control-nav',
        name: 'stock-nav',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const StockControlMainScreen(),
          );
        },
      ),
      GoRoute(
        path: '/stock-req',
        name: 'stock-req',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const StockTransferToProcessingOrKItchenScreen(),
          );
        },
      ),

      // ! ---------------------------- Kitchen --------------------------------------------
      GoRoute(
        path: '/Kitchen-nav',
        name: 'kitchen-nav',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const KitchenMainScreen(),
          );
        },
      ),

      GoRoute(
        path: '/kitchen-shift',
        name: 'kitchen-shift',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: KitchenShiftTabScreen(),
          );
        },
      ),
      GoRoute(
        path: '/kitchen-order-dtls/:orderNumber',
        name: 'kitchen-order-details',
        pageBuilder: (context, state) {
          final orderNumber = state.pathParameters['orderNumber'];
          if (orderNumber == null) {
            return const CupertinoPage(
              child: Scaffold(body: Center(child: Text("Order not found"))),
            );
          }

          return CupertinoPage(
            key: state.pageKey,
            child: KitchenOrderDetailScreen(
              orderNumber: orderNumber,
            ), // ✅ Pass orderNumber
          );
        },
      ),
    ],
  );

  static GoRouter get router => _router;
}
