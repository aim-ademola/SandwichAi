import 'package:intl/intl.dart';

class DateFormatter {
  // WAT is UTC+1
  static final _watOffset = const Duration(hours: 1);
  // static final _watTimezone = DateTime.utc(0).timeZoneOffset + _watOffset;

  /// Converts ISO 8601 UTC string to Nigerian WAT time
  static DateTime toWAT(String isoDate) {
    final utcDate = DateTime.parse(isoDate).toUtc();
    return utcDate.add(_watOffset);
  }

  /// e.g. "17 Mar 2026, 07:25 PM"
  static String formatDateTime(String isoDate) {
    final wat = toWAT(isoDate);
    return DateFormat('dd MMM yyyy, hh:mm a').format(wat);
  }

  /// e.g. "17 Mar 2026"
  static String formatDate(String isoDate) {
    final wat = toWAT(isoDate);
    return DateFormat('dd MMM yyyy').format(wat);
  }

  /// e.g. "07:25 PM"
  static String formatTime(String isoDate) {
    final wat = toWAT(isoDate);
    return DateFormat('hh:mm a').format(wat);
  }

  /// e.g. "Today, 07:25 PM" / "Yesterday, 07:25 PM" / "17 Mar, 07:25 PM"
  static String formatRelative(String isoDate) {
    final wat = toWAT(isoDate);
    final now = DateTime.now().toUtc().add(_watOffset);
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(wat.year, wat.month, wat.day);

    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Today, ${DateFormat('hh:mm a').format(wat)}';
    if (diff == 1) return 'Yesterday, ${DateFormat('hh:mm a').format(wat)}';
    return DateFormat('dd MMM, hh:mm a').format(wat);
  }
}
