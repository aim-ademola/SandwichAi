import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/network/connectivity_service.dart';
import 'package:sandwich_ai/src/core/offline/connectivity_snack.dart'
    show
        showSyncStartSnackBar,
        showSyncSuccessSnackBar,
        showSyncFailureSnackBar;
import 'package:sandwich_ai/src/core/offline/offline_queue_manager.dart';

class AppInitializer extends StatefulWidget {
  final Widget child;
  const AppInitializer({super.key, required this.child});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();

    ConnectivityService.instance.listen((online) {
      if (online) {
        OfflineQueueManager.instance.retry(
          onStart: () => showSyncStartSnackBar(context, "Syncing..."),
          onSuccess: () =>
              showSyncSuccessSnackBar(context, "Synced successfully"),
          onFailure: () =>
              showSyncFailureSnackBar(context, "Some failed items"),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
