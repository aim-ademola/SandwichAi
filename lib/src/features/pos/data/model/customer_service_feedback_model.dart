class CustomerServiceRecord {
  final String id;
  final String title;
  final String details;
  final String status;
  final String? branchId;
  final int? rating;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? orderId;
  final String? reviewId;
  final String? sentiment;
  final int? foodQuality;
  final int? serviceQuality;
  final int? cleanliness;
  final int? valueForMoney;
  final int? ambience;
  final String? responseText;
  final String? respondedBy;
  final String? respondedAt;
  final bool? wouldRecommend;
  final bool? isPublished;
  final bool? isFlagged;
  final String? flagReason;
  final String? reviewSource;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic> raw;

  const CustomerServiceRecord({
    required this.id,
    required this.title,
    required this.details,
    required this.status,
    this.branchId,
    this.rating,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.orderId,
    this.reviewId,
    this.sentiment,
    this.foodQuality,
    this.serviceQuality,
    this.cleanliness,
    this.valueForMoney,
    this.ambience,
    this.responseText,
    this.respondedBy,
    this.respondedAt,
    this.wouldRecommend,
    this.isPublished,
    this.isFlagged,
    this.flagReason,
    this.reviewSource,
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
      branchId: _stringOrNull(json['branchId'] ?? json['branch_id']),
      rating: _intOrNull(
        json['overallRating'] ?? json['rating'] ?? json['score'],
      ),
      customerId: _stringOrNull(json['customerId'] ?? json['customer_id']),
      customerName: _stringOrNull(
        json['customerName'] ?? json['customer_name'] ?? json['name'],
      ),
      customerPhone: _stringOrNull(
        json['customerPhone'] ?? json['customer_phone'],
      ),
      customerEmail: _stringOrNull(
        json['customerEmail'] ?? json['customer_email'],
      ),
      orderId: _stringOrNull(json['orderId'] ?? json['order_id']),
      reviewId: _stringOrNull(json['reviewId'] ?? json['review_id']),
      sentiment: _stringOrNull(json['sentiment']),
      foodQuality: _intOrNull(json['foodQuality'] ?? json['food_quality']),
      serviceQuality: _intOrNull(
        json['serviceQuality'] ?? json['service_quality'],
      ),
      cleanliness: _intOrNull(json['cleanliness']),
      valueForMoney: _intOrNull(
        json['valueForMoney'] ?? json['value_for_money'],
      ),
      ambience: _intOrNull(json['ambience']),
      responseText: _stringOrNull(
        json['responseText'] ?? json['response_text'],
      ),
      respondedBy: _stringOrNull(json['respondedBy'] ?? json['responded_by']),
      respondedAt: _stringOrNull(json['respondedAt'] ?? json['responded_at']),
      wouldRecommend: _boolOrNull(
        json['wouldRecommend'] ?? json['would_recommend'],
      ),
      isPublished: _boolOrNull(json['isPublished'] ?? json['is_published']),
      isFlagged: _boolOrNull(json['isFlagged'] ?? json['is_flagged']),
      flagReason: _stringOrNull(json['flagReason'] ?? json['flag_reason']),
      reviewSource: _stringOrNull(
        json['reviewSource'] ?? json['review_source'],
      ),
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

  static bool? _boolOrNull(dynamic value) {
    if (value is bool) return value;
    if (value is String) return bool.tryParse(value);
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

  CustomerServiceRecordList copyWith({
    List<CustomerServiceRecord>? data,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
  }) {
    return CustomerServiceRecordList(
      data: data ?? this.data,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
