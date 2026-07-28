# Stock Request Scope And Test Plan

## Deployment Focus

The priority for tomorrow's deployment is Stock Request, alongside the other Milestone 1 features.

Goods Received enhancements, procurement extras, and non-critical purchase-order flows can be handled later in the week unless they directly block Stock Request.

## Key Business Terms

### Stock Request

A request for existing stock already available inside the organization.

There are two types:

- Interdepartment stock request
- Interbranch stock request

Current implementation status:

Already existing:

- Create stock request screen: `lib/src/features/processing/presentation/req_stock.dart`
- Stock request history/list screen: `lib/src/features/processing/presentation/stock_req_history.dart`
- Stock request details screen: `lib/src/features/processing/presentation/stock_req_details.dart`
- Stock Control fulfillment/action screen: `lib/src/features/stock_control/presentation/complete_stock_reqs.dart`
- Stock request bloc: `lib/src/features/processing/bloc/stock_request_bloc/`
- Stock request repository: `lib/src/features/processing/data/repo/stock_request_repo.dart`
- Stock request model: `lib/src/features/processing/data/model/stock_reuest_model.dart`

Already partially working:

- Users can create stock requests.
- The create screen loads inventory items.
- The create screen already loads branch stock for the current branch.
- Stock request list/history exists.
- Stock request details exists.
- Stock Control has a screen where request actions can be performed.

Needs implementation or verification:

- Show available stock quantity clearly before the requester submits.
- Make interdepartment stock request the default flow for all departments.
- Add interbranch stock request option only for Procurement.
- Add issuing branch selector only for Procurement interbranch requests.
- Ensure interdepartment requests submit without `issuingBranchId`.
- Ensure interbranch requests require `issuingBranchId`.
- Ensure `issuingBranchId` is different from `requestingBranchId`.
- Add or confirm incoming external branch request view for Stock Control.
- Add or confirm outgoing interbranch request view for Procurement.
- Hide or remove direct approval action if approval must go through approval workflow.
- Block manual complete for interbranch requests.
- Add or wire dispatch action for interbranch requests.
- Update list/details screens to show request type, requesting branch, and issuing branch.

Interdepartment app flow:

```text
Requester creates stock request
        ↓
Stock Control sees incoming request
        ↓
Stock Control approves or rejects
        ↓
If approved, Stock Control prepares/moves item physically
        ↓
Stock Control completes request in the app
        ↓
Stock is deducted from branch stock
```

Interbranch app flow:

```text
Procurement creates interbranch stock request
        ↓
External branch Stock Control sees incoming request
        ↓
External branch approves/processes/dispatches
        ↓
Request becomes IN_TRANSIT
        ↓
Requesting branch confirms receipt later through Goods Received
```

### Purchase Request

An internal request to Procurement asking them to buy an item.

Usually this comes from Stock Control because Stock Control manages the store, but other departments may also raise purchase requests where needed.

Example:

```text
Stock Control -> Procurement
"Rice is low. Please purchase rice."
```

Procurement sees these under Procurement Request and can raise a Purchase Order from them.

Current implementation note:

- Purchase Request already has existing screens and should be checked before implementation, not reworked as part of Stock Request.
- Stock Control create screen: `lib/src/features/stock_control/presentation/precuremnt_req.dart`
- Procurement request list screen: `lib/src/features/procurement/presentation/procuremnt_purchase_req.dart`
- Procurement request details screen: `lib/src/features/procurement/presentation/Procurement_req_dtls.dart`
- This flow already consumes branch stock on the Stock Control create screen, so use it as a reference for Stock Request availability display.

### Purchase Order

The actual buying document Procurement raises to a supplier.

Procurement can create a purchase order in two ways:

- From a purchase request submitted by Stock Control or another department.
- Directly by Procurement, without a prior purchase request.

## Departments In Scope

### Stock Control

Stock Control is the central store within a branch.

Responsibilities:

- Holds branch inventory.
- Receives interdepartment stock requests from other departments.
- Processes and fulfills internal stock requests.
- Can raise purchase requests to Procurement when stock is low.

### Procurement

Procurement handles sourcing decisions.

Responsibilities:

- Reviews purchase requests.
- Raises purchase orders.
- Can create interbranch stock requests.
- Decides whether to request stock from another branch before buying from a supplier.

