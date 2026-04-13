class SupplierResponse {
  final String? id;
  final String? supplierId;
  final String? email;
  final String? phone;
  final String? businessName;
  final String? tradingName;
  final String? registrationNumber;
  final String? contactPersonName;
  final String? contactPersonTitle;
  final String? contactPersonPhone;
  final String? contactPersonEmail;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final String? supplierType;
  final String? status;
  final String? description;
  final String? logo;
  final String? website;
  final String? defaultPaymentTerm;
  final String? defaultCurrency;
  final double? minimumOrderValue;
  final int? deliveryLeadTime;
  final int? totalOrders;
  final int? completedOrders;
  final int? cancelledOrders;
  final bool? isVerified;
  final String? verifiedAt;
  final bool? isEmailVerified;
  final bool? isPhoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupplierResponse({
    required this.id,
    required this.supplierId,
    required this.email,
    required this.phone,
    required this.businessName,
    required this.tradingName,
    required this.registrationNumber,
    required this.contactPersonName,
    required this.contactPersonTitle,
    required this.contactPersonPhone,
    required this.contactPersonEmail,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
    required this.supplierType,
    required this.status,
    required this.description,
    this.logo,
    this.website,
    required this.defaultPaymentTerm,
    required this.defaultCurrency,
    required this.minimumOrderValue,
    required this.deliveryLeadTime,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.isVerified,
    this.verifiedAt,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierResponse.fromJson(Map<String, dynamic> json) {
    return SupplierResponse(
      id: json['id'] ?? '',
      supplierId: json['supplierId'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      businessName: json['businessName'] ?? '',
      tradingName: json['tradingName'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      contactPersonName: json['contactPersonName'] ?? '',
      contactPersonTitle: json['contactPersonTitle'] ?? '',
      contactPersonPhone: json['contactPersonPhone'] ?? '',
      contactPersonEmail: json['contactPersonEmail'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      zipCode: json['zipCode'] ?? '',
      supplierType: json['supplierType'] ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      logo: json['logo'] ?? '',
      website: json['website'] ?? '',
      defaultPaymentTerm: json['defaultPaymentTerm'] ?? '',
      defaultCurrency: json['defaultCurrency'] ?? '',
      minimumOrderValue: (json['minimumOrderValue'] ?? 0).toDouble(),
      deliveryLeadTime: json['deliveryLeadTime'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      completedOrders: json['completedOrders'] ?? 0,
      cancelledOrders: json['cancelledOrders'] ?? 0,
      isVerified: (json['isVerified'] as bool?) ?? false,

      verifiedAt: json['verifiedAt'] ?? '',
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? ''),
      updatedAt: DateTime.parse(json['updatedAt'] ?? ''),
    );
  }
}

// supplier_product_model.dart
class SupplierProductResponse {
  final String? id;
  final String? productCode;
  final String? supplierId;
  final String? productName;
  final String? description;
  final String? category;
  final String? subCategory;
  final List<String?> images;
  final String? primaryImage;
  final String? brand;
  final String? manufacturer;
  final String? origin;
  final Map<String, dynamic>? specifications;
  final String? unitType;
  final String? packagingType;
  final String? unitsPerPackage;
  final String? baseUnitPrice;
  final String? currency;
  final String? minimumOrderQty;
  final String? status;
  final String? availableStock;
  final int leadTime;
  final bool hasQualityCert;
  final List<String?> certifications;
  final int shelfLife;
  final String? storageConditions;
  final String? totalSold;
  final double? averageRating;
  final int totalReviews;
  final bool isActive;
  final bool isFeatured;
  final bool isPromotional;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<dynamic> bulkPrices;
  final List<dynamic> discounts;

  SupplierProductResponse({
    required this.id,
    required this.productCode,
    required this.supplierId,
    required this.productName,
    required this.description,
    required this.category,
    this.subCategory,
    required this.images,
    this.primaryImage,
    this.brand,
    this.manufacturer,
    this.origin,
    this.specifications,
    required this.unitType,
    required this.packagingType,
    required this.unitsPerPackage,
    required this.baseUnitPrice,
    required this.currency,
    required this.minimumOrderQty,
    required this.status,
    required this.availableStock,
    required this.leadTime,
    required this.hasQualityCert,
    required this.certifications,
    required this.shelfLife,
    required this.storageConditions,
    required this.totalSold,
    this.averageRating,
    required this.totalReviews,
    required this.isActive,
    required this.isFeatured,
    required this.isPromotional,
    required this.createdAt,
    required this.updatedAt,
    required this.bulkPrices,
    required this.discounts,
  });

  factory SupplierProductResponse.fromJson(Map<String, dynamic> json) {
    return SupplierProductResponse(
      id: json['id'] ?? '',
      productCode: json['productCode'] ?? '',
      supplierId: json['supplierId'] ?? '',
      productName: json['productName'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'] ?? '',
      primaryImage: json['primaryImage'] ?? '',
      brand: json['brand'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      origin: json['origin'] ?? '',
      specifications: json['specifications'] as Map<String, dynamic>?,
      unitType: json['unitType'] ?? '',
      packagingType: json['packagingType'] ?? '',
      unitsPerPackage: json['unitsPerPackage'] ?? '',
      baseUnitPrice: json['baseUnitPrice'] ?? '',
      currency: json['currency'] ?? '',
      minimumOrderQty: json['minimumOrderQty'] ?? '',
      status: json['status'] ?? '',
      availableStock: json['availableStock'] ?? '',
      leadTime: (json['leadTime'] as int?) ?? 0,
      hasQualityCert: (json['hasQualityCert'] as bool?) ?? false,
      shelfLife: (json['shelfLife'] as int?) ?? 0,
      totalReviews: (json['totalReviews'] as int?) ?? 0,
      isActive: (json['isActive'] as bool?) ?? false,
      isFeatured: (json['isFeatured'] as bool?) ?? false,
      isPromotional: (json['isPromotional'] as bool?) ?? false,
      averageRating: (json['averageRating'] as num?)?.toDouble(),

      images: List<String>.from((json['images'] as List?) ?? []),
      certifications: List<String>.from(
        (json['certifications'] as List?) ?? [],
      ),
      bulkPrices: (json['bulkPrices'] as List?) ?? [],
      discounts: (json['discounts'] as List?) ?? [],
      storageConditions: json['storageConditions'] ?? '',
      totalSold: json['totalSold'] ?? '',

      createdAt: DateTime.parse(json['createdAt'] ?? ''),
      updatedAt: DateTime.parse(json['updatedAt'] ?? ''),
    );
  }
}

class PaginationMeta {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
      hasNextPage: json['hasNextPage'] as bool,
      hasPreviousPage: json['hasPreviousPage'] as bool,
    );
  }
}
