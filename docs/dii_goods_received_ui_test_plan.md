# D(ii) Goods Received UI Test Plan

Date prepared: 2026-07-26  
Department: Procurement  
Module: Goods Received

## Goal

Verify the mobile app correctly uses the Goods Received endpoints from the M1 document and live staging docs.

## Screens To Test

- Main screen: Procurement > Goods Received
- File: `lib/src/features/procurement/presentation/procurement_good_reveived_tab.dart`
- Overview tab: `lib/src/features/procurement/presentation/goods_received_overview.dart`
- Log Receipt tab: `lib/src/features/procurement/presentation/create_good_recieved_proc.dart`
- History tab: `lib/src/features/procurement/presentation/goods_recieved_history.dart`
- Detail/QC screen: `lib/src/features/procurement/presentation/goods_received_detail.dart`
- Repository: `lib/src/features/procurement/data/repository/procurement_good_received_repo.dart`

## Endpoints Covered

- `POST /procurement/goods-received`
- `GET /procurement/goods-received`
- `GET /procurement/goods-received/{id}`
- `PATCH /procurement/goods-received/{id}/qc`
- `GET /reorder/suggestions`
- `GET /procurement/goods-received/prefill/{poId}`

## Before Testing

1. Log in to staging as a Procurement user.
2. Open Flutter logs.
3. Confirm logs use `SandwichAI.INFO` and long responses are split into numbered chunks.
4. Keep one valid branch ID ready.
5. Keep one valid PO ID ready if testing PO prefill.

## Test 1: Overview Tab

Steps:

1. Open Procurement.
2. Open Goods Received.
3. Stay on the Overview tab.
4. Pull to refresh.

Expected logs:

```text
GET /procurement/goods-received/stats/qc
GET /reorder/suggestions?branchId={branchId}
```

Expected UI:

- QC Stats cards load or show a clear empty/error state.
- Reorder Suggestions load or show `No reorder suggestions`.
- If permission is missing, the app should show a clear unavailable message.

Report if failing:

```text
D(ii) Overview issue
Endpoint:
GET /reorder/suggestions?branchId={branchId}

Expected:
Reorder suggestions or valid empty state.

Actual:
Paste response status and response text.
```

## Test 2: Create Goods Received

Steps:

1. Open Goods Received.
2. Go to Log Receipt tab.
3. Fill required fields:
   - Branch
   - Supplier
   - Invoice number
   - PO number if available
   - Received By
   - Inspected By
   - At least one item
   - Received quantity
   - Quality check
4. Tap Submit Goods Received.

Expected log:

```text
POST /procurement/goods-received
```

Expected UI:

- Success snackbar appears.
- Receipt is created.
- New receipt appears in History after refresh.

Report if failing:

```text
D(ii) Create GRN issue
Endpoint:
POST /procurement/goods-received

Request body:
Paste request body from log.

Response:
Paste status code and response text.

Question for backend:
Confirm required fields for basic GRN and whether purchaseOrderId is required.
```

## Test 3: PO Prefill

Steps:

1. Open Goods Received > Log Receipt.
2. Enter a valid PO ID.
3. Trigger PO prefill.

Expected log:

```text
GET /procurement/goods-received/prefill/{poId}
```

Expected UI:

- Supplier name fills from PO.
- PO number fills from PO.
- Items fill from PO.
- Fully received PO lines should not appear.

Report if failing:

```text
D(ii) PO Prefill issue
Endpoint:
GET /procurement/goods-received/prefill/{poId}

PO ID:
{poId}

Expected:
Supplier, PO number, and outstanding item rows are returned.

Actual:
Paste response status and response text.
```

## Test 4: Goods Received History

Steps:

1. Open Goods Received.
2. Go to History tab.
3. Pull to refresh.

Expected log:

```text
GET /procurement/goods-received?branchId={branchId}
```

Expected UI:

- Existing GRN logs appear.
- Empty state appears if backend returns no records.
- Each card should show supplier, receipt/GRN number, item counts, QC status, and date where available.

Report if failing:

```text
D(ii) History issue
Endpoint:
GET /procurement/goods-received?branchId={branchId}

Expected:
GRN list or valid empty state.

Actual:
Paste response status and response text.
```

## Test 5: Goods Received Detail

Steps:

1. Open Goods Received > History.
2. Tap one receipt.

Expected log:

```text
GET /procurement/goods-received/{id}
```

Expected UI:

- Detail screen opens.
- Receipt fields match backend.
- Items list is visible.
- QC action is available.

Report if failing:

```text
D(ii) GRN Detail issue
Endpoint:
GET /procurement/goods-received/{id}

GRN ID:
{id}

Expected:
Receipt detail data.

Actual:
Paste response status and response text.
```

## Test 6: Update QC

Steps:

1. Open a Goods Received detail screen.
2. Tap QC action.
3. Select QC status.
4. Add note if needed.
5. Save.

Expected log:

```text
PATCH /procurement/goods-received/{id}/qc
```

Expected UI:

- Success feedback appears.
- Detail reloads.
- QC status changes.

Report if failing:

```text
D(ii) QC update issue
Endpoint:
PATCH /procurement/goods-received/{id}/qc

GRN ID:
{id}

Request body:
Paste request body.

Response:
Paste status code and response text.

Question for backend:
Confirm valid qcStatus values and required inspectedBy/item fields.
```

## Known Mobile Risk

Live backend docs show advanced PO-linked GRN fields:

- `purchaseOrderId`
- `deliveryNote`
- `isPartialDelivery`
- `isFinalDelivery`
- `purchaseOrderItemId`
- `packagingConfigId`

The current mobile flow has the basic Goods Received flow implemented. If PO-linked receiving fails, check whether the backend now requires those advanced fields.

## Tomorrow Sign-Off Checklist

- Overview loads QC stats.
- Overview calls reorder suggestions with `branchId`.
- Create GRN works.
- PO prefill works.
- History loads.
- Detail opens.
- QC update works.
- Any backend failure is copied into `docs/m1_api_blockers.md`.