### Processing

Processing can request stock from Stock Control within the same branch.

### Kitchen

Kitchen can request stock from Stock Control within the same branch.

### POS / Sales / Front Desk

POS or sales-facing teams can request operational items or consumables from Stock Control within the same branch.

### Admin / Management

Admin or management handles approval workflow, oversight, and audit tracking.

## Stock Request Types

### Interdepartment Stock Request

This is a same-branch request between a department and Stock Control.

Example:

```text
Kitchen -> Stock Control, same branch
Processing -> Stock Control, same branch
POS -> Stock Control, same branch
```

Rules:

- Available to all departments.
- `requestingBranchId` should be the current user's branch.
- `issuingBranchId` should be empty.
- No Goods Received record is required.
- Completion happens directly in the stock request flow.

### Interbranch Stock Request

This is a request from one branch to another branch.

Example:

```text
Procurement at HQ -> Victoria Island branch
```

Recommended scope for this release:

- Only Procurement should create interbranch stock requests.
- Other departments should not directly request stock from another branch.
- This keeps interbranch movement centralized and easier to audit.

Rules:

- `requestingBranchId` should be the current user's branch.
- `issuingBranchId` is required.
- `issuingBranchId` must be different from `requestingBranchId`.
- Interbranch requests should not be manually completed.
- Final completion should happen only after stock is received and tracked with `stockRequestId`.

## Recommended Department Flow

If a department needs stock:

```text
Department -> Stock Control
```

If Stock Control cannot fulfill:

```text
Stock Control / Department -> Purchase Request -> Procurement
```

Procurement then decides:

```text
Procurement -> Interbranch Stock Request
```

or

```text
Procurement -> Purchase Order
```

## Screens To Create Or Verify

## Existing Screens In The App

### Already Available

- Processing stock request tabs: `lib/src/features/processing/presentation/processing_to_stock_requisitin_tab.dart`
- Create stock request: `lib/src/features/processing/presentation/req_stock.dart`
- Stock request history/list: `lib/src/features/processing/presentation/stock_req_history.dart`
- Stock request details: `lib/src/features/processing/presentation/stock_req_details.dart`
- Stock Control fulfillment/actions: `lib/src/features/stock_control/presentation/complete_stock_reqs.dart`
- Stock Control procurement request: `lib/src/features/stock_control/presentation/precuremnt_req.dart`
- Procurement request list: `lib/src/features/procurement/presentation/procuremnt_purchase_req.dart`
- Procurement request details: `lib/src/features/procurement/presentation/Procurement_req_dtls.dart`
- Purchase order form/list: `lib/src/features/procurement/presentation/order_form.dart`, `lib/src/features/procurement/presentation/order_list.dart`

### Needs Update Or New Screen

- Create stock request needs interdepartment/interbranch mode handling.
- Stock request list/details need request type and issuing branch visibility.
- Stock Control fulfillment needs incoming external branch request handling.
- Procurement needs an interbranch stock request view for outgoing requests.
- Approval workflow screen/API path needs to be confirmed.
- Interbranch dispatch UI needs to be added or wired into Stock Control fulfillment.

## Step-by-Step Implementation Plan

### Step 1: Freeze The Deployment Scope

Goal:

- Implement only Stock Request items needed for tomorrow.
- Do not spend time on full Goods Received or purchase order enhancements unless they directly block interbranch stock request testing.

Decision:

- Interdepartment stock request: available to all departments.
- Interbranch stock request: Procurement only.
- Approval: approval workflow only.

### Step 2: Audit The Current Stock Request Flow

Use the existing screens:

- `RequestStockScreen`
- `StockRequestsScreen`
- `StockRequestDetailsScreen`
- `CompleteStockRequestDetailsScreen`

Check:

- Can a department create a request?
- Does it send the right branch and department?
- Does it appear in the list?
- Does Stock Control see it?
- Can Stock Control process it?
- Which endpoint is currently used for approval?
- Which statuses are currently visible in the UI?

Output:

- Mark each item as done, partial, missing, or backend blocker.

### Step 3: Update The Stock Request Data Model

Add support for the backend fields required by Kamal's document:

- `requestType`
- `issuingBranchId`
- `issuingBranch`
- `requestingBranch`
- `qtySent`
- any dispatch metadata returned by backend

Rules:

- Interdepartment requests should not send `issuingBranchId`.
- Interbranch requests must send `issuingBranchId`.
- `issuingBranchId` must not equal `requestingBranchId`.

### Step 4: Update Create Stock Request Screen

Existing screen:

- `lib/src/features/processing/presentation/req_stock.dart`

Required behavior:

- All departments can create interdepartment requests.
- Procurement can choose between interdepartment and interbranch.
- Non-procurement departments should not see interbranch option.
- For interdepartment, hide issuing branch selector and submit without `issuingBranchId`.
- For interbranch, show issuing branch selector and require a different branch.
- Before submitting, show the available stock quantity at the source branch.

UI fields:

- Request type selector, only for Procurement.
- Issuing branch selector, only when request type is interbranch.
- Item selector.
- Available quantity for selected item at the source branch.
- Quantity.
- Notes.

Source branch rules:

- Interdepartment source branch is the current user's branch.
- Interbranch source branch is the selected issuing branch.

Availability endpoint:

- First check whether stock request endpoints already return item availability.
- If not, consume Branch Stock for the source branch.
- If Branch Stock does not expose the required item/quantity clearly, tag Kamal and request the correct endpoint or response shape.

Likely existing frontend pieces:

- Branch stock bloc/repository/model already exist under `lib/src/features/stock_control`.
- `RequestStockScreen` already loads branch stock for the current branch.
- For interbranch, update it to reload branch stock when Procurement selects the issuing branch.

Expected availability behavior:

- When user selects an item, show available quantity and unit.
- If requested quantity is greater than available quantity, warn or block based on backend/business rule.
- The requester should know before submitting whether the source branch has enough stock.

Backend payload:

Interdepartment:

```json
{
  "requestingBranchId": "current-branch-id",
  "requestedBy": "employee-id",
  "department": "Kitchen",
  "notes": "",
  "items": []
}
```

Interbranch:

```json
{
  "requestingBranchId": "current-branch-id",
  "issuingBranchId": "external-branch-id",
  "requestedBy": "employee-id",
  "department": "Procurement",
  "notes": "",
  "items": []
}
```

### Step 5: Update Stock Request List / History

Existing screen:

- `lib/src/features/processing/presentation/stock_req_history.dart`

Required behavior:

- Show request type where available.
- Show status accurately.
- Show requesting branch.
- Show issuing branch only for interbranch.
- Add filters if backend supports them:
  - All
  - Pending
  - Approved
  - Processing
  - In Transit
  - Completed
  - Rejected/Cancelled

For Procurement:

- Add an outgoing interbranch view:

```text
Requests my branch made to external branches
```

Query needed:

```text
requestingBranchId = currentBranchId
requestType = INTERBRANCH
```

or:

```text
branchId = currentBranchId
requestType = INTERBRANCH
direction = OUTGOING
```

Exact query depends on backend support.

### Step 6: Update Stock Request Details

Existing screen:

- `lib/src/features/processing/presentation/stock_req_details.dart`

Required behavior:

- Show interdepartment/interbranch label.
- Show requesting branch.
- Show issuing branch only for interbranch.
- Show requested quantity and sent quantity.
- Show approval information.
- Show dispatch/receipt status for interbranch where available.

Action rules:

- Do not show direct approve action.
- Do not show manual complete for interbranch.
- Show complete only for interdepartment when backend allows it.

### Step 7: Update Stock Control Fulfillment

Existing screen:

- `lib/src/features/stock_control/presentation/complete_stock_reqs.dart`

This screen should support two work queues:

1. Internal branch requests

```text
Departments in my branch requested stock from my Stock Control
```

2. External branch requests

```text
Other branches requested stock from my branch
```

Required behavior:

- Internal requests can be queued, processed, and completed.
- External interbranch requests can be queued, processed, and dispatched.
- External interbranch requests should not be completed manually.
- External interbranch dispatch moves status to `IN_TRANSIT`.

Query needed for external requests:

```text
issuingBranchId = currentBranchId
requestType = INTERBRANCH
```

or:

```text
branchId = currentBranchId
requestType = INTERBRANCH
direction = INCOMING
```

