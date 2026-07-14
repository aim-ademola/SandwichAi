# M1 Mobile API Implementation Plan

Source: `C:\Users\Aim\Downloads\Mobile App Api Implementation M1 Doc.pdf`

Goal: consume every M1 endpoint, reusing existing screens where possible and adding compact operational screens only where the app has no natural surface yet.

## Implementation Rules

- Prefer extending existing repositories, blocs, and screens before adding new modules.
- If an endpoint is action-only, expose it as a button, dialog, bottom sheet, card action, or chart data source instead of creating a full screen.
- If an endpoint returns a report/list/chart, add a real screen or dashboard section.
- Keep department ownership clear:
  - Stock Control: branch stock, expiry, reorder, stock cards.
  - Procurement: dashboard overview, goods received, purchase orders, supplier performance.
  - Shared: employee lookup by branch and department.
- Each endpoint must have a typed request/response model, repository method, bloc/cubit event/state, UI loading/empty/error states, and a focused analyzer pass.

## Current Coverage Snapshot

### Already Partly Consumed

| Area | Endpoint(s) | Current App Surface | Gap |
| --- | --- | --- | --- |
| Branch stock CRUD | `GET /branch-stock/{id}`, `PATCH /branch-stock/{id}`, `DELETE /branch-stock/{id}`, `PATCH /branch-stock/{id}/adjust` | Stock catalogue/details/add-edit/adjustment flows | Needs verification against final DTO shape |
| Employees by department | `GET /Employees/branches/{branchId}/departments/{department}/employees` | Processing employee repository | Move toward shared picker/service for all departments |
| Goods received basic flow | `POST /procurement/goods-received`, `GET /procurement/goods-received` | Procurement goods received create/history tab | Missing detail, QC action, PO prefill/status/stats |
| Purchase orders basic flow | `POST /procurement/orders`, `GET /procurement/orders` | Procurement order form/list/details | Missing update/delete/approval/dispatch/bulk/overdue/timeline |
| Procurement dashboard | `GET /procurement/dashboard/overview` | Procurement dashboard exists; generic dashboard repo currently points to `procurement/dashboard` | Align endpoint and UI cards |

### Not Yet Covered Or Needs New Surface

| Area | Endpoint(s) | Planned Surface |
| --- | --- | --- |
| Branch stock controls | `PATCH /branch-stock/{id}/allow-negative`, `/lock`, `/unlock`, `GET /branch-stock/locked`, `GET /branch-stock/negative-stock-report` | Stock item detail actions, Locked Stock screen, Negative Stock Report screen |
| Expiry tracking | `GET /stock-cards/expiry-report`, `GET /stock-cards/analytics/expiry-summary`, `GET /stock-cards/{branchId}/expiry-report`, `GET /stock-cards/{branchId}/{itemId}/batches`, `PATCH /stock-cards/{branchId}/{itemId}/batches/{batchId}` | Expiry Tracking screen, expiry summary cards, item batch bottom sheet/edit dialog |
| Goods received advanced | `GET /procurement/goods-received/{id}`, `PATCH /procurement/goods-received/{id}/qc`, `GET /reorder/suggestions`, `GET /procurement/goods-received/prefill/{poId}`, `GET /goods-received/purchase-order/{poId}`, `GET /goods-received/purchase-order/{poId}/delivery-status`, `PATCH /goods-received/purchase-order/{poId}/mark-complete`, `GET /procurement/goods-received/stats/qc` | Goods Received detail screen, QC modal, PO prefill flow, delivery status panel, QC stats cards |
| Purchase order advanced | `PATCH /procurement/orders/{id}`, `DELETE /procurement/orders/{id}`, `GET /procurement/orders/{id}/approval-status`, `POST /procurement/orders/{id}/submit-approval`, `POST /procurement/orders/{id}/dispatch`, `GET /procurement/orders/approval/pending`, `POST /procurement/orders/bulk-create`, `GET /procurement/orders/overdue-deliveries`, `GET /procurement/orders/timeline` | Existing PO details/list/form actions, pending approvals tab, overdue deliveries tab, timeline chart |
| Supplier performance | `GET /procurement/performance`, `GET /procurement/performance/rankings` | Procurement dashboard performance cards and Supplier Rankings screen/section |
| Reorder module | `GET /reorder/report/{branchId}`, `POST /reorder/acknowledge/{branchStockId}` | Stock Control Reorder Report screen with acknowledge action |
| Stock card movement trends | `GET /stock-cards/analytics/movement-trends` | Stock Control dashboard chart |

## Phase 1: API Layer And Models

1. Create `stock_cards_repo.dart` and models for expiry reports, expiry summary, batches, batch update, and movement trends.
2. Extend branch stock repository with:
   - `allowNegativeStock(stockId)`
   - `lockStock(stockId)`
   - `unlockStock(stockId)`
   - `getLockedStock()`
   - `getNegativeStockReport()`
