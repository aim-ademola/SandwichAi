# Stock Control Report Endpoint Test Results

Test date: 2026-07-27  
Environment: Staging  
Base URL: `https://api-staging.sandwichai.co`  
Login user: `hybiekay2+3@gmail.com`  
Department: `STOCK_CONTROL`  
Branch: `Head Office`  
Branch ID: `cmiir5erp0002fj4sorxk7668`

Note: The auth token was attached for every request. Token value is intentionally not included here.

## Summary

| Area | Endpoint | Status | Result |
| --- | --- | --- | --- |
| Expiry report, branch path, 30 days | `GET /expiry/expiry-tracking/{branchId}/expiry-report?withinDays=30&includeExpired=true` | `200 OK` | Works, but returns empty batches |
| Expiry report, query path, 30 days | `GET /expiry/expiry-tracking?branchId={branchId}&withinDays=30&includeExpired=true` | `200 OK` | Works, but returns empty batches |
| Expiry summary | `GET /expiry/expiry-tracking/analytics/expiry-summary?branchId={branchId}` | `200 OK` | Works, shows 1 active batch and no expiring batches |
| Expiry report, branch path, 60 days | `GET /expiry/expiry-tracking/{branchId}/expiry-report?withinDays=60&includeExpired=true` | `200 OK` | Works, but returns empty batches |
| Expiry report, query path, 60 days | `GET /expiry/expiry-tracking?branchId={branchId}&withinDays=60&includeExpired=true` | `200 OK` | Works, but returns empty batches |
| Locked stock report | `GET /branch-stock/locked?branchId={branchId}` | `403 Forbidden` | Backend permission issue |
| Negative stock report | `GET /branch-stock/negative-stock-report?branchId={branchId}` | `403 Forbidden` | Backend permission issue |

## 1. Expiry Report - Branch Path, 30 Days

Request:

```http
GET https://api-staging.sandwichai.co/expiry/expiry-tracking/cmiir5erp0002fj4sorxk7668/expiry-report?withinDays=30&includeExpired=true
Authorization: Bearer <token>
Accept: application/json
```

Status:

```text
200 OK
```

Response:

```json
{
  "message": "Expiry report retrieved successfully",
  "data": {
    "summary": {
      "total": 0,
      "expiredNow": 0,
      "expiringWithin7Days": 0,
      "expiringWithin14Days": 0,
      "expiringWithin30Days": 0,
      "totalValueAtRisk": 0
    },
    "batches": []
  },
  "pagination": {
    "total": 0,
    "page": 1,
    "limit": 50,
    "totalPages": 0
  }
}
```

## 2. Expiry Report - Query Path, 30 Days

Request:

```http
GET https://api-staging.sandwichai.co/expiry/expiry-tracking?branchId=cmiir5erp0002fj4sorxk7668&withinDays=30&includeExpired=true
Authorization: Bearer <token>
Accept: application/json
```

Status:

```text
200 OK
```

Response:

```json
{
  "message": "Expiry report retrieved successfully",
  "data": {
    "summary": {
      "total": 0,
      "expiredNow": 0,
      "expiringWithin7Days": 0,
      "expiringWithin14Days": 0,
      "expiringWithin30Days": 0,
      "totalValueAtRisk": 0
    },
    "batches": []
  },
  "pagination": {
    "total": 0,
    "page": 1,
    "limit": 50,
    "totalPages": 0
  }
}
```

## 3. Expiry Summary

Request:

```http
GET https://api-staging.sandwichai.co/expiry/expiry-tracking/analytics/expiry-summary?branchId=cmiir5erp0002fj4sorxk7668
Authorization: Bearer <token>
Accept: application/json
```

Status:

```text
200 OK
```

Response:

```json
{
  "message": "Expiry summary retrieved successfully",
  "data": {
    "totalActiveBatches": 1,
    "expiredNow": 0,
    "expiringWithin7Days": 0,
    "expiringWithin14Days": 0,
    "expiringWithin30Days": 0,
    "expiringWithin60Days": 0,
    "totalValueAtRisk": 0,
    "healthStatus": "HEALTHY"
  }
}
```

## 4. Expiry Report - Branch Path, 60 Days

Request:

```http
GET https://api-staging.sandwichai.co/expiry/expiry-tracking/cmiir5erp0002fj4sorxk7668/expiry-report?withinDays=60&includeExpired=true
Authorization: Bearer <token>
Accept: application/json
```

Status:

```text
200 OK
```

Response:

```json
{
  "message": "Expiry report retrieved successfully",
  "data": {
    "summary": {
      "total": 0,
      "expiredNow": 0,
      "expiringWithin7Days": 0,
      "expiringWithin14Days": 0,
      "expiringWithin30Days": 0,
      "totalValueAtRisk": 0
    },
    "batches": []
  },
  "pagination": {
    "total": 0,
    "page": 1,
    "limit": 50,
    "totalPages": 0
  }
}
```

## 5. Expiry Report - Query Path, 60 Days

Request:

```http
GET https://api-staging.sandwichai.co/expiry/expiry-tracking?branchId=cmiir5erp0002fj4sorxk7668&withinDays=60&includeExpired=true
Authorization: Bearer <token>
Accept: application/json
```

Status:

```text
200 OK
```

Response:

```json
{
  "message": "Expiry report retrieved successfully",
  "data": {
    "summary": {
      "total": 0,
      "expiredNow": 0,
      "expiringWithin7Days": 0,
      "expiringWithin14Days": 0,
      "expiringWithin30Days": 0,
      "totalValueAtRisk": 0
    },
    "batches": []
  },
  "pagination": {
    "total": 0,
    "page": 1,
    "limit": 50,
    "totalPages": 0
  }
}
```

## 6. Locked Stock Report

Request:

```http
GET https://api-staging.sandwichai.co/branch-stock/locked?branchId=cmiir5erp0002fj4sorxk7668
Authorization: Bearer <token>
Accept: application/json
```

Status:

```text
403 Forbidden
```

Response:

```json
{
  "message": "Forbidden resource",
  "error": "Forbidden",
  "statusCode": 403
}
```

## 7. Negative Stock Report

Request:

```http
GET https://api-staging.sandwichai.co/branch-stock/negative-stock-report?branchId=cmiir5erp0002fj4sorxk7668
Authorization: Bearer <token>
Accept: application/json
```

Status:

```text
403 Forbidden
```

Response:

```json
{
  "message": "Forbidden resource",
  "error": "Forbidden",
  "statusCode": 403
}
```

## Notes For Backend Review

Expiry report endpoints are working at HTTP level, but they return no batches. The summary says `totalActiveBatches` is `1`, and all expiry windows are zero up to 60 days. This suggests the active batch may not be expired or expiring soon, or the report endpoint is filtering it out.

Locked stock and negative stock report endpoints return `403 Forbidden` for the Stock Control test user, even when the request is scoped to the user's branch with `branchId`.
