import 'package:flutter/material.dart';
import 'package:sandwich_ai/main.dart';

/// Triggered when retry/sync starts
void showSyncStartSnackBar(BuildContext context, String message) {
  final messenger = rootScaffoldMessengerKey.currentState;
  messenger?.clearSnackBars();

  messenger?.showSnackBar(
    SnackBar(
      content: Row(
        children: const [
          Icon(Icons.sync, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Checking and Syncing pending requests...",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.blue.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Triggered when retry/sync succeeds
void showSyncSuccessSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: const [
          Icon(Icons.check_circle, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "All offline requests synced!",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Triggered when some requests failed during retry
void showSyncFailureSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: const [
          Icon(Icons.warning_rounded, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Some items failed to sync.",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.orange.shade800,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: "View",
        textColor: Colors.white,
        onPressed: () {
          // here you can navigate to pending logs screen (optional)
        },
      ),
    ),
  );
}