3. Extend goods received repository with:
   - `getGoodsReceivedById(id)`
   - `updateGoodsReceivedQc(id, request)`
   - `getGoodsReceivedPrefill(poId)`
   - `getGoodsReceivedByPurchaseOrder(poId)`
   - `getPurchaseOrderDeliveryStatus(poId)`
   - `markPurchaseOrderComplete(poId)`
   - `getGoodsReceivedQcStats()`
4. Add reorder repository methods:
   - `getReorderSuggestions()`
   - `getReorderReport(branchId)`
   - `acknowledgeReorder(branchStockId)`
5. Extend procurement order repository with:
   - update, delete, approval status, submit approval, dispatch, pending approvals, bulk create, overdue deliveries, timeline.
6. Add procurement performance repository:
   - `getProcurementPerformance()`
   - `getProcurementPerformanceRankings()`
7. Promote employee-by-department lookup into a shared repository/helper so procurement, stock control, kitchen, and processing can reuse it.

## Phase 2: Stock Control Screens

1. Add stock detail actions:
   - Allow negative stock.
   - Lock item.
   - Unlock item.
   - Show confirmation dialogs with clear warnings.
2. Add drawer entries:
   - `Expiry Tracking`
   - `Locked Stock`
   - `Negative Stock Report`
   - `Reorder Report`
3. Build Expiry Tracking screen:
   - Summary cards from `/stock-cards/analytics/expiry-summary`.
   - Branch expiry list from `/stock-cards/{branchId}/expiry-report`.
   - Global report mode from `/stock-cards/expiry-report` if department-wide.
4. Build batch bottom sheet:
   - Load `/stock-cards/{branchId}/{itemId}/batches`.
   - Patch batch details with `/stock-cards/{branchId}/{itemId}/batches/{batchId}`.
5. Add movement trends chart to Stock Control dashboard using `/stock-cards/analytics/movement-trends`.

## Phase 3: Procurement Goods Received

1. Update Procurement dashboard to consume `/procurement/dashboard/overview`.
2. Expand Goods Received history:
   - Tap row/card opens detail from `/procurement/goods-received/{id}`.
   - Add QC update modal using `/procurement/goods-received/{id}/qc`.
3. Add PO-driven receiving:
   - Search/select PO.
   - Prefill goods received form from `/procurement/goods-received/prefill/{poId}`.
   - Show delivery status from `/goods-received/purchase-order/{poId}/delivery-status`.
   - Mark PO complete from `/goods-received/purchase-order/{poId}/mark-complete`.
4. Add QC stats cards to Goods Received tab from `/procurement/goods-received/stats/qc`.
5. Add reorder suggestions panel using `/reorder/suggestions`.

## Phase 4: Procurement Purchase Orders

1. Extend existing PO details screen actions:
   - Edit order: `PATCH /procurement/orders/{id}`.
   - Delete order: `DELETE /procurement/orders/{id}`.
   - Submit approval: `POST /procurement/orders/{id}/submit-approval`.
   - Dispatch: `POST /procurement/orders/{id}/dispatch`.
2. Add approval status banner from `/procurement/orders/{id}/approval-status`.
3. Add Procurement tabs/filters:
   - Pending approvals from `/procurement/orders/approval/pending`.
   - Overdue deliveries from `/procurement/orders/overdue-deliveries`.
4. Add bulk-create workflow only if product UX requires it; otherwise keep repository-only until requested.
5. Add timeline chart to procurement dashboard/details from `/procurement/orders/timeline`.

## Phase 5: Supplier Performance

1. Add supplier performance cards on Procurement dashboard:
   - Overall procurement performance from `/procurement/performance`.
2. Add supplier ranking section:
   - Ranking list from `/procurement/performance/rankings`.
3. Link ranking items to existing supplier/product screens where possible.

## Phase 6: Validation And Rollout

1. Run `dart analyze` on each touched module.
2. Smoke-test navigation paths:
   - Stock Control drawer entries.
   - Procurement drawer entries.
   - Goods received create/detail/QC.
   - Purchase order detail actions.
3. Validate API requests with real branch/org/employee IDs from cache.
4. Verify empty/error states for endpoints that may return no data.
5. Keep feature flags/placeholders only for screens whose backend is unavailable.

## Suggested Implementation Order

1. Stock card + branch stock control repository methods.
2. Stock Control report/action screens.
3. Goods Received detail/QC/prefill/stats.
4. Purchase Order detail actions and approval/dispatch flows.
5. Procurement dashboard charts/performance/rankings.
6. Final endpoint audit against the PDF checklist.
