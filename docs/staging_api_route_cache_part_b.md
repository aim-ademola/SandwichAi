# Staging API Route Cache: Part B

Source: `https://api-staging.sandwichai.co/api/docs-json`  
Fetched: 2026-07-25  
Reason: backend changed route paths for branch assignment, packaging config, and expiry tracking.

## Summary

The live staging docs confirm these route groups:

- Expiry tracking now uses `/expiry/expiry-tracking/...`
- Branch assignment uses `/inventory-items/branch-assignment/...`
- Packaging config uses `/inventory-items-packaging/...`

## Expiry Tracking

Implementation status: already using the live staging route base in `lib/src/features/stock_control/data/repo/stock_card_repo.dart`.

Routes:

- `GET /expiry/expiry-tracking`
  - Summary: Expiry report for items expiring within a time window.
  - Query: `branchId`, `itemId`, `withinDays`, `includeExpired`, `page`, `limit`
- `GET /expiry/expiry-tracking/analytics/expiry-summary`
  - Summary: Expiry summary for dashboard widget.
  - Query: `branchId`
- `GET /expiry/expiry-tracking/{branchId}/expiry-report`
  - Summary: Branch-specific expiry report.
  - Path: `branchId`
  - Query: `withinDays`, `includeExpired`
- `GET /expiry/expiry-tracking/{branchId}/{itemId}/batches`
  - Summary: Get all stock batches for an item at a branch.
  - Path: `branchId`, `itemId`
- `PATCH /expiry/expiry-tracking/{branchId}/{itemId}/batches/{batchId}`
  - Summary: Update a stock batch.
  - Path: `branchId`, `itemId`, `batchId`
  - Body: `UpdateBatchDto`

Note: the original PDF listed `/stock-cards/...` for expiry tracking, but the live staging docs now list `/expiry/expiry-tracking/...`.

## Branch Assignment

Implementation status: view-only mobile support added on the stock item detail screen. Mobile users can see where an item is available, but cannot assign or unassign branches.

Mobile location:

- Flow: `Stock Catalogue` > item detail > `Available in Branches`
- UI: `lib/src/features/stock_control/presentation/branch_stock_details.dart`
- Repository: `lib/src/features/stock_control/data/repo/branch_assignment_repo.dart`
- Model: `lib/src/features/stock_control/data/model/branch_assignment_model.dart`

Mobile route used:

- `GET /inventory-items/branch-assignment/{itemId}/branches`

Admin/manage routes are intentionally not exposed in mobile because admin does not use the mobile app.

Routes:

- `GET /inventory-items/branch-assignment/by-branch`
  - Summary: Get inventory items filtered by branch visibility.
  - Query: `branchId`, `category`, `search`, `page`, `limit`
- `GET /inventory-items/branch-assignment/{itemId}/branches`
  - Summary: Get all branch assignments for an inventory item.
  - Path: `itemId`
- `POST /inventory-items/branch-assignment/{itemId}/branches/assign`
  - Summary: Assign specific branches to an inventory item.
  - Path: `itemId`
  - Body: `AssignBranchesToItemDto`
- `POST /inventory-items/branch-assignment/{itemId}/branches/assign-all`
  - Summary: Assign inventory item to all branches, with optional exclusions.
  - Path: `itemId`
  - Body: `AssignAllBranchesToItemDto`
- `DELETE /inventory-items/branch-assignment/{itemId}/branches/unassign`
  - Summary: Unassign specific branches from an inventory item.
  - Path: `itemId`
  - Body: `UnassignBranchesFromItemDto`
- `DELETE /inventory-items/branch-assignment/{itemId}/branches/unassign-all`
  - Summary: Remove all branch assignments from an inventory item.
  - Path: `itemId`

### Branch Assignment DTOs

`AssignBranchesToItemDto`

- Required: `branchIds`
- `branchIds`: `List<String>`
- `replaceAll`: `bool`
- `notes`: `String`

`AssignAllBranchesToItemDto`

- Required: none
- `excludeBranchIds`: `List<String>`
- `notes`: `String`

