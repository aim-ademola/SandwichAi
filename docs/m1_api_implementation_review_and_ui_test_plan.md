# M1 Mobile API Implementation Review And UI Test Plan

Source document: `C:\Users\Aim\Downloads\Mobile App Api Implementation M1 Doc.pdf`  
Reviewed repo: `D:\Project\SandwichAi`  
Review date: 2026-07-25

## Executive Summary

The M1 work is mostly implemented for Stock Control and Procurement. The app has typed models, repositories, blocs/cubits, and UI screens for most endpoints in the PDF.

Main result:

- Stock Control: mostly implemented, with one major endpoint mismatch in expiry tracking.
- Procurement dashboard: implemented through the shared dashboard contract endpoint.
- Goods Received: implemented, including overview, create, history, details, QC, PO prefill/status, PO receipts, and mark complete.
- Purchase Orders: implemented for create/list/update/delete/approval/dispatch/pending/overdue/timeline/bulk-create.
- Supplier Performance: implemented on procurement dashboard.
- Employees by Department: implemented as a shared repository, but each department screen should still be tested where it uses employee pickers.

Important risks before signing off:

- The original PDF listed expiry routes under `/stock-cards/...`, but live staging docs now show `/expiry/expiry-tracking/...`; current mobile code matches the live staging docs.
- Stock lock action is blocked in staging by backend authorization: `PATCH /branch-stock/{id}/lock` returns `403 Forbidden resource` for the tested user.
- `dart analyze` currently exits with 33 issues, including an unsupported `analysis_options.yaml` option.
- `flutter test` currently fails because the widget test builds the app before Firebase is initialized/mocked.
- Some procurement and goods-received screens instantiate repositories directly instead of using the global providers, which makes test mocking harder.

## Review Findings

### 1. Expiry Tracking Routes Were Changed After The PDF

Severity: Informational

Original PDF listed:

- `GET /stock-cards/expiry-report`
- `GET /stock-cards/analytics/expiry-summary`
- `GET /stock-cards/{branchId}/expiry-report`
- `GET /stock-cards/{branchId}/{itemId}/batches`
- `PATCH /stock-cards/{branchId}/{itemId}/batches/{batchId}`

Live staging docs now list:

- `GET /expiry/expiry-tracking`
- `GET /expiry/expiry-tracking/analytics/expiry-summary`
- `GET /expiry/expiry-tracking/{branchId}/expiry-report`
- `GET /expiry/expiry-tracking/{branchId}/{itemId}/batches`
- `PATCH /expiry/expiry-tracking/{branchId}/{itemId}/batches/{batchId}`

Current mobile implementation matches the live staging docs:

- `lib/src/features/stock_control/data/repo/stock_card_repo.dart:35` calls `expiry/expiry-tracking`
- `lib/src/features/stock_control/data/repo/stock_card_repo.dart:41` calls `expiry/expiry-tracking/analytics/expiry-summary`
- `lib/src/features/stock_control/data/repo/stock_card_repo.dart:56` calls `expiry/expiry-tracking/$branchId/expiry-report`
- `lib/src/features/stock_control/data/repo/stock_card_repo.dart:71` calls `expiry/expiry-tracking/$branchId/$itemId/batches`
- `lib/src/features/stock_control/data/repo/stock_card_repo.dart:104` calls `expiry/expiry-tracking/$branchId/$itemId/batches/$batchId`

Expected action: use the live staging docs as source of truth for Part B route work.

### 2. Analyzer Is Not Clean

Severity: Medium

Command run:

```powershell
dart analyze
```

Result: failed with 33 issues.

Most important issue:

- `analysis_options.yaml:13:38` has unsupported option `ignore ignore ignore`.

Other issues are warnings/infos such as unused private element, async `BuildContext` usage, deprecated APIs, production `print`, and file naming warnings.

Impact: CI or release gates may fail if analyzer warnings are enforced.

### 3. Stock Lock Action Is Blocked By Backend Permission

Severity: High

Observed staging request:

```text
PATCH https://api-staging.sandwichai.co/branch-stock/cms0sakxw00p8mu2iqq32ej2w/lock
```

