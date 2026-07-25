# M1 API Blockers

Review date: 2026-07-25  
Environment: staging  
Reference: `hdl:245680`, `pid:24453`

## Security Note

The app logs may include bearer token/JWT text. Do not paste full tokens into tickets, screenshots, or docs. If a token was shared outside the secure team channel, rotate/revoke it and log in again to generate a fresh token.

## Current Test Status

### Working

These flows were confirmed working from the staging app logs:

- Chat rooms load successfully.
  - Endpoint: `GET /chat/rooms?includeArchived=false&starredOnly=false`
  - Evidence: app log shows `Loaded 4 chat rooms`.
- View branch stock / stock details works.
  - Endpoint: `GET /branch-stock/cms0sakxw00p8mu2iqq32ej2w`
  - Evidence: response message is `Stock retrieved successfully`.
  - Returned stock state includes `currentStock: 59`, `status: IN_STOCK`, `allowNegativeStock: false`, and `isLocked: false`.
- Stock adjustment works.
  - Endpoint: `PATCH /branch-stock/{id}/adjust`
  - Evidence: confirmed manually from staging test.
- Delete branch stock works.
  - Endpoint: `DELETE /branch-stock/{id}`
  - Evidence: confirmed manually from staging test.

### Blocked

These flows are blocked by backend/user permission:

- Lock stock item.
  - Endpoint: `PATCH /branch-stock/{id}/lock`
  - Result: `403 Forbidden resource`.
- Unlock stock item.
  - Endpoint: `PATCH /branch-stock/{id}/unlock`
  - Result: not working in staging, likely same branch stock control permission issue.
- Allow negative stock.
  - Endpoint: `PATCH /branch-stock/{id}/allow-negative`
  - Result: `403 Forbidden resource`.
- Locked stock report.
  - Endpoint: `GET /branch-stock/locked`
  - Result: not accessible because of permission issue.
- Negative stock report.
  - Endpoint: `GET /branch-stock/negative-stock-report`
  - Result: not accessible because of permission issue.

### Fixed Mobile-Side Blocker

- Expiry tracking was showing demo data when staging returned no expiry records.
  - Endpoint: `GET /expiry/expiry-tracking/{branchId}/expiry-report`
  - Backend response: `200 OK` with `data.batches: []` and summary totals all `0`.
  - Previous result: app could show fake/demo expiry rows instead of the real empty state in dev.
  - Current result: demo fallback removed. The app now uses real API data only and shows `No expiring products found.` when the API returns an empty `batches` list.

## Blocker 1: Branch Stock Control Permissions Return 403

Status: Blocked by backend/user permissions

### Error Seen In App Logs

Lock stock:

```text
PATCH https://api-staging.sandwichai.co/branch-stock/cms0sakxw00p8mu2iqq32ej2w/lock
403 Forbidden
{"message":"Forbidden resource","error":"Forbidden","statusCode":403}
```

Allow negative stock:

```text
PATCH https://api-staging.sandwichai.co/branch-stock/cms0sakxw00p8mu2iqq32ej2w/allow-negative
403 Forbidden
{"message":"Forbidden resource","error":"Forbidden","statusCode":403}
```

### Affected Feature

Department: Stock Control

Screen:

- Stock item details screen

Files:

- UI: `lib/src/features/stock_control/presentation/branch_stock_details.dart`
- Bloc: `lib/src/features/stock_control/bloc/add_branch_stock_bloc/bloc.dart`
- Repository: `lib/src/features/stock_control/data/repo/add_branch_stock.dart`

### What Was Verified

The mobile app is calling the expected M1 endpoints:

```text
PATCH /branch-stock/{id}/lock
PATCH /branch-stock/{id}/allow-negative
```

The request is reaching staging, but the backend rejects the logged-in user/token with `403 Forbidden resource`.

### Impact

The Stock Control user cannot complete these branch stock control workflows from the mobile app. Confirmed blocked actions:

- `PATCH /branch-stock/{id}/lock`
- `PATCH /branch-stock/{id}/unlock`
- `PATCH /branch-stock/{id}/allow-negative`
- `GET /branch-stock/locked`
- `GET /branch-stock/negative-stock-report`

### Why This Is Blocked

There is no screen or flow in this mobile app for granting endpoint permissions to a user. This cannot be fixed from the Stock Control UI unless the backend already grants the required permission through the login role/token.

### Required Backend/Admin Action

1. Confirm the exact permission required for `PATCH /branch-stock/{id}/lock`.
2. Confirm the exact permission required for `PATCH /branch-stock/{id}/unlock`.
3. Confirm the exact permission required for `PATCH /branch-stock/{id}/allow-negative`.
4. Grant those permissions to the staging test user or the user role.
5. Confirm the exact permission required for `GET /branch-stock/locked`.
6. Confirm the exact permission required for `GET /branch-stock/negative-stock-report`.
7. Grant report permissions to the staging test user or the user role.
8. If possible, return a more specific 403 message, for example:

```text
Missing permission: branch-stock:lock
Missing permission: branch-stock:unlock
Missing permission: branch-stock:allow-negative
Missing permission: branch-stock:locked:read
Missing permission: branch-stock:negative-stock-report:read
```

### Retest Steps After Permission Is Granted

1. Log in to staging as the same Stock Control user.
2. Open Stock Control.
3. Open a branch stock item detail screen.
4. Tap the overflow menu.
5. Tap `Lock Item`.
6. Confirm the dialog.
7. Verify the request returns 200 or 2xx.
8. Confirm success snackbar appears.
9. Tap `Allow Negative Stock`.
10. Confirm the dialog.
11. Verify the request returns 200 or 2xx.
12. Confirm success snackbar appears.
13. Tap `Unlock Item`.
14. Confirm the dialog.
15. Verify the request returns 200 or 2xx.
16. Confirm success snackbar appears.
17. Refresh item details.
18. Open Stock Control drawer > `Reports` > `Locked Stock`.
19. Verify `GET /branch-stock/locked` returns 200 or 2xx.
20. Confirm the item is no longer locked after unlock, or confirm locked report reflects the latest backend state.
21. Open Stock Control drawer > `Reports` > `Negative Stock`.
22. Verify `GET /branch-stock/negative-stock-report` returns 200 or 2xx.
23. Confirm the negative stock report loads or shows a valid empty state.

Expected result: stock item locks successfully, allow-negative succeeds, unlock succeeds, locked stock report loads, negative stock report loads, and stock state/report data reflects the latest backend state.

## Fixed: Expiry Tracking Demo Fallback Removed

Status: Fixed in mobile

### Affected Feature

Department: Stock Control

Screen:

- Stock Control > Reports > Expiry

Files:

- UI: `lib/src/features/stock_control/presentation/stock_control_report_screens.dart`
- Cubit: `lib/src/features/stock_control/bloc/stock_control_reports_cubit/stock_control_reports_cubit.dart`
- Repository: `lib/src/features/stock_control/data/repo/stock_card_repo.dart`

### What Changed

The app no longer injects demo expiry rows when staging returns a successful empty expiry report. Expiry tracking now displays only real backend data.

Confirmed empty backend response shape:

```text
{
  message: Expiry report retrieved successfully,
  data: {
    summary: {
      total: 0,
      expiredNow: 0,
      expiringWithin7Days: 0,
      expiringWithin14Days: 0,
      expiringWithin30Days: 0,
      totalValueAtRisk: 0
    },
    batches: []
  },
  pagination: {
    total: 0,
    page: 1,
    limit: 50,
    totalPages: 0
  }
}
```

### Retest Steps

1. Log in to staging as a Stock Control user.
2. Open Stock Control.
3. Open Reports.
4. Open the Expiry tab.
5. Test with a branch that has expiry records.
6. Confirm real expiry rows are shown.
7. Test with a branch/date filter that returns `200 OK` and `data.batches: []`.
8. Confirm the app shows `No expiring products found.` and does not show demo rows.
