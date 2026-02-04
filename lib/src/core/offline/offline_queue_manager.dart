import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sandwich_ai/src/core/offline/pending_req.dart';
import '../network/api_engine_private/api_client.dart';

class OfflineQueueManager {
  static final OfflineQueueManager instance = OfflineQueueManager._();
  OfflineQueueManager._();

  final _box = Hive.box('pending_requests');
  final ApiClient _apiClient = ApiClient.instance;

  bool _isRetrying = false;

  /// Save an offline request
  Future<void> add(PendingRequest request, {Function()? onSaved}) async {
    await _box.add(request.toJson());
    onSaved?.call();
  }

  /// Retry all pending offline requests
  Future<void> retry({
    Function()? onStart,
    Function()? onSuccess,
    Function()? onFailure,
  }) async {
    if (_isRetrying) return; // Prevent duplicate retries
    _isRetrying = true;

    onStart?.call(); // Notify retry started

    List keys = _box.keys.toList();
    bool allSuccess = true;

    for (var key in keys) {
      final dynamic stored = _box.get(key);

      if (stored == null) {
        allSuccess = false;
        continue;
      }

      // Ensure JSON is a valid map
      final json = Map<String, dynamic>.from(stored);

      final req = PendingRequest.fromJson(json);

      try {
        if (req.method == 'POST') {
          await _apiClient.post(req.url, data: req.body);
        } else if (req.method == 'PUT') {
          await _apiClient.put(req.url, data: req.body);
        } else if (req.method == 'PATCH') {
          await _apiClient.patch(req.url, data: req.body);
        }

        // Remove after successful execution
        await _box.delete(key);
      } catch (_) {
        allSuccess = false;
      }
    }

    _isRetrying = false;

    if (allSuccess) {
      onSuccess?.call();
    } else {
      onFailure?.call();
    }
  }
}