Observed response:

```json
{"message":"Forbidden resource","error":"Forbidden","statusCode":403}
```

Mobile implementation:

- UI action: `lib/src/features/stock_control/presentation/branch_stock_details.dart`
- Bloc event: `lib/src/features/stock_control/bloc/add_branch_stock_bloc/bloc.dart`
- Repository call: `lib/src/features/stock_control/data/repo/add_branch_stock.dart:202`

Review: the mobile app is calling the expected endpoint. The failure means the logged-in user/token does not have backend permission for this stock-control action. There is currently no mobile/admin screen in this repo that grants endpoint permissions to a user.

Required backend/admin action:

- Add or expose permission assignment for the user/role that should perform stock lock/unlock/allow-negative.
- Confirm the exact permission names required by the backend for:
  - `PATCH /branch-stock/{id}/lock`
  - `PATCH /branch-stock/{id}/unlock`
  - `PATCH /branch-stock/{id}/allow-negative`
  - `GET /branch-stock/locked`
  - `GET /branch-stock/negative-stock-report`
- Return a more specific error message if possible, for example `Missing permission: branch-stock:lock`.

QA status: blocked until the staging user has the required permission or the backend exposes a permission-management flow.

### 4. Widget Test Fails Due To Firebase Initialization

Severity: Medium

Command run:

```powershell
flutter test
```

Result: failed in `test/widget_test.dart`.

Failure:

```text
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()
```

Relevant path:

- `test/widget_test.dart`
- `lib/src/core/config/app_bootstrap.dart`
- `router/router.dart`

Impact: automated test coverage cannot pass until Firebase is initialized or mocked in the widget test.

### 5. Direct Repository Construction In Some UI Screens

Severity: Low to Medium

Examples:

- `lib/src/features/procurement/presentation/procurement_good_reveived_tab.dart` creates `GoodsReceivedRepository()` and `ReorderRepository()` directly.
- Several other screens use direct repository construction patterns.

Impact: manual testing works, but automated widget tests are harder because mocks cannot be injected through global providers.

Preferred pattern: use `context.read<GoodsReceivedRepositoryInterface>()` and `context.read<ReorderRepositoryInterface>()` where practical.

## Endpoint Coverage

### Stock Control: Branch Stock Module

Status: Implemented

Endpoints from PDF:

- `GET /branch-stock/{id}` implemented in `lib/src/features/stock_control/data/repo/branch_details_repo.dart`
- `PATCH /branch-stock/{id}` implemented in `lib/src/features/stock_control/data/repo/add_branch_stock.dart:77`
- `DELETE /branch-stock/{id}` implemented in `lib/src/features/stock_control/data/repo/add_branch_stock.dart:114`
- `PATCH /branch-stock/{id}/adjust` implemented in `lib/src/features/stock_control/data/repo/add_branch_stock.dart:147`
- `PATCH /branch-stock/{id}/allow-negative` implemented in `lib/src/features/stock_control/data/repo/add_branch_stock.dart:195`
- `PATCH /branch-stock/{id}/lock` implemented in `lib/src/features/stock_control/data/repo/add_branch_stock.dart:202`
- `PATCH /branch-stock/{id}/unlock` implemented in `lib/src/features/stock_control/data/repo/add_branch_stock.dart:207`
- `GET /branch-stock/locked` implemented in `lib/src/features/stock_control/data/repo/add_branch_stock.dart:212`
- `GET /branch-stock/negative-stock-report` implemented in `lib/src/features/stock_control/data/repo/add_branch_stock.dart:217`

UI files:

- Stock details and actions: `lib/src/features/stock_control/presentation/branch_stock_details.dart`
- Stock adjustment: `lib/src/features/stock_control/presentation/stock_adjustmnt.dart`
- Reports tab shell: `lib/src/features/stock_control/presentation/stock_control_report_screens.dart`
- Drawer entry: `lib/src/features/stock_control/presentation/stock_control_drawer.dart`

### Shared: Employees Module