`UnassignBranchesFromItemDto`

- Required: `branchIds`
- `branchIds`: `List<String>`

## Packaging Config

Implementation status: not found in current mobile code search. Add repository/model/bloc/UI as needed for Part B.

Routes:

- `POST /inventory-items-packaging/packaging/batch-lookup`
  - Summary: Get packaging configs for multiple items in one call.
  - Body: `BatchPackagingLookupDto`
- `GET /inventory-items-packaging/packaging/purchase-defaults`
  - Summary: Get purchase-default packaging config for every item in the org.
  - Query: `category`
- `POST /inventory-items-packaging/{itemId}/packaging`
  - Summary: Create a packaging configuration for an inventory item.
  - Path: `itemId`
  - Body: `CreatePackagingConfigDto`
- `GET /inventory-items-packaging/{itemId}/packaging`
  - Summary: List all packaging configurations for an inventory item.
  - Path: `itemId`
- `POST /inventory-items-packaging/{itemId}/packaging/convert`
  - Summary: Convert a quantity between packaging configs or to/from base unit.
  - Path: `itemId`
  - Body: `ConvertPackagingDto`
- `GET /inventory-items-packaging/{itemId}/packaging/defaults`
  - Summary: Get default packaging config for each context.
  - Path: `itemId`
- `GET /inventory-items-packaging/{itemId}/packaging/{configId}`
  - Summary: Get a single packaging configuration.
  - Path: `itemId`, `configId`
- `PATCH /inventory-items-packaging/{itemId}/packaging/{configId}`
  - Summary: Update a packaging configuration.
  - Path: `itemId`, `configId`
  - Body: `UpdatePackagingConfigDto`
- `DELETE /inventory-items-packaging/{itemId}/packaging/{configId}`
  - Summary: Delete a packaging configuration.
  - Path: `itemId`, `configId`
- `PATCH /inventory-items-packaging/{itemId}/packaging/{configId}/set-default`
  - Summary: Set this config as the default for one or more contexts.
  - Path: `itemId`, `configId`
  - Body: `SetDefaultPackagingDto`

### Packaging DTOs

`BatchPackagingLookupDto`

- Required: `itemIds`
- `itemIds`: `List<String>`

`CreatePackagingConfigDto`

- Required: `unitName`, `conversionFactor`
- `unitName`: `String`
- `abbreviation`: `String`
- `conversionFactor`: `num`
- `isDefaultForPurchase`: `bool`
- `isDefaultForReceipt`: `bool`
- `isDefaultForCounting`: `bool`
- `notes`: `String`

`ConvertPackagingDto`

- Required: `quantity`
- `quantity`: `num`
- `fromConfigId`: `String?`
- `toConfigId`: `String?`

`UpdatePackagingConfigDto`

- Required: none
- `unitName`: `String`
- `abbreviation`: `String`
- `conversionFactor`: `num`
- `isDefaultForPurchase`: `bool`
- `isDefaultForReceipt`: `bool`
- `isDefaultForCounting`: `bool`
- `isActive`: `bool`
- `notes`: `String`

`SetDefaultPackagingDto`

- Required: `contexts`
- `contexts`: `List<String>`
- Allowed context values from docs: `purchase`, `receipt`, `counting`

## Current Code Search Result

Found:

- Expiry tracking repo uses `/expiry/expiry-tracking/...`.
- Stock movement trends still correctly uses `/stock-cards/analytics/movement-trends`.

Not found:

- Branch assignment implementation.
- Packaging config implementation.

## Part B Implementation Notes

Recommended next files:

- Branch assignment view-only repository/model already added under `lib/src/features/stock_control/data/repo/` and `lib/src/features/stock_control/data/model/`.
- Add packaging config repository/model under `lib/src/features/stock_control/data/repo/` and `lib/src/features/stock_control/data/model/`.
- Wire repositories in `lib/src/core/constant/di/repository_providers.dart`.
- Add bloc/cubit providers in `lib/src/core/constant/di/stock_providers.dart`.
- Branch assignment UI is under Stock Catalogue / item details because it is inventory-item focused.
