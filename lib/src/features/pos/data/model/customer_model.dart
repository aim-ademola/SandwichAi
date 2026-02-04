class CustomerModel {
  final String id;
  final String phone;
  final String email;
  final String name;
  final String organizationId;
  final String? dateOfBirth;
  final String? address;
  final String? city;
  final String? dietaryRestrictions;
  final List<String>? favoriteItems;
  final int totalOrders;
  final double totalSpent;
  final int loyaltyPoints;
  final String membershipTier;
  final String? lastOrderDate;
  final double? avgOrderValue;
  final double? avgRating;
  final bool isActive;
  final bool isBlacklisted;
  final String? blacklistReason;
  final bool allowsMarketing;
  final bool allowsSMS;
  final bool allowsEmail;
  final String createdAt;
  final String updatedAt;

  CustomerModel({
    required this.id,
    required this.phone,
    required this.email,
    required this.name,
    required this.organizationId,
    this.dateOfBirth,
    this.address,
    this.city,
    this.dietaryRestrictions,
    this.favoriteItems,
    required this.totalOrders,
    required this.totalSpent,
    required this.loyaltyPoints,
    required this.membershipTier,
    this.lastOrderDate,
    this.avgOrderValue,
    this.avgRating,
    required this.isActive,
    required this.isBlacklisted,
    this.blacklistReason,
    required this.allowsMarketing,
    required this.allowsSMS,
    required this.allowsEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      organizationId: json['organizationId'] as String,
      dateOfBirth: json['dateOfBirth'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      dietaryRestrictions: json['dietaryRestrictions'] as String?,
      favoriteItems: json['favoriteItems'] != null
          ? List<String>.from(json['favoriteItems'] as List)
          : null,
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalSpent: _parseDouble(json['totalSpent']), // Fixed here
      loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
      membershipTier: json['membershipTier'] as String? ?? 'Bronze',
      lastOrderDate: json['lastOrderDate'] as String?,
      avgOrderValue: _parseDoubleNullable(json['avgOrderValue']), // Fixed here
      avgRating: _parseDoubleNullable(json['avgRating']), // Fixed here
      isActive: json['isActive'] as bool? ?? true,
      isBlacklisted: json['isBlacklisted'] as bool? ?? false,
      blacklistReason: json['blacklistReason'] as String?,
      allowsMarketing: json['allowsMarketing'] as bool? ?? false,
      allowsSMS: json['allowsSMS'] as bool? ?? false,
      allowsEmail: json['allowsEmail'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  // Helper method to parse double from string or number
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper method to parse nullable double from string or number
  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'name': name,
      'organizationId': organizationId,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'city': city,
      'dietaryRestrictions': dietaryRestrictions,
      'favoriteItems': favoriteItems,
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'loyaltyPoints': loyaltyPoints,
      'membershipTier': membershipTier,
      'lastOrderDate': lastOrderDate,
      'avgOrderValue': avgOrderValue,
      'avgRating': avgRating,
      'isActive': isActive,
      'isBlacklisted': isBlacklisted,
      'blacklistReason': blacklistReason,
      'allowsMarketing': allowsMarketing,
      'allowsSMS': allowsSMS,
      'allowsEmail': allowsEmail,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class CustomersListResponse {
  final List<CustomerModel> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  CustomersListResponse({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory CustomersListResponse.fromJson(Map<String, dynamic> json) {
    return CustomersListResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}
