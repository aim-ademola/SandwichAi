import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

enum LogLevel { info, warning, error }

class AppLogger {
  AppLogger._();

  static const int _maxLogChunkLength = 900;

  static void log(
    Object? message, {
    LogLevel level = LogLevel.info,
    StackTrace? stackTrace,
  }) {
    // Debug & Profile
    if (kDebugMode || kProfileMode) {
      _developerLog(_format(message, level), level: level);
      if (stackTrace != null) {
        _developerLog(stackTrace.toString(), level: level);
      }
    }

    // Release only
    if (kReleaseMode && level == LogLevel.error) {
      FirebaseCrashlytics.instance.recordError(
        message,
        stackTrace ?? StackTrace.current,
      );
    }
  }

  static String _format(Object? message, LogLevel level) {
    final prefix = switch (level) {
      LogLevel.info => '[INFO]',
      LogLevel.warning => '[WARN]',
      LogLevel.error => '[ERROR]',
    };
    return '$prefix $message';
  }

  static void _developerLog(String message, {required LogLevel level}) {
    final name = switch (level) {
      LogLevel.info => 'SandwichAI.INFO',
      LogLevel.warning => 'SandwichAI.WARN',
      LogLevel.error => 'SandwichAI.ERROR',
    };

    if (message.length <= _maxLogChunkLength) {
      developer.log(message, name: name);
      return;
    }

    final totalChunks = (message.length / _maxLogChunkLength).ceil();
    for (var index = 0; index < totalChunks; index++) {
      final start = index * _maxLogChunkLength;
      final end = (start + _maxLogChunkLength).clamp(0, message.length);
      developer.log(
        '[${index + 1}/$totalChunks] ${message.substring(start, end)}',
        name: name,
      );
    }
  }
}

void logDebug(Object? message) {
  assert(() {
    developer.log('[DEBUG] $message', name: 'SandwichAI.DEBUG');
    return true;
  }());
}