Status: Implemented as shared repository and cleaned up for current department employee pickers

Endpoint from PDF:

- `GET /Employees/branches/{branchId}/departments/{department}/employees`

Implementation:

- `lib/src/core/data/repo/employee_lookup_repo.dart`
- Registered in `lib/src/core/constant/di/repository_providers.dart`
- Processing uses `EmployeeRepository`, which wraps the shared lookup.
- Kitchen shift employee loading now delegates to `EmployeeLookupRepositoryInterface` instead of owning a duplicate endpoint call.

QA note: manual testing should verify every department screen that needs employee selection calls the shared endpoint with the correct department string.

### Stock Control: Expiry Tracking Module

Status: Implemented against live staging docs

Implemented surfaces:

- Expiry report tab in `StockReportsScreen`
- Expiry summary cards
- Expiry item list
- Batch bottom sheet
- Batch edit dialog

Files:

- Repository: `lib/src/features/stock_control/data/repo/stock_card_repo.dart`
- Models: `lib/src/features/stock_control/data/model/stock_card_model.dart`
- Cubit: `lib/src/features/stock_control/bloc/stock_control_reports_cubit/stock_control_reports_cubit.dart`
- UI: `lib/src/features/stock_control/presentation/stock_control_report_screens.dart`

Note: repository endpoint paths use `expiry/expiry-tracking/...`, which matches the live staging Swagger route cache.

### Procurement: Dashboard Overview

Status: Implemented and reviewed against staging response

Endpoint:

- `GET /procurement/dashboard/overview`

Files:

- Endpoint map: `lib/src/features/dashboard/data/repo/dashboard_contract_repo.dart:20`
- UI: `lib/src/features/procurement/presentation/procurement_dash.dart`
- Bloc: `lib/src/features/dashboard/bloc/dashboard_contract_bloc`

Review update:

- Live staging docs confirm the endpoint path is `/procurement/dashboard/overview`.
- Backend query params are `organizationId`, `branchId`, and `timePeriod`.
- Mobile was previously sending the old shared dashboard query key `range=today`.
- Mobile now sends procurement dashboard time filters as `timePeriod=DAILY|WEEKLY|MONTHLY`.
- Staging response uses a procurement-specific shape with `overview`, `requestsReceived`, `purchaseOrders`, and `goodsReceivedLogs`, not the generic `metrics/sections` shape.
- Staging response also includes `supplierSpendAnalysis` and `aiInsight`.
- Mobile now maps `overview.totalSpend`, `overview.purchaseOrders.total`, and `overview.deliveriesCompleted.total` into the top dashboard cards.
- Mobile now displays dashboard feed groups from the same endpoint: requests received, purchase orders, goods received, supplier spend, and AI insight.

### Procurement: Goods Received

Status: Implemented

Endpoints:

- `POST /procurement/goods-received`
- `GET /procurement/goods-received`
- `GET /procurement/goods-received/{id}`
- `PATCH /procurement/goods-received/{id}/qc`
- `GET /reorder/suggestions`
- `GET /procurement/goods-received/prefill/{poId}`
- `GET /goods-received/purchase-order/{poId}`
- `GET /goods-received/purchase-order/{poId}/delivery-status`
- `PATCH /goods-received/purchase-order/{poId}/mark-complete`
- `GET /procurement/goods-received/stats/qc`

Files:

- Repository: `lib/src/features/procurement/data/repository/procurement_good_received_repo.dart`
- Advanced cubit: `lib/src/features/procurement/procurement_blocs/goods_received_advanced_cubit/goods_received_advanced_cubit.dart`
- Tab screen: `lib/src/features/procurement/presentation/procurement_good_reveived_tab.dart`
- Overview: `lib/src/features/procurement/presentation/goods_received_overview.dart`
- Create/log receipt: `lib/src/features/procurement/presentation/create_good_recieved_proc.dart`
- History: `lib/src/features/procurement/presentation/goods_recieved_history.dart`
- Detail/QC: `lib/src/features/procurement/presentation/goods_received_detail.dart`

### Procurement: Purchase Orders

Status: Implemented

