# Search Debounce Implementation Plan

## Goal

Add consistent debounce behavior to search fields across the app so searches do not run on every keystroke.

This should improve performance, reduce unnecessary API calls, and prevent search results from flickering while users type.

## Recommended Debounce Delay

Use one standard delay across the app:

```dart
const Duration(milliseconds: 350)
```

This is short enough to feel responsive, but long enough to avoid firing many searches while the user is still typing.

## Step 1: Find All Search Inputs

Search commands used:

```bash
rg -n "hintText:.*Search|Search by|Search .*\\.\\.\\." lib/src -S
rg -n "Timer\\? .*Search|_searchDebounce|Debounce|Duration\\(milliseconds: (350|450)\\)" lib/src -S
rg -n "\\.add\\(Search|Search[A-Za-z]+\\(" lib/src/features lib/src/core -S
```

### First-Pass Search Inventory

These are the search inputs found during the first pass.

| Area | File | Search Type | Current Debounce |
| --- | --- | --- | --- |
| Procurement Requests | `lib/src/features/procurement/presentation/procurement_request.dart` | Local UI search state | None |
| Purchase Order History | `lib/src/features/procurement/presentation/order_list.dart` | Bloc/API search via `SearchOrders` | None |
| Supplier List | `lib/src/features/procurement/presentation/supplier_list.dart` | Bloc/API search via `SearchSuppliers` | None |
| Create Goods Received | `lib/src/features/procurement/presentation/create_good_recieved_proc.dart` | Supplier/item dialog search | Needs review |
| Branch Stock | `lib/src/features/stock_control/presentation/branch_stock.dart` | Bloc/local search via `SearchItems` | None |
| Add Items Catalogue | `lib/src/features/stock_control/presentation/add_items_catalogue_screen.dart` | Inventory item search | Existing manual `Timer`, 450ms |
| Processing Requisition | `lib/src/features/stock_control/presentation/processing_requsition.dart` | Inventory item search | Existing manual `Timer`, 450ms |
| Procurement Requisition | `lib/src/features/stock_control/presentation/precuremnt_req.dart` | Inventory item search | Existing manual `Timer`, 450ms |
| Create Waste Log | `lib/src/features/stock_control/presentation/create_waste_log.dart` | Inventory item search | Existing manual `Timer`, 450ms |
| Processing Request Stock | `lib/src/features/processing/presentation/req_stock.dart` | Inventory item search | Existing manual `Timer`, 350ms |
| Create Product Intake | `lib/src/features/processing/presentation/create_product_intake.dart` | Inventory item search | Existing manual `Timer`, 450ms |
| Create Processing Task | `lib/src/features/processing/presentation/create_processing_task.dart` | Bloc/local menu search via `SearchMenuItems` | None |
| Recipe Compliance | `lib/src/features/processing/presentation/recipe_compliance.dart` | Bloc/local menu search via `SearchMenuItems` | None |
| Recipe Calculator | `lib/src/features/processing/presentation/recipe_calc.dart` | Menu item dropdown search | Needs review |
| Product Intake History | `lib/src/features/processing/presentation/product_intake_history.dart` | Bloc/local search via `SearchProductIntakes` | None |
| Processing Tasks | `lib/src/features/processing/presentation/get_processing_tasks.dart` | Task search/filter | None |
| Create Output Verification | `lib/src/features/processing/presentation/create_output_ver.dart` | Local menu item search | None |
| POS Order Screen | `lib/src/features/pos/presentation/order_screen.dart` | Bloc/API menu search via `SearchMenuItems` | Existing manual `Timer`, 450ms |
| POS Customer Base | `lib/src/features/pos/presentation/customer_base.dart` | Bloc/API customer search via `SearchCustomers` | None |
| POS Payment Customer Lookup | `lib/src/features/pos/presentation/payment_method.dart` | API customer lookup | Existing manual `Timer`, 350ms |
| POS Reviews Order Lookup | `lib/src/features/pos/presentation/reviews.dart` | Order lookup | Existing manual `Timer`, 500ms |
| Chat Messages | `lib/src/core/globals/chat/chat.dart` | Bloc/API message search via `SearchMessages` | None |

### Existing Search Events Found

These Bloc events should be reviewed when applying debounce:

- `SearchOrders`
- `SearchSuppliers`
- `SearchItems`
- `SearchStockCategories`
- `SearchStockMovements`
- `SearchProductIntakes`
- `SearchMenuItems`
- `SearchEmployees`
- `SearchCustomers`
- `SearchKitchenOrders`
- `SearchMessages`

### Notes

- Some screens already use manual `Timer` debounce. Replace those with the shared `Debouncer` helper for consistency.
- Some searches are local-only and cheap, but should still use the same helper to make the typing behavior consistent.
- API-backed searches should be prioritized first because they create network load.
- Files with `Needs review` have search UI, but the exact filtering path should be inspected before editing.

## Step 2: Create Shared Debouncer Helper

Create:

```text
lib/src/core/utils/debouncer.dart
```

Status: implemented.

Suggested implementation:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';

class Debouncer {
  Debouncer({required this.delay});

