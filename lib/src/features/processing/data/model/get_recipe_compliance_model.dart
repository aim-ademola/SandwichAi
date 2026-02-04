import 'package:equatable/equatable.dart';

class RecipeComplianceResponse extends Equatable {
  const RecipeComplianceResponse({
    required this.id,
    required this.menuItemId,
    required this.branchId,
    required this.checkDate,
    required this.batchesPrepared,
    required this.itemName,
    required this.expectedInput,
    required this.actualInput,
    required this.variance,
    required this.variancePercent,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.menuItem,
    required this.branch,
  });

  final String? id;
  final String? menuItemId;
  final String? branchId;
  final DateTime? checkDate;
  final int? batchesPrepared;
  final String? itemName;
  final String? expectedInput;
  final String? actualInput;
  final String? variance;
  final String? variancePercent;
  final String? status;
  final String? notes;
  final DateTime? createdAt;
  final MenuItem? menuItem;
  final Branch? branch;

  RecipeComplianceResponse copyWith({
    String? id,
    String? menuItemId,
    String? branchId,
    DateTime? checkDate,
    int? batchesPrepared,
    String? itemName,
    String? expectedInput,
    String? actualInput,
    String? variance,
    String? variancePercent,
    String? status,
    String? notes,
    DateTime? createdAt,
    MenuItem? menuItem,
    Branch? branch,
  }) {
    return RecipeComplianceResponse(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      branchId: branchId ?? this.branchId,
      checkDate: checkDate ?? this.checkDate,
      batchesPrepared: batchesPrepared ?? this.batchesPrepared,
      itemName: itemName ?? this.itemName,
      expectedInput: expectedInput ?? this.expectedInput,
      actualInput: actualInput ?? this.actualInput,
      variance: variance ?? this.variance,
      variancePercent: variancePercent ?? this.variancePercent,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      menuItem: menuItem ?? this.menuItem,
      branch: branch ?? this.branch,
    );
  }

  factory RecipeComplianceResponse.fromJson(Map<String, dynamic> json) {
    return RecipeComplianceResponse(
      id: json["id"],
      menuItemId: json["menuItemId"],
      branchId: json["branchId"],
      checkDate: DateTime.tryParse(json["checkDate"] ?? ""),
      batchesPrepared: json["batchesPrepared"],
      itemName: json["itemName"],
      expectedInput: json["expectedInput"],
      actualInput: json["actualInput"],
      variance: json["variance"],
      variancePercent: json["variancePercent"],
      status: json["status"],
      notes: json["notes"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      menuItem: json["menuItem"] == null
          ? null
          : MenuItem.fromJson(json["menuItem"]),
      branch: json["branch"] == null ? null : Branch.fromJson(json["branch"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "menuItemId": menuItemId,
    "branchId": branchId,
    "checkDate": checkDate?.toIso8601String(),
    "batchesPrepared": batchesPrepared,
    "itemName": itemName,
    "expectedInput": expectedInput,
    "actualInput": actualInput,
    "variance": variance,
    "variancePercent": variancePercent,
    "status": status,
    "notes": notes,
    "createdAt": createdAt?.toIso8601String(),
    "menuItem": menuItem?.toJson(),
    "branch": branch?.toJson(),
  };

  @override
  String toString() {
    return "$id, $menuItemId, $branchId, $checkDate, $batchesPrepared, $itemName, $expectedInput, $actualInput, $variance, $variancePercent, $status, $notes, $createdAt, $menuItem, $branch, ";
  }

  @override
  List<Object?> get props => [
    id,
    menuItemId,
    branchId,
    checkDate,
    batchesPrepared,
    itemName,
    expectedInput,
    actualInput,
    variance,
    variancePercent,
    status,
    notes,
    createdAt,
    menuItem,
    branch,
  ];
}

class Branch extends Equatable {
  const Branch({
    required this.id,
    required this.name,
    required this.branchCode,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
    required this.email,
    required this.openingHours,
    required this.isActive,
    required this.managerId,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String? id;
  final String? name;
  final String? branchCode;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final String? email;
  final dynamic openingHours;
  final bool? isActive;
  final String? managerId;
  final String? organizationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Branch copyWith({
    String? id,
    String? name,
    String? branchCode,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    String? email,
    dynamic openingHours,
    bool? isActive,
    String? managerId,
    String? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      branchCode: branchCode ?? this.branchCode,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      email: email ?? this.email,
      openingHours: openingHours ?? this.openingHours,
      isActive: isActive ?? this.isActive,
      managerId: managerId ?? this.managerId,
      organizationId: organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json["id"],
      name: json["name"],
      branchCode: json["branch_code"],
      address: json["address"],
      city: json["city"],
      state: json["state"],
      country: json["country"],
      zipCode: json["zipCode"],
      email: json["email"],
      openingHours: json["openingHours"],
      isActive: json["isActive"],
      managerId: json["managerId"],
      organizationId: json["organizationId"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "branch_code": branchCode,
    "address": address,
    "city": city,
    "state": state,
    "country": country,
    "zipCode": zipCode,
    "email": email,
    "openingHours": openingHours,
    "isActive": isActive,
    "managerId": managerId,
    "organizationId": organizationId,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };

  @override
  String toString() {
    return "$id, $name, $branchCode, $address, $city, $state, $country, $zipCode, $email, $openingHours, $isActive, $managerId, $organizationId, $createdAt, $updatedAt, ";
  }

  @override
  List<Object?> get props => [
    id,
    name,
    branchCode,
    address,
    city,
    state,
    country,
    zipCode,
    email,
    openingHours,
    isActive,
    managerId,
    organizationId,
    createdAt,
    updatedAt,
  ];
}

class MenuItem extends Equatable {
  const MenuItem({
    required this.id,
    required this.dishName,
    required this.description,
    required this.category,
    required this.price,
    required this.preparationTime,
    required this.isAvailable,
    required this.imageUrl,
    required this.branchId,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String? id;
  final String? dishName;
  final String? description;
  final String? category;
  final String? price;
  final int? preparationTime;
  final bool? isAvailable;
  final String? imageUrl;
  final String? branchId;
  final String? organizationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MenuItem copyWith({
    String? id,
    String? dishName,
    String? description,
    String? category,
    String? price,
    int? preparationTime,
    bool? isAvailable,
    String? imageUrl,
    String? branchId,
    String? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      dishName: dishName ?? this.dishName,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      preparationTime: preparationTime ?? this.preparationTime,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      branchId: branchId ?? this.branchId,
      organizationId: organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json["id"],
      dishName: json["dishName"],
      description: json["description"],
      category: json["category"],
      price: json["price"],
      preparationTime: json["preparationTime"],
      isAvailable: json["isAvailable"],
      imageUrl: json["imageUrl"],
      branchId: json["branchId"],
      organizationId: json["organizationId"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "dishName": dishName,
    "description": description,
    "category": category,
    "price": price,
    "preparationTime": preparationTime,
    "isAvailable": isAvailable,
    "imageUrl": imageUrl,
    "branchId": branchId,
    "organizationId": organizationId,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };

  @override
  String toString() {
    return "$id, $dishName, $description, $category, $price, $preparationTime, $isAvailable, $imageUrl, $branchId, $organizationId, $createdAt, $updatedAt, ";
  }

  @override
  List<Object?> get props => [
    id,
    dishName,
    description,
    category,
    price,
    preparationTime,
    isAvailable,
    imageUrl,
    branchId,
    organizationId,
    createdAt,
    updatedAt,
  ];
}
