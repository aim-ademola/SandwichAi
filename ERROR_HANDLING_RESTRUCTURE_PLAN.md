# Error Handling Restructure Plan

Date: 23 June 2026

## Goal

Restructure mobile API error handling so the app shows the real backend error whenever the backend provides one, instead of replacing it with generic messages like `Something went wrong`, `Failed to load data`, or `Please try again later`.

The mobile app should only create fallback messages for true client-side failures such as no internet, timeout, cancelled request, invalid local file type, or response parsing failure.

## Current Findings

- `ApiClient` already centralizes HTTP calls in `lib/src/core/network/api_engine_private/api_client.dart`.
- `ApiClient._extractErrorMessage()` currently reads `message`, `error`, and `detail`, but it does not fully handle validation arrays or nested backend payloads.
- `ApiClient._handleHttpError()` preserves backend messages for many 4xx responses, but server errors like `500`, `502`, `503`, and `504` are converted to generic messages.
- Many repositories and BLoCs still add their own generic fallback text after the shared client has already parsed the backend response.
- The Swagger docs at `https://lionfish-app-o5cz2.ondigitalocean.app/docs` use `/openapi.json`. The documented validation shape includes `detail: [{ loc, msg, type, input, ctx }]`, so the app needs to parse `detail` arrays and surface their `msg` values.

## Target Error Contract

Create one normalized app error shape and use it everywhere:

```dart
class ApiErrorDetails {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic raw;
  final List<FieldError> fieldErrors;
}

class FieldError {
  final String field;
  final String message;
  final String? type;
}
```

Then update `NetworkException` to carry:

- `message`: user-facing backend message when available.
- `statusCode`: HTTP status code.
- `type`: network/application category.
- `data` or `raw`: original backend error payload.
- `fieldErrors`: validation details from backend where available.

## Backend Error Parsing Rules

The shared parser should extract messages in this order:

1. `message` string.
2. `message` list, joined into readable lines.
3. `error` string.
4. `detail` string.
5. `detail` list of FastAPI validation errors, using each item `msg`.
6. Nested `data.message`, `data.error`, or `errors`.
7. Raw string response.
8. Local fallback only if backend gave no useful message.

For FastAPI validation errors:

```json
{
  "detail": [
    {
      "loc": ["body", "message"],
      "msg": "Field required",
      "type": "missing"
    }
  ]
}
```

The mobile message should become:

```text
message: Field required
fieldErrors: [{ field: "message", message: "Field required", type: "missing" }]
```

## Implementation Steps

### 1. Add a Shared Backend Error Parser

Create:

```text
lib/src/core/network/api_engine_private/backend_error_parser.dart
```

Responsibilities:

- Accept `dynamic responseData` and `int? statusCode`.
- Return `ApiErrorDetails`.
- Preserve the raw backend payload.
- Convert backend validation arrays into `FieldError`.
- Avoid generic copy if backend supplied any useful message.

### 2. Upgrade `NetworkException`

Update:

```text
lib/src/core/network/api_engine_private/network_exception.dart
```

Changes:

- Add `rawData`.
- Add `fieldErrors`.
- Add optional `code`.
- Add factory like `NetworkException.fromBackend(ApiErrorDetails details)`.
- Keep existing factories for no internet, timeout, cancellation, bad certificate, and format errors.

### 3. Update `ApiClient`

Update:

```text
lib/src/core/network/api_engine_private/api_client.dart
```

Changes:

- Replace `_extractErrorMessage()` with `BackendErrorParser.parse()`.
- For every HTTP status, including `500`, preserve backend message if available.
- Do not convert server errors to generic text unless backend response has no message at all.
- Ensure Dio `badResponse` stores `response.data` inside `NetworkException`.

### 4. Remove Repository-Level Generic Error Overrides

Audit repositories for patterns like:

```dart
return ApiResponse.errorMessage('Failed to load orders. Please try again later.');
return ApiResponse.errorMessage(_parseErrorMessage(e.toString()));
```

Replace with:

```dart
return ApiResponse.error(error);
```

or let `ApiClient` return the `ApiResponse` directly.

Priority modules:

1. Auth repositories.
2. POS order/payment/menu repositories.
3. Procurement repositories.
4. Processing repositories.
5. Stock control repositories.
6. Chat repositories.

### 5. Keep Local Validation Local

Local validation should still happen before API calls, but it should be clearly separated from backend errors.

Examples:

- Invalid file type.
- Missing required local form field before submit.
- No selected branch.
- No internet.
- Request timeout.

These can remain app-generated messages.

### 6. Update BLoCs To Pass Through Backend Errors

BLoCs should not replace repository errors with generic text.

Preferred pattern:

```dart
response.when(
  success: (data) => emit(Success(data)),
  error: (error) => emit(Failure(error: error)),
);
```

If existing states only accept `String`, migrate risky modules first to hold `NetworkException` or `ApiErrorDetails`.

### 7. Update UI Display

For simple screens:

- Show `error.message`.

For form screens:

- Show `error.message`.
- If `fieldErrors` is not empty, map field-specific backend errors to the relevant input fields.

For debug builds:

- Log `statusCode`, `code`, and `rawData`.

For release builds:

- Do not expose stack traces or raw technical payloads directly to users.

### 8. Tests

Add parser tests for:

- `{ "message": "Invalid credentials" }`
- `{ "message": ["email must be valid", "password is required"] }`
- `{ "error": "Unauthorized" }`
- `{ "detail": "Not found" }`
- `{ "detail": [{ "loc": ["body", "email"], "msg": "Invalid email", "type": "value_error" }] }`
- `{ "data": { "message": "Branch not found" } }`
- plain text response.
- empty/null response.

Then add one repository/BLoC test for each priority module after migration.

## Rollout Order

### Phase 1: Core Parser

- Add parser and model.
- Update `NetworkException`.
- Update `ApiClient`.
- Run analyzer.

### Phase 2: High-Impact Flows

- Login.
- Forgot/reset/change password.
- POS order/payment.
- Procurement order creation/drafts.
- Stock control requisitions.

### Phase 3: Remaining Modules

- Processing.
- Kitchen.
- Chat.
- Dashboard APIs.
- File uploads.

### Phase 4: UI Field Errors

- Add field-level backend error display to form-heavy pages.
- Start with auth, purchase order, stock request, and recipe compliance forms.

## Acceptance Criteria

- Backend-provided errors appear in UI exactly or cleanly formatted.
- Generic app messages are used only when the backend did not return a useful error.
- All API errors flow through one shared parser.
- Repositories stop duplicating backend error parsing.
- BLoCs preserve the parsed backend error object or at least its exact message.
- Validation errors from `/openapi.json` style `detail` arrays are shown as useful field messages.
- Analyzer does not introduce new hard errors.

## Example Desired Behavior

Backend response:

```json
{
  "detail": [
    {
      "loc": ["body", "message"],
      "msg": "Field required",
      "type": "missing"
    }
  ]
}
```

Mobile output:

```text
Field required
```

Not:

```text
Something went wrong. Please try again.
```