  final Duration delay;
  Timer? _timer;

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}
```

## Step 3: Use Debouncer In Each Search Screen

Status: implemented for the first rollout.

Screens updated to use `lib/src/core/utils/debouncer.dart`:

- `lib/src/features/procurement/presentation/procurement_request.dart`
- `lib/src/features/procurement/presentation/order_list.dart`
- `lib/src/features/procurement/presentation/supplier_list.dart`
- `lib/src/features/stock_control/presentation/branch_stock.dart`
- `lib/src/features/stock_control/presentation/add_items_catalogue_screen.dart`
- `lib/src/features/stock_control/presentation/processing_requsition.dart`
- `lib/src/features/stock_control/presentation/precuremnt_req.dart`
- `lib/src/features/stock_control/presentation/create_waste_log.dart`
- `lib/src/features/processing/presentation/req_stock.dart`
- `lib/src/features/processing/presentation/product_intake_history.dart`
- `lib/src/features/processing/presentation/get_processing_tasks.dart`
- `lib/src/features/processing/presentation/create_product_intake.dart`
- `lib/src/features/processing/presentation/create_processing_task.dart`
- `lib/src/features/processing/presentation/recipe_compliance.dart`
- `lib/src/features/pos/presentation/customer_base.dart`
- `lib/src/features/pos/presentation/order_screen.dart`
- `lib/src/features/pos/presentation/payment_method.dart`
- `lib/src/features/pos/presentation/reviews.dart`
- `lib/src/core/globals/chat/chat.dart`

Add a field:

```dart
late final Debouncer _searchDebouncer;
```

Initialize it:

```dart
@override
void initState() {
  super.initState();
  _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 350),
  );
}
```

Dispose it:

```dart
@override
void dispose() {
  _searchDebouncer.dispose();
  _searchController.dispose();
  super.dispose();
}
```

## Step 4: Apply To Local List Search

Status: implemented for the first rollout.

Debounced local list search paths:

- `lib/src/features/procurement/presentation/procurement_request.dart`
- `lib/src/features/procurement/presentation/create_good_recieved_proc.dart`
  - supplier picker dialog
  - item picker dialog
- `lib/src/features/processing/presentation/recipe_calc.dart`
- `lib/src/features/processing/presentation/create_output_ver.dart`

Hybrid local/API inventory pickers also use the shared debouncer for the API search call while keeping local cached results responsive:

- `lib/src/features/stock_control/presentation/add_items_catalogue_screen.dart`
- `lib/src/features/stock_control/presentation/processing_requsition.dart`
- `lib/src/features/stock_control/presentation/precuremnt_req.dart`
- `lib/src/features/stock_control/presentation/create_waste_log.dart`
- `lib/src/features/processing/presentation/req_stock.dart`
- `lib/src/features/processing/presentation/create_product_intake.dart`

Reviewed but not changed:

- `lib/src/features/processing/presentation/processing_vaidate_stock_trf.dart`
  - It has a search listener, but the handler currently has no filtering logic.

For screens that filter an existing local list:

```dart
onChanged: (value) {
  _searchDebouncer(() {
    if (!mounted) return;
    setState(() {
      _searchQuery = value.trim();
    });
  });
}
```

## Step 5: Apply To API Or Bloc Search

Status: implemented for the first rollout.

Re-audit status: checked again after Step 4 local-search changes. Remaining direct API/Bloc calls are intentional immediate actions such as clear buttons, submitted search, initial loads, and non-text filters.

Debounced API/Bloc search paths:

- `SearchOrders` in `lib/src/features/procurement/presentation/order_list.dart`
- `SearchSuppliers` in `lib/src/features/procurement/presentation/supplier_list.dart`
- `SearchItems` in `lib/src/features/stock_control/presentation/branch_stock.dart`
- `LoadInventoryItems(search: ...)` in inventory picker forms:
  - `lib/src/features/stock_control/presentation/add_items_catalogue_screen.dart`
  - `lib/src/features/stock_control/presentation/processing_requsition.dart`
  - `lib/src/features/stock_control/presentation/precuremnt_req.dart`
  - `lib/src/features/stock_control/presentation/create_waste_log.dart`
  - `lib/src/features/processing/presentation/req_stock.dart`
  - `lib/src/features/processing/presentation/create_product_intake.dart`
- `SearchProductIntakes` in `lib/src/features/processing/presentation/product_intake_history.dart`
- `FilterProcessingTasks` from search input in `lib/src/features/processing/presentation/get_processing_tasks.dart`
- `SearchMenuItems` in:
  - `lib/src/features/processing/presentation/create_processing_task.dart`
  - `lib/src/features/processing/presentation/recipe_compliance.dart`
  - `lib/src/features/pos/presentation/order_screen.dart`
- `SearchCustomers` in `lib/src/features/pos/presentation/customer_base.dart`
- customer lookup API search in `lib/src/features/pos/presentation/payment_method.dart`
- order lookup API search in `lib/src/features/pos/presentation/reviews.dart`
- `SearchMessages` in `lib/src/core/globals/chat/chat.dart`

Intentional immediate calls:

- Clear buttons cancel debounce and reset results immediately.
- Submitted search actions run immediately.
- Initial data loads run immediately.
- Non-text filter changes run immediately.

For screens that call an API or dispatch a Bloc event:

```dart
onChanged: (value) {
  final query = value.trim();

  _searchDebouncer(() {
    if (!mounted) return;

    if (query.isEmpty) {
      context.read<OrdersListBloc>().add(const LoadOrders());
    } else {
      context.read<OrdersListBloc>().add(SearchOrders(query));
    }
  });
}
```

## Step 6: Make Clear Button Immediate

Status: implemented for the first rollout.

Clear/reset behavior now follows this pattern:

- cancel pending debouncer
- clear the controller
- reset local search text or filtered list immediately
- dispatch clear/reload events immediately where applicable

Additional Step 6 cleanup applied to:

- `lib/src/features/stock_control/presentation/add_items_catalogue_screen.dart`
- `lib/src/features/stock_control/presentation/processing_requsition.dart`
- `lib/src/features/stock_control/presentation/precuremnt_req.dart`
- `lib/src/features/stock_control/presentation/create_waste_log.dart`
- `lib/src/features/processing/presentation/req_stock.dart`
- `lib/src/features/processing/presentation/create_product_intake.dart`
- `lib/src/features/processing/presentation/create_output_ver.dart`

Clear should not wait for debounce.

```dart
onPressed: () {
  _searchDebouncer.cancel();
  _searchController.clear();

  setState(() {
    _searchQuery = '';
  });

  context.read<OrdersListBloc>().add(const LoadOrders());
}
```

For local list search, the reload event can be replaced with local reset logic.

## Step 7: Avoid Context After Delay Bugs

Status: implemented for the first rollout.

Because debounce runs later, always check:

```dart
if (!mounted) return;
```

before:

- `setState`
- `context.read`
- `Navigator`
- `ScaffoldMessenger`

Audit result:

- Screen-level debounced callbacks now check `mounted` before running UI work.
- Dialog-level debounced searches in `create_good_recieved_proc.dart` use a `dialogOpen` flag before calling `StatefulBuilder` setters.
- Clear buttons cancel pending debounce immediately, so an old delayed search cannot restore stale text/results after clear.

## Step 8: Rollout Order

Status: rollout code changes completed for the first pass.

Rollout order used:

1. Completed: Add shared `Debouncer` helper.
2. Completed: Update Procurement Requests search.
3. Completed: Update Purchase Order History search.
4. Completed: Update Supplier List search.
5. Completed: Update Goods Received search.
6. Completed: Update Branch Stock and Stock Control searches.
7. Completed: Update Processing searches.
8. Completed: Update POS searches.
9. Completed: Run targeted analyzer checks after each group.
10. Pending final release check: build dev and staging debug APKs after Step 9 manual testing.

Keep this rollout order for future screens:

1. Add or reuse the shared debounce helper.
2. Debounce API and Bloc searches first.
3. Debounce local list filtering only where typing causes heavy rebuilds.
4. Make clear/reset buttons immediate.
5. Add `mounted` or dialog-open guards for every delayed callback.
6. Run analyzer on touched files.
7. Manually test typing, clearing, navigation, and tab switching.

## Step 9: Testing Checklist

Status: ready for manual QA.

For each updated screen:

- Type quickly and confirm search waits until typing stops.
- Confirm only the latest query is used.
- Clear the search field and confirm results reset immediately.
- Navigate away while typing and confirm no crash.
- Switch tabs while debounce is waiting and confirm no stale result crash.
- Confirm API searches do not fire on every keystroke.
- Confirm local searches still feel responsive.

Screen groups to test:

- Procurement: requests, purchase order history, suppliers, goods received supplier/item dialogs.
- Stock Control: branch stock, add catalogue item, processing requisition, procurement request, waste log.
- Processing: request stock, product intake history, processing tasks, product intake item picker, processing task item search, output verification, recipe compliance, recipe calculator.
- POS: customer base, order screen menu search, payment email customer search, reviews order lookup.
- Chat: chat search.

Pass criteria:

- Fast typing should trigger one final search after the delay, not one search per key press.
- Clearing the field should reset immediately without waiting for the delay.
- Leaving the screen while a debounce is waiting should not show a Flutter error.
- Closing a search dialog while a debounce is waiting should not show a Flutter error.
- API or Bloc logs should show fewer search calls during fast typing.
- Local list searches should still update correctly after the delay.

Suggested manual test flow:

1. Open the screen.
2. Type at least five characters quickly.
3. Wait for the debounce delay and confirm the final result matches the full text.
4. Clear the field and confirm the list resets immediately.
5. Type again and leave the screen before the delay finishes.
6. Reopen the screen and confirm there is no stale search result or crash.
7. Repeat the same flow for dialog search fields, then close the dialog before the delay finishes.

## Future Improvement

After all screens use the same debounce helper, consider creating a reusable widget:

```text
DebouncedSearchField
```

That widget can standardize:

- prefix search icon
- clear button
- border styling
- debounce delay
- clear behavior
- text field padding

This should only be done after the first rollout, once the repeated patterns are clear.
