// Enums
enum ShiftType { MORNING, AFTERNOON, EVENING, NIGHT, FULL_DAY }

enum EmployeeStatus { ACTIVE, INACTIVE, ON_LEAVE }

enum Department { KITCHEN, SERVICE, MANAGEMENT }

class Employee {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? address;
  final String? dateOfBirth;
  final String role;
  final Department department;
  final bool isDepartmentManager;
  final EmployeeStatus status;
  final String? hireDate;
  final String? terminationDate;
  final String? lastLogin;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final String organizationId;
  final String branchId;
  final String createdAt;
  final String updatedAt;

  Employee({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.address,
    this.dateOfBirth,
    required this.role,
    required this.department,
    required this.isDepartmentManager,
    required this.status,
    this.hireDate,
    this.terminationDate,
    this.lastLogin,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    required this.organizationId,
    required this.branchId,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Employee.fromJson(Map<String, dynamic> json) {
    Department parseDepartment(String? val) {
      if (val == null) return Department.KITCHEN;
      switch (val.toUpperCase()) {
        case 'SERVICE':
          return Department.SERVICE;
        case 'MANAGEMENT':
          return Department.MANAGEMENT;
        case 'KITCHEN':
        default:
          return Department.KITCHEN;
      }
    }

    EmployeeStatus parseStatus(String? val) {
      if (val == null) return EmployeeStatus.ACTIVE;
      switch (val.toUpperCase()) {
        case 'INACTIVE':
          return EmployeeStatus.INACTIVE;
        case 'ON_LEAVE':
          return EmployeeStatus.ON_LEAVE;
        case 'ACTIVE':
        default:
          return EmployeeStatus.ACTIVE;
      }
    }

    return Employee(
      id: (json['id'] ?? '') as String,
      employeeId: (json['employeeId'] ?? json['employee_id'] ?? '') as String,
      firstName: (json['firstName'] ?? json['first_name'] ?? '') as String,
      lastName: (json['lastName'] ?? json['last_name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      address: json['address'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      role: (json['role'] ?? '') as String,
      department: parseDepartment(json['department'] as String?),
      isDepartmentManager:
          (json['isDepartmentManager'] ??
                  json['is_department_manager'] ??
                  false)
              as bool,
      status: parseStatus(json['status'] as String?),
      hireDate: json['hireDate'] as String?,
      terminationDate: json['terminationDate'] as String?,
      lastLogin: json['lastLogin'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      emergencyContactRelation: json['emergencyContactRelation'] as String?,
      organizationId:
          (json['organizationId'] ?? json['organization_id'] ?? '') as String,
      branchId: (json['branchId'] ?? json['branch_id'] ?? '') as String,
      createdAt: (json['createdAt'] ?? json['created_at'] ?? '') as String,
      updatedAt: (json['updatedAt'] ?? json['updated_at'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    String departmentToString(Department d) {
      switch (d) {
        case Department.SERVICE:
          return 'SERVICE';
        case Department.MANAGEMENT:
          return 'MANAGEMENT';
        case Department.KITCHEN:
        default:
          return 'KITCHEN';
      }
    }

    String statusToString(EmployeeStatus s) {
      switch (s) {
        case EmployeeStatus.INACTIVE:
          return 'INACTIVE';
        case EmployeeStatus.ON_LEAVE:
          return 'ON_LEAVE';
        case EmployeeStatus.ACTIVE:
        default:
          return 'ACTIVE';
      }
    }

    return {
      'id': id,
      'employeeId': employeeId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'role': role,
      'department': departmentToString(department),
      'isDepartmentManager': isDepartmentManager,
      'status': statusToString(status),
      'hireDate': hireDate,
      'terminationDate': terminationDate,
      'lastLogin': lastLogin,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactRelation': emergencyContactRelation,
      'organizationId': organizationId,
      'branchId': branchId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

// Branch Model

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
  final Map<String, dynamic>? openingHours; // Changed from String? to Map
  final bool isActive;
  final String? managerId; // Changed to nullable
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
    this.managerId, // Made nullable
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    try {
      return Branch(
        id: _parseString(json['id']),
        name: _parseString(json['name']),
        branchCode: _parseString(json['branch_code'] ?? json['branchCode']),
        address: _parseString(json['address']),
        city: _parseString(json['city']),
        state: _parseString(json['state']),
        country: _parseString(json['country']),
        zipCode: _parseString(json['zipCode']),
        email: _parseString(json['email']),
        openingHours:
            json['openingHours'] != null && json['openingHours'] is Map
            ? Map<String, dynamic>.from(json['openingHours'])
            : null,
        isActive: _parseBool(json['isActive']),
        managerId: _parseStringOrNull(json['managerId']),
        organizationId: _parseString(json['organizationId']),
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      print('Error parsing Branch: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) return '';
    if (value is num) return value.toString();
    return value.toString();
  }

  static String? _parseStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is Map) return null;
    if (value is num) return value.toString();
    return value.toString();
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is num) return value != 0;
    return false;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    if (value is DateTime) return value;
    return DateTime.now();
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

  // Helper methods to work with opening hours
  String? getOpeningTime(String day) {
    if (openingHours == null) return null;
    final dayHours = openingHours![day.toLowerCase()];
    if (dayHours is Map) {
      return dayHours['open'] as String?;
    }
    return null;
  }

  String? getClosingTime(String day) {
    if (openingHours == null) return null;
    final dayHours = openingHours![day.toLowerCase()];
    if (dayHours is Map) {
      return dayHours['close'] as String?;
    }
    return null;
  }

  String getFormattedHours(String day) {
    final open = getOpeningTime(day);
    final close = getClosingTime(day);
    if (open == null || close == null) return 'Closed';
    return '$open - $close';
  }
}

// Kitchen Shift Model
class KitchenShift {
  final String id;
  final String employeeId;
  final String branchId;
  final String date;
  final ShiftType shiftType;
  final String startTime;
  final String endTime;
  final bool isActive;
  final String? clockInTime;
  final String? clockOutTime;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final Employee employee;
  final Branch branch;

  KitchenShift({
    required this.id,
    required this.employeeId,
    required this.branchId,
    required this.date,
    required this.shiftType,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    this.clockInTime,
    this.clockOutTime,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.employee,
    required this.branch,
  });

  factory KitchenShift.fromJson(Map<String, dynamic> json) {
    return KitchenShift(
      id: json['id'],
      employeeId: json['employeeId'],
      branchId: json['branchId'],
      date: json['date'],
      shiftType: ShiftType.values.firstWhere(
        (s) => s.name == (json['shiftType'] ?? 'MORNING'),
        orElse: () => ShiftType.MORNING,
      ),
      startTime: json['startTime'],
      endTime: json['endTime'],
      isActive: json['isActive'] ?? false,
      clockInTime: json['clockInTime'],
      clockOutTime: json['clockOutTime'],
      notes: json['notes'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      employee: Employee.fromJson(json['employee']),
      branch: Branch.fromJson(json['branch']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'branchId': branchId,
      'date': date,
      'shiftType': shiftType.name,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
      'clockInTime': clockInTime,
      'clockOutTime': clockOutTime,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'employee': employee.toJson(),
      'branch': branch.toJson(),
    };
  }

  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (_) {
      return date;
    }
  }

  String get formattedTimeRange {
    try {
      final start = DateTime.parse(startTime);
      final end = DateTime.parse(endTime);
      return '${_format(start)} - ${_format(end)}';
    } catch (_) {
      return '$startTime - $endTime';
    }
  }

  String _format(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get shiftTypeDisplay {
    switch (shiftType) {
      case ShiftType.MORNING:
        return 'Morning';
      case ShiftType.AFTERNOON:
        return 'Afternoon';
      case ShiftType.EVENING:
        return 'Evening';
      case ShiftType.NIGHT:
        return 'Night';
      case ShiftType.FULL_DAY:
        return 'Full Day';
    }
  }
}

// Create Shift Request
class CreateKitchenShiftRequest {
  final String employeeId;
  final String branchId;
  final String date;
  final ShiftType shiftType;
  final String startTime;
  final String endTime;
  final String? notes;

  CreateKitchenShiftRequest({
    required this.employeeId,
    required this.branchId,
    required this.date,
    required this.shiftType,
    required this.startTime,
    required this.endTime,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'branchId': branchId,
      'date': date,
      'shiftType': shiftType.name,
      'startTime': startTime,
      'endTime': endTime,
      'notes': notes,
    };
  }
}

// Update Shift Request
class UpdateKitchenShiftRequest {
  final String? employeeId;
  final String? date;
  final ShiftType? shiftType;
  final String? startTime;
  final String? endTime;
  final bool? isActive;
  final String? notes;

  UpdateKitchenShiftRequest({
    this.employeeId,
    this.date,
    this.shiftType,
    this.startTime,
    this.endTime,
    this.isActive,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'date': date,
      'shiftType': shiftType?.name,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
      'notes': notes,
    };
  }
}
