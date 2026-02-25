// data/model/product_intake_model.dart

class ProductIntake {
  final String id;
  final String branchId;
  final String organizationId;
  final DateTime intakeDate;
  final String issuedBy;
  final String stockBatchId;
  final String productName;
  final ProductType productType;
  final String itemId;
  final String qtyReceived;
  final Unit unit;
  final bool qualityStatus;
  final String receivedBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Branch? branch;
  final InventoryItem? item;

  ProductIntake({
    required this.id,
    required this.branchId,
    required this.organizationId,
    required this.intakeDate,
    required this.issuedBy,
    required this.stockBatchId,
    required this.productName,
    required this.productType,
    required this.itemId,
    required this.qtyReceived,
    required this.unit,
    required this.qualityStatus,
    required this.receivedBy,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.branch,
    this.item,
  });

  factory ProductIntake.fromJson(Map<String, dynamic> json) {
    return ProductIntake(
      id: json['id'] ?? '',
      branchId: json['branchId'] ?? '',
      organizationId: json['organizationId'] ?? '',
      intakeDate: DateTime.parse(json['intakeDate']),
      issuedBy: json['issuedBy'] ?? '',
      stockBatchId: json['stockBatchId'] ?? '',
      productName: json['productName'] ?? '',
      productType: ProductTypeExtension.fromString(json['productType']),
      itemId: json['itemId'] ?? '',
      qtyReceived: json['qtyReceived'] ?? '',
      unit: UnitExtension.fromString(json['unit']),
      qualityStatus: json['qualityStatus'] ?? false,
      receivedBy: json['receivedBy'] ?? '',
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      item: json['item'] != null ? InventoryItem.fromJson(json['item']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branchId': branchId,
      'organizationId': organizationId,
      'intakeDate': intakeDate.toIso8601String(),
      'issuedBy': issuedBy,
      'stockBatchId': stockBatchId,
      'productName': productName,
      'productType': productType.value,
      'itemId': itemId,
      'qtyReceived': qtyReceived,
      'unit': unit.value,
      'qualityStatus': qualityStatus,
      'receivedBy': receivedBy,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'branch': branch?.toJson(),
      'item': item?.toJson(),
    };
  }
}

class Branch {
  final String id;
  final String name;
  final String branchCode;
  final String address;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final String email;
  final Map<String, dynamic>? openingHours;
  final bool isActive;
  final String managerId;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Branch({
    required this.id,
    required this.name,
    required this.branchCode,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
    required this.email,
    this.openingHours,
    required this.isActive,
    required this.managerId,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      branchCode: json['branch_code'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      zipCode: json['zipCode'] ?? '',
      email: json['email'] ?? '',
      openingHours: json['openingHours'] as Map<String, dynamic>?, // ← Updated
      isActive: json['isActive'] ?? false,
      managerId: json['managerId'] ?? '',
      organizationId: json['organizationId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'branch_code': branchCode,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zipCode': zipCode,
      'email': email,
      'openingHours': openingHours,
      'isActive': isActive,
      'managerId': managerId,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class InventoryItem {
  final String id;
  final String itemName;
  final String category;
  final String unit;
  final String description;
  final String sku;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.itemName,
    required this.category,
    required this.unit,
    required this.description,
    required this.sku,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] ?? '',
      itemName: json['itemName'] ?? '',
      category: json['category'] ?? '',
      unit: json['unit'] ?? '',
      description: json['description'] ?? '',
      sku: json['sku'] ?? '',
      organizationId: json['organizationId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'category': category,
      'unit': unit,
      'description': description,
      'sku': sku,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// Employee Model
class Employee {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final DateTime dateOfBirth;
  final String role;
  final String department;
  final bool isDepartmentManager;
  final EmployeeStatus status;
  final DateTime hireDate;
  final DateTime? terminationDate;
  final DateTime lastLogin;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final String organizationId;
  final String branchId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Employee({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.dateOfBirth,
    required this.role,
    required this.department,
    required this.isDepartmentManager,
    required this.status,
    required this.hireDate,
    this.terminationDate,
    required this.lastLogin,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    required this.organizationId,
    required this.branchId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    try {
      return Employee(
        id: json['id']?.toString() ?? '',
        employeeId: json['employeeId']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.parse(json['dateOfBirth'])
            : DateTime.now(),
        role: json['role']?.toString() ?? '',
        department: json['department']?.toString() ?? '',
        isDepartmentManager: json['isDepartmentManager'] == true,
        status: json['status'] != null
            ? EmployeeStatusExtension.fromString(json['status'])
            : EmployeeStatus.active,
        hireDate: json['hireDate'] != null
            ? DateTime.parse(json['hireDate'])
            : DateTime.now(),
        terminationDate: json['terminationDate'] != null
            ? DateTime.parse(json['terminationDate'])
            : null,
        lastLogin: json['lastLogin'] != null
            ? DateTime.parse(json['lastLogin'])
            : DateTime.now(),
        emergencyContactName: json['emergencyContactName']?.toString(),
        emergencyContactPhone: json['emergencyContactPhone']?.toString(),
        emergencyContactRelation: json['emergencyContactRelation']?.toString(),
        organizationId: json['organizationId']?.toString() ?? '',
        branchId: json['branchId']?.toString() ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
      );
    } catch (e) {
      throw FormatException('Failed to parse Employee: $e\nJSON: $json');
    }
  }

  String get fullName => '$firstName $lastName';
}

class EmployeesResponse {
  final List<Employee> data;
  final int total;
  final int page;
  final int limit;

  EmployeesResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory EmployeesResponse.fromJson(Map<String, dynamic> json) {
    return EmployeesResponse(
      data: (json['data'] as List)
          .map((item) => Employee.fromJson(item))
          .toList(),
      total: json['total'] is int
          ? json['total']
          : int.parse(json['total'].toString()),
      page: json['page'] is int
          ? json['page']
          : int.parse(json['page'].toString()),
      limit: json['limit'] is int
          ? json['limit']
          : int.parse(json['limit'].toString()),
    );
  }
}

// Request Models
class CreateProductIntakeRequest {
  final String branchId;
  final String issuedBy;
  final String stockBatchId;
  final String productName;
  final ProductType productType;
  final String itemId;
  final int qtyReceived;
  final Unit unit;
  final bool qualityStatus;
  final String receivedBy;
  final String? notes;

  CreateProductIntakeRequest({
    required this.branchId,
    required this.issuedBy,
    required this.stockBatchId,
    required this.productName,
    required this.productType,
    required this.itemId,
    required this.qtyReceived,
    required this.unit,
    required this.qualityStatus,
    required this.receivedBy,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'issuedBy': issuedBy,
      'stockBatchId': stockBatchId,
      'productName': productName,
      'productType': productType.value,
      'itemId': itemId,
      'qtyReceived': qtyReceived,
      'unit': unit.value,
      'qualityStatus': qualityStatus,
      'receivedBy': receivedBy,
      if (notes != null) 'notes': notes,
    };
  }
}

// Enums
enum ProductType { rawMaterial, semiProcessed, finishedProduct }

extension ProductTypeExtension on ProductType {
  String get value {
    switch (this) {
      case ProductType.rawMaterial:
        return 'RAW_MATERIAL';
      case ProductType.semiProcessed:
        return 'SEMI_PROCESSED';
      case ProductType.finishedProduct:
        return 'FINISHED_PRODUCT';
    }
  }

  String get displayName {
    switch (this) {
      case ProductType.rawMaterial:
        return 'Raw Material';
      case ProductType.semiProcessed:
        return 'Semi-Processed';
      case ProductType.finishedProduct:
        return 'Finished Product';
    }
  }

  static ProductType fromString(String value) {
    switch (value) {
      case 'RAW_MATERIAL':
        return ProductType.rawMaterial;
      case 'SEMI_PROCESSED':
        return ProductType.semiProcessed;
      case 'FINISHED_PRODUCT':
        return ProductType.finishedProduct;
      default:
        return ProductType.rawMaterial;
    }
  }
}

enum Unit { kg, g, l, ml, pieces, bags, cartons, bottles }

extension UnitExtension on Unit {
  String get value {
    switch (this) {
      case Unit.kg:
        return 'KG';
      case Unit.g:
        return 'G';
      case Unit.l:
        return 'L';
      case Unit.ml:
        return 'ML';
      case Unit.pieces:
        return 'PIECES';
      case Unit.bags:
        return 'BAGS';
      case Unit.cartons:
        return 'CARTONS';
      case Unit.bottles:
        return 'BOTTLES';
    }
  }

  String get displayName => value;

  static Unit fromString(String value) {
    switch (value) {
      case 'KG':
        return Unit.kg;
      case 'G':
        return Unit.g;
      case 'L':
        return Unit.l;
      case 'ML':
        return Unit.ml;
      case 'PIECES':
        return Unit.pieces;
      case 'BAGS':
        return Unit.bags;
      case 'CARTONS':
        return Unit.cartons;
      case 'BOTTLES':
        return Unit.bottles;
      default:
        return Unit.kg;
    }
  }
}

enum EmployeeStatus { active, inactive, terminated, onLeave, onDuty, offDuty }

extension EmployeeStatusExtension on EmployeeStatus {
  String get value {
    switch (this) {
      case EmployeeStatus.active:
        return 'ACTIVE';
      case EmployeeStatus.inactive:
        return 'INACTIVE';
      case EmployeeStatus.terminated:
        return 'TERMINATED';
      case EmployeeStatus.onLeave:
        return 'ON_LEAVE';
      case EmployeeStatus.onDuty:
        return 'ON_DUTY';
      case EmployeeStatus.offDuty:
        return 'OFF_DUTY';
    }
  }

  static EmployeeStatus fromString(String value) {
    switch (value) {
      case 'ACTIVE':
        return EmployeeStatus.active;
      case 'INACTIVE':
        return EmployeeStatus.inactive;
      case 'TERMINATED':
        return EmployeeStatus.terminated;
      case 'ON_LEAVE':
        return EmployeeStatus.onLeave;
      case 'ON_DUTY':
        return EmployeeStatus.onDuty;
      case 'OFF_DUTY':
        return EmployeeStatus.offDuty;
      default:
        return EmployeeStatus.active;
    }
  }
}