Endpoints:

- `POST /procurement/orders`
- `GET /procurement/orders`
- `PATCH /procurement/orders/{id}`
- `DELETE /procurement/orders/{id}`
- `GET /procurement/orders/{id}/approval-status`
- `POST /procurement/orders/{id}/submit-approval`
- `POST /procurement/orders/{id}/dispatch`
- `GET /procurement/orders/approval/pending`
- `POST /procurement/orders/bulk-create`
- `GET /procurement/orders/overdue-deliveries`
- `GET /procurement/orders/timeline`

Files:

- Create/update/delete/action repository: `lib/src/features/procurement/data/repository/purchase_order_repo.dart`
- List/tabs/timeline repository: `lib/src/features/procurement/data/repository/order_list_repo.dart`
- List bloc: `lib/src/features/procurement/procurement_blocs/order_list-bloc`
- Action cubit: `lib/src/features/procurement/procurement_blocs/purchase_order_actions_cubit`
- Purchase order tabs: `lib/src/features/procurement/presentation/purchase_orders_tab.dart`
- Create and bulk-create form: `lib/src/features/procurement/presentation/order_form.dart`
- List/history screen: `lib/src/features/procurement/presentation/order_list.dart`
- Details/actions/timeline/PDF: `lib/src/features/procurement/presentation/order_list_details.dart`

### Procurement: Supplier Performance

Status: Implemented

Endpoints:

- `GET /procurement/performance`
- `GET /procurement/performance/rankings`

Files:

- Repository: `lib/src/features/procurement/data/repository/procurement_performance_repo.dart`
- Cubit: `lib/src/features/procurement/procurement_blocs/procurement_performance_cubit`
- UI: `lib/src/features/procurement/presentation/procurement_dash.dart`

### Stock Control: Reorder Module

Status: Implemented

Endpoints:

- `GET /reorder/report/{branchId}`
- `POST /reorder/acknowledge/{branchStockId}`
- `GET /reorder/suggestions`

Files:

- Repository: `lib/src/features/stock_control/data/repo/reorder_repo.dart`
- Stock report UI: `lib/src/features/stock_control/presentation/stock_control_report_screens.dart`
- Goods received suggestions UI: `lib/src/features/procurement/presentation/goods_received_overview.dart`

### Stock Control: Stock Card Movement Trends

Status: Implemented

Endpoint:

- `GET /stock-cards/analytics/movement-trends`

Files:

- Repository: `lib/src/features/stock_control/data/repo/stock_card_repo.dart:131`
- Cubit: `lib/src/features/stock_control/bloc/stock_control_reports_cubit/stock_control_reports_cubit.dart:323`
- Dashboard chart: `lib/src/features/stock_control/presentation/stock_control_dashboard_body.dart:1169`

## Manual UI Test Plan

Use a real test account with valid organization, branch, and employee IDs. Test both normal data and empty-state accounts where possible.

### Setup Before Testing

1. Start the app in the target environment.
2. Log in as an employee with access to Stock Control and Procurement.
3. Confirm the branch ID and organization ID are present in cache after login.
4. Keep backend logs open so each UI action can be matched to the expected endpoint.
5. Test on one Android emulator/device and one small mobile viewport if possible.

## Department: Stock Control

Main entry screen:

- Dashboard: `lib/src/features/stock_control/presentation/stock_control_dashboard.dart`
- Dashboard body/chart: `lib/src/features/stock_control/presentation/stock_control_dashboard_body.dart`
- Drawer: `lib/src/features/stock_control/presentation/stock_control_drawer.dart`

### Test Stock Dashboard Movement Trends

1. Log in as Stock Control user.
2. Open Stock Control dashboard.
3. Wait for dashboard cards to load.
4. Confirm the `Stock Movement Trends` chart appears.
5. Pull to refresh if available or re-open the dashboard.
6. Confirm backend receives `GET /stock-cards/analytics/movement-trends`.
7. Confirm empty state appears if backend returns no trend rows.
8. Confirm error state appears if the endpoint fails.

Expected result: chart loads without UI overflow and reflects the API response.