Exact query depends on backend support.

### Step 8: Add Or Wire Interbranch Dispatch

Backend endpoint from document:

```text
PATCH /stock-requests/:id/dispatch
```

Payload example:

```json
{
  "dispatchItems": [
    {
      "itemId": "item-id",
      "qtySent": 20,
      "shortfallReason": "INTERNAL_USE_RETAINED",
      "shortfallNote": "Kept 20 units for service"
    }
  ]
}
```

Required behavior:

- Dispatch only interbranch requests.
- Dispatch only when status is `PROCESSING`.
- If `qtySent` is less than requested, require `shortfallReason`.
- On success, request becomes `IN_TRANSIT`.

### Step 9: Approval Workflow Integration

Current risk:

- Existing stock request action enum includes direct approve.
- Document says direct approve endpoint should be avoided.

Required behavior:

- Remove/hide direct approve button from stock request UI.
- Use approval workflow screen/endpoints only.
- If approval workflow endpoints are not available in frontend, log it as a blocker.

Backend question:

- What endpoint lists approval workflow entries for stock requests?
- What endpoint approves/rejects the stock request approval workflow item?

### Step 10: Interbranch Receipt Boundary

This is related but lower priority unless needed for tomorrow's full interbranch closure.

Rules:

- Interbranch completion should happen through Goods Received.
- Goods Received must include `stockRequestId`.
- Goods Received must not include both `purchaseOrderId` and `stockRequestId`.
- Goods Received should use procurement goods-received endpoints.

For tomorrow:

- At minimum, frontend should not manually complete interbranch requests.
- If receipt UI is not ready, the request can stop at `IN_TRANSIT` and be marked as a known remaining task.

### Step 11: Testing Pass

Run tests manually by role/department:

- Kitchen interdepartment request.
- Processing interdepartment request.
- POS/Sales interdepartment request.
- Procurement interdepartment request.
- Procurement interbranch request.
- Stock Control internal fulfillment.
- Stock Control external branch dispatch.
- Approval workflow approve/reject.
- Interbranch manual complete blocked.

### Step 12: Report Blockers

For every blocker, report:

- User department/role.
- Screen.
- Action attempted.
- Endpoint.
- Payload.
- Backend response.
- Whether it is frontend, backend, or unclear.

### 1. Create Stock Request

Purpose:

- Let users request stock items.

Expected behavior:

- User can search/select items.
- User can enter quantity.
- User can add notes.
- All departments can create interdepartment stock requests.
- Procurement can choose interdepartment or interbranch.
- Non-procurement departments should not see interbranch creation controls.
- Interdepartment requests should submit without `issuingBranchId`.
- Interbranch requests should require `issuingBranchId`.

### 2. Stock Request List / History

Purpose:

- Show requests relevant to the logged-in user, department, branch, or role.

Expected behavior:

- Show request ID.
- Show request status.
- Show requested items and quantities.
- Show request type where available.
- Support useful filters such as pending, approved, processing, in transit, completed, rejected, and cancelled.

### 3. Stock Request Details

Purpose:

- Show the full request record and available next actions.

Expected behavior:

- Show requester.
- Show department.
- Show requesting branch.
- Show issuing branch only for interbranch requests.
- Show items, requested quantities, sent quantities where available.
- Show status timeline or status metadata.
- Hide direct approval action from this screen if approval workflow is required.

### 4. Stock Control Fulfillment Screen

Purpose:

- Let Stock Control process incoming interdepartment stock requests.

Expected behavior:

- Stock Control can see incoming requests.
- Stock Control can move approved requests into queue.
- Stock Control can process requests.
- Stock Control can complete interdepartment requests.
- Completion should deduct stock from the branch.

### 5. Approval Workflow Screen

Purpose:

- Let approvers approve or reject stock requests.

Expected behavior:

- Stock requests should be approved only through approval workflow.
- The direct stock request approve endpoint should not be used from the frontend.
- Approval should keep both approval workflow and stock request records in sync.

### 6. Interbranch Dispatch Screen

Purpose:

- Let the issuing branch dispatch approved interbranch stock requests.

Expected behavior:

