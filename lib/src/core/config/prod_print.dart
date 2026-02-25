import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error }

class AppLogger {
  AppLogger._();

  static void log(
    Object? message, {
    LogLevel level = LogLevel.info,
    StackTrace? stackTrace,
  }) {
    // Debug & Profile
    if (kDebugMode || kProfileMode) {
      debugPrint(_format(message, level));
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }

    // Release only
    // if (kReleaseMode && level == LogLevel.error) {
    //   FirebaseCrashlytics.instance.recordError(
    //     message,
    //     stackTrace ?? StackTrace.current,
    //   );
    // }
  }

  static String _format(Object? message, LogLevel level) {
    final prefix = switch (level) {
      LogLevel.info => '[INFO]',
      LogLevel.warning => '[WARN]',
      LogLevel.error => '[ERROR]',
    };
    return '$prefix $message';
  }
}

void logDebug(Object? message) {
  assert(() {
    print(message);
    return true;
  }());
}