### Test Branch Stock Details

Files:

- `lib/src/features/stock_control/presentation/branch_stock_details.dart`
- `lib/src/features/stock_control/data/repo/branch_details_repo.dart`

Steps:

1. Open Stock Control.
2. Open Branch Stock or Stock Catalogue.
3. Tap an existing stock item.
4. Confirm details screen opens.
5. Confirm backend receives `GET /branch-stock/{id}`.
6. Verify item name, current stock, unit, reorder level, and expiry data.
7. Test network failure and confirm error state is understandable.

Expected result: item details match backend data.

### Test Update Branch Stock

Files:

- `lib/src/features/stock_control/presentation/add_items_catalogue_screen.dart`
- `lib/src/features/stock_control/data/repo/add_branch_stock.dart`

Steps:

1. Open a stock item edit flow.
2. Change valid fields such as reorder level, max level, unit cost, or expiry date.
3. Save.
4. Confirm backend receives `PATCH /branch-stock/{id}`.
5. Re-open details and confirm changed values persist.
6. Try invalid values such as negative stock or invalid date.
7. Confirm the app blocks invalid input or shows a clear error.

Expected result: valid updates save, invalid updates are rejected.

### Test Delete Branch Stock

Files:

- `lib/src/features/stock_control/presentation/branch_stock_details.dart`
- `lib/src/features/stock_control/data/repo/add_branch_stock.dart`

Steps:

1. Open a disposable test stock item.
2. Use the delete action.
3. Confirm a destructive confirmation dialog appears.
4. Confirm delete.
5. Confirm backend receives `DELETE /branch-stock/{id}`.
6. Confirm the item no longer appears in the list.

Expected result: item is deleted and UI returns to a valid state.

### Test Stock Adjustment

Files:

- `lib/src/features/stock_control/presentation/stock_adjustmnt.dart`
- `lib/src/features/stock_control/data/repo/add_branch_stock.dart`

Steps:

1. Open a stock item.
2. Open Stock Adjustment.
3. Test `ADD`, `SUBTRACT`, and `SET` with valid quantities.
4. Confirm backend receives `PATCH /branch-stock/{id}/adjust`.
5. Confirm `performedBy` is populated from the logged-in employee.
6. Confirm stock quantity changes after refresh.
7. Try zero or invalid quantity.

Expected result: adjustment succeeds and validation prevents bad data.

### Test Allow Negative, Lock, And Unlock

Files:

- `lib/src/features/stock_control/presentation/branch_stock_details.dart`
- `lib/src/features/stock_control/bloc/add_branch_stock_bloc`
- `lib/src/features/stock_control/data/repo/add_branch_stock.dart`

Steps:

1. Open a stock item detail screen.
2. Tap `Allow Negative Stock`.
3. Confirm warning dialog appears.
4. Confirm action.
5. Confirm backend receives `PATCH /branch-stock/{id}/allow-negative`.
6. Tap `Lock Item`.
7. Confirm backend receives `PATCH /branch-stock/{id}/lock`.
8. Refresh the detail screen and verify locked state if shown.
9. Tap `Unlock Item`.
10. Confirm backend receives `PATCH /branch-stock/{id}/unlock`.

Expected result: each action shows success/failure feedback and the item state updates.

Known blocker:

- Staging currently returns `403 Forbidden resource` for `PATCH /branch-stock/{id}/lock` with the tested user.
- This is not fixable from the current mobile UI because there is no permission assignment screen.
- Retest after backend/admin grants the required stock-control permission to the user or role.

### Test Stock Reports

Files:

- `lib/src/features/stock_control/presentation/stock_control_report_screens.dart`
- `lib/src/features/stock_control/bloc/stock_control_reports_cubit`
- `lib/src/features/stock_control/data/repo/stock_card_repo.dart`
- `lib/src/features/stock_control/data/repo/reorder_repo.dart`

Steps:

1. Open Stock Control drawer.
2. Tap `Reports`.
3. Confirm tabs appear: `Expiry`, `Locked Stock`, `Negative Stock`, `Reorder`.

