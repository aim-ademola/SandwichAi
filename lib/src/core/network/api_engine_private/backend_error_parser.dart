class FieldError {
  final String field;
  final String message;
  final String? type;

  const FieldError({required this.field, required this.message, this.type});
}

class ApiErrorDetails {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic raw;
  final List<FieldError> fieldErrors;

  const ApiErrorDetails({
    required this.message,
    this.statusCode,
    this.code,
    this.raw,
    this.fieldErrors = const [],
  });

  bool get hasBackendMessage => message.trim().isNotEmpty;
}

class BackendErrorParser {
  static ApiErrorDetails parse(
    dynamic data, {
    int? statusCode,
    String fallbackMessage = 'Something went wrong. Please try again.',
  }) {
    final fieldErrors = <FieldError>[];
    final code = _extractCode(data);
    final message =
        _extractMessage(data, fieldErrors) ?? fallbackMessage.trim();

    return ApiErrorDetails(
      message: message.isEmpty ? fallbackMessage : message,
      statusCode: statusCode,
      code: code,
      raw: data,
      fieldErrors: fieldErrors,
    );
  }

  static String? _extractMessage(dynamic data, List<FieldError> fieldErrors) {
    if (data == null) return null;

    if (data is String) {
      final value = data.trim();
      return value.isEmpty ? null : value;
    }

    if (data is List) {
      final messages = data
          .map((item) => _extractMessage(item, fieldErrors))
          .whereType<String>()
          .where((message) => message.trim().isNotEmpty)
          .toList();
      return messages.isEmpty ? null : messages.join('\n');
    }

    if (data is Map) {
      final map = data.cast<dynamic, dynamic>();

      final message = _stringOrJoinedList(map['message'], fieldErrors);
      if (message != null) return message;

      final error = _stringOrJoinedList(map['error'], fieldErrors);
      if (error != null) return error;

      final detail = _parseDetail(map['detail'], fieldErrors);
      if (detail != null) return detail;

      final errors = _stringOrJoinedList(map['errors'], fieldErrors);
      if (errors != null) return errors;

      final dataMessage = _extractMessage(map['data'], fieldErrors);
      if (dataMessage != null) return dataMessage;
    }

    return null;
  }

  static String? _parseDetail(dynamic detail, List<FieldError> fieldErrors) {
    if (detail is List) {
      final messages = <String>[];
      for (final item in detail) {
        if (item is Map) {
          final map = item.cast<dynamic, dynamic>();
          final msg = map['msg']?.toString().trim();
          if (msg != null && msg.isNotEmpty) {
            messages.add(msg);
            fieldErrors.add(
              FieldError(
                field: _fieldFromLocation(map['loc']),
                message: msg,
                type: map['type']?.toString(),
              ),
            );
            continue;
          }
        }

        final message = _extractMessage(item, fieldErrors);
        if (message != null) messages.add(message);
      }
      return messages.isEmpty ? null : messages.join('\n');
    }

    return _stringOrJoinedList(detail, fieldErrors);
  }

  static String? _stringOrJoinedList(
    dynamic value,
    List<FieldError> fieldErrors,
  ) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is List) {
      final messages = value
          .map((item) => _extractMessage(item, fieldErrors))
          .whereType<String>()
          .where((message) => message.trim().isNotEmpty)
          .toList();
      return messages.isEmpty ? null : messages.join('\n');
    }
    if (value is Map) return _extractMessage(value, fieldErrors);
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _extractCode(dynamic data) {
    if (data is! Map) return null;
    final map = data.cast<dynamic, dynamic>();
    return (map['code'] ?? map['errorCode'] ?? map['type'])?.toString();
  }

  static String _fieldFromLocation(dynamic location) {
    if (location is List && location.isNotEmpty) {
      final parts = location
          .where((part) => part.toString() != 'body')
          .map((part) => part.toString())
          .toList();
      return parts.isEmpty ? location.last.toString() : parts.join('.');
    }
    return location?.toString() ?? '';
  }
}