- Only applies to interbranch requests.
- Confirms quantities being sent.
- Allows sending less than requested only when a shortfall reason is provided.
- Moves the request to `IN_TRANSIT`.
- Deducts stock from issuing branch.

### 7. Interbranch Receipt Hook

Purpose:

- Confirm stock physically arrived at the requesting branch.

Expected behavior:

- Goods received record must include `stockRequestId`.
- Goods received should not include both `purchaseOrderId` and `stockRequestId`.
- Receipt should use procurement goods-received endpoints.
- This may be tested later if not part of tomorrow's deployment UI.

## Status Lifecycle

### Interdepartment

```text
PENDING -> APPROVED -> IN_QUEUE -> PROCESSING -> COMPLETED
```

Notes:

- Stock is deducted when completed.
- No Goods Received record is needed.
- `issuingBranchId` should remain empty.

### Interbranch

```text
PENDING -> APPROVED -> IN_QUEUE -> PROCESSING -> IN_TRANSIT -> GOODS_RECEIVED -> COMPLETED
```

Notes:

- Stock is deducted from issuing branch at dispatch.
- Stock is credited to requesting branch at receipt.
- Completion should happen through Goods Received, not direct complete.

## Test Cases

### Create Stock Request

- Kitchen can create an interdepartment stock request.
- Processing can create an interdepartment stock request.
- POS or Sales can create an interdepartment stock request.
- Procurement can create an interdepartment stock request.
- Procurement can create an interbranch stock request.
- Non-procurement users cannot create an interbranch stock request.
- Interdepartment request submits without `issuingBranchId`.
- Interbranch request requires `issuingBranchId`.
- Interbranch request fails if `issuingBranchId` equals `requestingBranchId`.
- Request cannot be submitted with no items.
- Request cannot be submitted with zero quantity.
- Request cannot be submitted with negative quantity.
- Notes are optional.

### Approval Workflow

- New stock request starts as `PENDING`.
- Approval workflow entry is created for the stock request.
- Approving through workflow changes stock request to `APPROVED`.
- Rejecting through workflow marks the stock request as rejected.
- Frontend does not call direct `PATCH /stock-requests/:id/approve`.
- Direct approve button is hidden or disabled in stock request screens.

### Interdepartment Lifecycle

- Approved request can move to `IN_QUEUE`.
- Queued request can move to `PROCESSING`.
- Processing interdepartment request can move to `COMPLETED`.
- Completing interdepartment request deducts stock from the same branch.
- Interdepartment request does not require Goods Received.
- Interdepartment request does not send `issuingBranchId`.

### Interbranch Lifecycle

- Procurement can select another branch as issuing branch.
- Interbranch request moves from `PENDING` to `APPROVED` through approval workflow.
- Approved interbranch request can move to `IN_QUEUE`.
- Queued interbranch request can move to `PROCESSING`.
- Processing interbranch request can be dispatched to `IN_TRANSIT`.
- Dispatch deducts stock from issuing branch.
- Dispatch fails if issuing branch has insufficient stock.
- Reduced dispatch quantity requires `shortfallReason`.
- Interbranch request cannot be manually completed from stock request screen.
- Interbranch request should complete only after receipt is logged with `stockRequestId`.

### Goods Received Rules For Interbranch

- Goods received can reference `stockRequestId`.
- Goods received can reference `purchaseOrderId`.
- Goods received cannot reference both `stockRequestId` and `purchaseOrderId`.
- Interbranch stock receipt must include `stockRequestId`.
- Receipt branch must match the requesting branch.
- Goods received should use procurement goods-received endpoints.

### Error Reporting

For any blocker, report:

- Department or user role used.
- Screen where the issue happened.
- Endpoint called.
- Payload sent.
- Backend response.
- Whether the issue appears frontend-side or backend-side.

## Priority Checklist For Tomorrow

- Interdepartment stock request works across departments.
- Procurement-only interbranch creation is scoped correctly.
- Approval workflow is used for stock request approval.
- Direct stock request approve endpoint is not used from frontend.
- Status transitions match Kamal's document.
- Stock request list and details screens are stable.
- Interdepartment requests leave issuing branch empty.
- Interbranch requests require a different issuing branch.
- Manual complete is blocked for interbranch requests.
- Backend blockers are documented and shared with the team.