Expiry tab:

1. Open `Expiry`.
2. Confirm summary cards and expiry list load.
3. Confirm expected endpoints are called.
4. Confirm backend receives `/expiry/expiry-tracking/...` requests.
5. Tap an expiry item.
6. Confirm batch bottom sheet opens.
7. Edit a batch.
8. Confirm patch endpoint is called and list refreshes.

Locked Stock tab:

1. Open `Locked Stock`.
2. Confirm backend receives `GET /branch-stock/locked`.
3. Verify locked items appear.
4. Test empty state.

Negative Stock tab:

1. Open `Negative Stock`.
2. Confirm backend receives `GET /branch-stock/negative-stock-report`.
3. Verify negative stock items are highlighted.
4. Test empty state.

Reorder tab:

1. Open `Reorder`.
2. Confirm backend receives `GET /reorder/report/{branchId}`.
3. Tap `Acknowledge` on a reorder item.
4. Confirm backend receives `POST /reorder/acknowledge/{branchStockId}`.
5. Confirm button changes to acknowledged or list refreshes.

Expected result: all tabs load, refresh, handle errors, and actions show feedback.

## Department: Procurement

Main entry screen:

- Dashboard: `lib/src/features/procurement/presentation/procurement_dash.dart`
- Drawer: `lib/src/features/procurement/presentation/procurement_drawer.dart`

### Test Procurement Dashboard Overview

Files:

- `lib/src/features/procurement/presentation/procurement_dash.dart`
- `lib/src/features/dashboard/data/repo/dashboard_contract_repo.dart`
- `lib/src/features/dashboard/bloc/dashboard_contract_bloc`

Steps:

1. Log in as Procurement user.
2. Open Procurement dashboard.
3. Confirm overview cards load.
4. Confirm backend receives `GET /procurement/dashboard/overview`.
5. Pull to refresh.
6. Confirm loading and error states work.

Expected result: dashboard metrics match backend response.

### Test Supplier Performance And Rankings

Files:

- `lib/src/features/procurement/data/repository/procurement_performance_repo.dart`
- `lib/src/features/procurement/procurement_blocs/procurement_performance_cubit`
- `lib/src/features/procurement/presentation/procurement_dash.dart`

Steps:

1. Open Procurement dashboard.
2. Scroll to performance section.
3. Confirm backend receives `GET /procurement/performance`.
4. Scroll to supplier rankings section.
5. Confirm backend receives `GET /procurement/performance/rankings`.
6. Verify ranked suppliers, scores, on-time rate, defect rate, and totals if shown.
7. Test empty rankings.
8. Test permission error and confirm message is clear.

Expected result: performance and ranking data render correctly.

### Test Goods Received Overview

Files:

- `lib/src/features/procurement/presentation/procurement_good_reveived_tab.dart`
- `lib/src/features/procurement/presentation/goods_received_overview.dart`
- `lib/src/features/procurement/procurement_blocs/goods_received_advanced_cubit`

Steps:

1. Open Procurement drawer.
2. Tap `Good Received Log`.
3. Open `Overview` tab.
4. Confirm QC stats load from `GET /procurement/goods-received/stats/qc`.
5. Confirm reorder suggestions load from `GET /reorder/suggestions`.
6. Verify empty, loading, and error states.

Expected result: overview cards and suggestions are visible and accurate.

### Test Log Goods Received

Files:

- `lib/src/features/procurement/presentation/create_good_recieved_proc.dart`
- `lib/src/features/procurement/data/repository/procurement_good_received_repo.dart`

Steps:

1. Open Procurement drawer.
2. Tap `Good Received Log`.
3. Open `Log Receipt` tab.
4. Fill supplier, invoice, PO number, received by, inspected by, and item rows.
5. Submit the form.
6. Confirm backend receives `POST /procurement/goods-received`.
7. Confirm success message appears.
8. Open `History` and confirm the new receipt appears.
9. Try submitting with missing required fields.

Expected result: valid receipt creates successfully and validation blocks incomplete forms.

### Test PO Prefill And Delivery Status In Goods Received

