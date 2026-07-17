class CustomerServiceRecord {
  final String id;
  final String title;
  final String details;
  final String status;
  final int? rating;
  final String? customerId;
  final String? customerName;
  final String? orderId;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic> raw;

  const CustomerServiceRecord({
    required this.id,
    required this.title,
    required this.details,
    required this.status,
    this.rating,
    this.customerId,
    this.customerName,
    this.orderId,
    this.createdAt,
    this.updatedAt,
    required this.raw,
  });

  factory CustomerServiceRecord.fromJson(Map<String, dynamic> json) {
    return CustomerServiceRecord(
      id: _string(json['id'] ?? json['_id']),
      title: _string(
        json['title'] ??
            json['subject'] ??
            json['headline'] ??
            json['comment'] ??
            json['review'],
        fallback: 'Untitled',
      ),
      details: _string(
        json['details'] ??
            json['description'] ??
            json['message'] ??
            json['body'] ??
            json['comment'] ??
            json['review'],
      ),
      status: _string(json['status'], fallback: 'Pending'),
      rating: _intOrNull(
        json['overallRating'] ?? json['rating'] ?? json['score'],
      ),
      customerId: _stringOrNull(json['customerId'] ?? json['customer_id']),
      customerName: _stringOrNull(
        json['customerName'] ?? json['customer_name'] ?? json['name'],
      ),
      orderId: _stringOrNull(json['orderId'] ?? json['order_id']),
      createdAt: _stringOrNull(json['createdAt'] ?? json['created_at']),
      updatedAt: _stringOrNull(json['updatedAt'] ?? json['updated_at']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  static String _string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final parsed = value.toString();
    return parsed.isEmpty ? fallback : parsed;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final parsed = value.toString();
    return parsed.isEmpty ? null : parsed;
  }

  static int? _intOrNull(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class CustomerServiceRecordList {
  final List<CustomerServiceRecord> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const CustomerServiceRecordList({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory CustomerServiceRecordList.fromJson(dynamic response) {
    final map = _asMap(response);
    final rawData = map['data'] ?? map['items'] ?? map['results'] ?? [];
    final meta = map['meta'] is Map<String, dynamic>
        ? map['meta'] as Map<String, dynamic>
        : map;
    final rows = rawData is List ? rawData : <dynamic>[];

    return CustomerServiceRecordList(
      data: rows
          .whereType<Map>()
          .map(
            (row) =>
                CustomerServiceRecord.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList(),
      page: _int(meta['page'] ?? meta['currentPage'], fallback: 1),
      limit: _int(meta['limit'] ?? meta['perPage'], fallback: 10),
      total: _int(meta['total'], fallback: rows.length),
      totalPages: _int(meta['totalPages'] ?? meta['lastPage'], fallback: 1),
    );
  }

  static Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    if (response is List) return {'data': response};
    return const {'data': []};
  }

  static int _int(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