Files:

- `lib/src/features/procurement/presentation/create_good_recieved_proc.dart`
- `lib/src/features/procurement/procurement_blocs/goods_received_advanced_cubit`

Steps:

1. Open `Goods Received > Log Receipt`.
2. Enter or select a valid purchase order ID.
3. Trigger PO prefill.
4. Confirm backend receives `GET /procurement/goods-received/prefill/{poId}`.
5. Confirm backend receives `GET /goods-received/purchase-order/{poId}/delivery-status`.
6. Confirm backend receives `GET /goods-received/purchase-order/{poId}`.
7. Verify supplier and item data prefill correctly.
8. Confirm delivered, pending, and received quantities are correct.
9. Tap mark complete where available.
10. Confirm backend receives `PATCH /goods-received/purchase-order/{poId}/mark-complete`.

Expected result: PO data preloads and completion status updates.

### Test Goods Received History, Details, And QC

Files:

- `lib/src/features/procurement/presentation/goods_recieved_history.dart`
- `lib/src/features/procurement/presentation/goods_received_detail.dart`

Steps:

1. Open `Goods Received > History`.
2. Confirm backend receives `GET /procurement/goods-received`.
3. Tap a receipt.
4. Confirm backend receives `GET /procurement/goods-received/{id}`.
5. Verify receipt information, QC summary, and item list.
6. Tap the QC action icon.
7. Choose `PASSED`, `FAILED`, or `PARTIAL`.
8. Add a QC note.
9. Save.
10. Confirm backend receives `PATCH /procurement/goods-received/{id}/qc`.
11. Confirm detail reloads with updated QC state.

Expected result: details and QC updates work end to end.

### Test Purchase Order Create

Files:

- `lib/src/features/procurement/presentation/purchase_orders_tab.dart`
- `lib/src/features/procurement/presentation/order_form.dart`
- `lib/src/features/procurement/data/repository/purchase_order_repo.dart`

Steps:

1. Open Procurement drawer.
2. Tap `Purchase Orders`.
3. Open `Create PO`.
4. Select supplier and buyer/branch data.
5. Fill priority, delivery date, payment term, delivery address/city/state, and item rows.
6. Submit.
7. Confirm backend receives `POST /procurement/orders`.
8. Confirm success feedback and navigation.
9. Open PO History and confirm the new PO appears.

Expected result: purchase order is created and visible in history.

### Test Purchase Order Bulk Create

Files:

- `lib/src/features/procurement/presentation/order_form.dart`
- `lib/src/features/procurement/procurement_blocs/porchase_order_blocs/bloc.dart`
- `lib/src/features/procurement/data/repository/purchase_order_repo.dart`

Steps:

1. Open `Purchase Orders > Create PO`.
2. Use the bulk-create workflow.
3. Add at least two valid orders.
4. Submit bulk create.
5. Confirm backend receives `POST /procurement/orders/bulk-create`.
6. Verify success and confirm all orders appear in history.
7. Try submitting one order only and confirm validation prevents it.

Expected result: bulk create accepts two or more valid orders and rejects invalid bulk payloads.

### Test Purchase Order List, Search, Filters, Pending, And Overdue

Files:

- `lib/src/features/procurement/presentation/order_list.dart`
- `lib/src/features/procurement/procurement_blocs/order_list-bloc`
- `lib/src/features/procurement/data/repository/order_list_repo.dart`

Steps:

1. Open `Purchase Orders`.
2. Open `PO History`.
3. Confirm `All`, `Pending Approvals`, and `Overdue` tabs appear.
4. On `All`, confirm backend receives `GET /procurement/orders`.
5. Search by order number or supplier.
6. Confirm query results update.
7. Apply status, priority, and category filters.
8. Confirm query parameters are sent.
9. Switch to `Pending Approvals`.
10. Confirm backend receives `GET /procurement/orders/approval/pending`.
11. Switch to `Overdue`.
12. Confirm backend receives `GET /procurement/orders/overdue-deliveries`.
13. Scroll to bottom and confirm pagination loads more items.

Expected result: each tab calls its correct endpoint and list states are stable.

### Test Purchase Order Details And Actions

Files:

- `lib/src/features/procurement/presentation/order_list_details.dart`
- `lib/src/features/procurement/procurement_blocs/purchase_order_actions_cubit`
- `lib/src/features/procurement/data/repository/purchase_order_repo.dart`
- `lib/src/features/procurement/data/repository/order_list_repo.dart`

Steps:

1. Open `Purchase Orders > PO History`.
2. Tap an order.
3. Confirm details screen opens.
4. Confirm backend receives `GET /procurement/orders/{id}/approval-status`.
5. Confirm backend receives `GET /procurement/orders/timeline` with `orderId`.
6. Verify approval status banner and timeline section.
7. Open overflow menu.
8. Tap `Edit Order`.
9. Save a valid update.
10. Confirm backend receives `PATCH /procurement/orders/{id}`.
11. Open overflow menu.
12. Tap `Submit Approval`.
13. Confirm backend receives `POST /procurement/orders/{id}/submit-approval`.
14. Open overflow menu.
15. Tap `Dispatch Order`.
16. Enter required dispatch fields.
17. Confirm backend receives `POST /procurement/orders/{id}/dispatch`.
18. Use a disposable order and tap `Delete Order`.
19. Confirm destructive dialog appears.
20. Confirm backend receives `DELETE /procurement/orders/{id}`.
21. Verify list refreshes after returning.

Expected result: actions call correct endpoints, show success/failure, and refresh context.

### Test Purchase Order PDF Actions

Files:

- `lib/src/features/procurement/presentation/order_list_details.dart`

Steps:

1. Open an order detail.
2. Tap share icon.
3. Confirm PDF generation completes.
4. Use overflow menu and tap `Print Order`.
5. Confirm print dialog opens.
6. Use overflow menu and tap `Download PDF`.
7. Confirm saved-file snackbar appears.

Expected result: PDF actions work without blocking purchase order API actions.

## Cross-Department Employee Lookup Testing

Files:

- `lib/src/core/data/repo/employee_lookup_repo.dart`
- `lib/src/core/constant/di/repository_providers.dart`

Steps:

1. Find each screen that assigns `receivedBy`, `inspectedBy`, `buyer`, `processor`, or department staff.
2. Open the employee picker or employee-dependent form.
3. Confirm backend receives `GET /Employees/branches/{branchId}/departments/{department}/employees`.
4. Verify the department value matches the current department.
5. Test search, role filter, and status filter where the UI exposes them.
6. Confirm no employees state is clear.
7. Confirm permissions errors are visible.

Expected result: each department can fetch the correct employee list for its branch and department.

## Regression Tests To Add

Add automated tests after the endpoint mismatch and Firebase test setup are fixed.

Recommended tests:

- Repository unit test for every M1 endpoint path.
- Parser tests for every M1 response model.
- Cubit/bloc tests for loading, loaded, empty, and error states.
- Widget tests for Stock Reports tabs.
- Widget tests for Goods Received overview/history/detail/QC.
- Widget tests for Purchase Orders all/pending/overdue tabs.
- Widget test for Purchase Order detail menu actions.
- Widget test for Procurement dashboard overview/performance/rankings.
- Golden or screenshot tests for small mobile widths on dashboard/report screens.

## Verification Commands

Run these before sign-off:

```powershell
dart analyze
flutter test
```

Current result on 2026-07-25:

- `dart analyze`: failed with 33 warnings/infos.
- `flutter test`: failed because Firebase is not initialized in `test/widget_test.dart`.

## Sign-Off Checklist

- Use `/expiry/expiry-tracking/...` for expiry endpoints per live staging docs.
- Fix analyzer configuration in `analysis_options.yaml`.
- Fix Firebase setup/mocking for widget tests.
- Re-run `dart analyze`.
- Re-run `flutter test`.
- Run the manual UI test plan above with backend logs open.
- Capture screenshots for successful dashboard/report/detail/action states.
- Capture screenshots for at least one empty state and one backend error state per department.
