class LoginRequest {
  final String email;
  final String password;
  final String type;
  final String organizationCode;

  const LoginRequest({
    required this.email,
    required this.password,
    required this.organizationCode,
    this.type = 'EMPLOYEE',
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'type': type,
    'organizationCode': organizationCode,
  };

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      organizationCode: json['organizationCode']?.toString() ?? '',
      type: json['type']?.toString() ?? 'EMPLOYEE',
    );
  }

  LoginRequest copyWith({
    String? email,
    String? password,
    String? type,
    String? organizationCode,
  }) {
    return LoginRequest(
      email: email ?? this.email,
      password: password ?? this.password,
      type: type ?? this.type,
      organizationCode: organizationCode ?? this.organizationCode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginRequest &&
        other.email == email &&
        other.password == password &&
        other.type == type &&
        other.organizationCode == organizationCode;
  }

  @override
  int get hashCode => Object.hash(email, password, type, organizationCode);

  @override
  String toString() =>
      'LoginRequest(email: $email, password: [HIDDEN], type: $type, organizationCode: $organizationCode)';
}

/// Branch Model
class BranchModel {
  final String id;
  final String name;
  final String code;
  final String city;

  const BranchModel({
    required this.id,
    required this.name,
    required this.code,
    required this.city,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'city': city,
  };

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BranchModel &&
        other.id == id &&
        other.name == name &&
        other.code == code &&
        other.city == city;
  }

  @override
  int get hashCode => Object.hash(id, name, code, city);
}

/// User Model
class UserModel {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String type;
  final String? organizationId;
  final String? organizationCode;
  final String? organizationName;
  final String? employeeId;
  final String? branchId;
  final BranchModel? branch;
  final String? role;
  final String? department;
  final bool? isDepartmentManager;
  final String? status;

  const UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.fullName,
    required this.type,
    this.organizationId,
    this.organizationCode,
    this.organizationName,
    this.employeeId,
    this.branchId,
    this.branch,
    this.role,
    this.department,
    this.isDepartmentManager,
    this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    if (firstName != null) 'firstName': firstName,
    if (lastName != null) 'lastName': lastName,
    if (fullName != null) 'fullName': fullName,
    'type': type,
    if (organizationId != null) 'organizationId': organizationId,
    if (organizationCode != null) 'organizationCode': organizationCode,
    if (organizationName != null) 'organizationName': organizationName,
    if (employeeId != null) 'employeeId': employeeId,
    if (branchId != null) 'branchId': branchId,
    if (branch != null) 'branch': branch!.toJson(),
    if (role != null) 'role': role,
    if (department != null) 'department': department,
    if (isDepartmentManager != null) 'isDepartmentManager': isDepartmentManager,
    if (status != null) 'status': status,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),
        fullName: json['fullName']?.toString(),
        type: json['type']?.toString() ?? 'EMPLOYEE',
        organizationId: json['organizationId']?.toString(),
        organizationCode: json['organizationCode']?.toString(),
        organizationName: json['organizationName']?.toString(),
        employeeId: json['employeeId']?.toString(),
        branchId: json['branchId']?.toString(),
        branch: json['branch'] != null
            ? BranchModel.fromJson(json['branch'] as Map<String, dynamic>)
            : null,
        role: json['role']?.toString(),
        department: json['department']?.toString(),
        isDepartmentManager: json['isDepartmentManager'],
        status: json['status']?.toString(),
      );
    } catch (e) {
      return UserModel(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),
        fullName: json['fullName']?.toString(),
        type: json['type']?.toString() ?? 'EMPLOYEE',
        organizationId: json['organizationId']?.toString(),
        organizationCode: json['organizationCode']?.toString(),
        organizationName: json['organizationName']?.toString(),
        employeeId: json['employeeId']?.toString(),
        branchId: json['branchId']?.toString(),
        branch: null,
        role: json['role']?.toString(),
        department: json['department']?.toString(),
        isDepartmentManager: json['isDepartmentManager'],
        status: json['status']?.toString(),
      );
    }
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? fullName,
    String? type,
    String? organizationId,
    String? organizationCode,
    String? organizationName,
    String? employeeId,
    String? branchId,
    BranchModel? branch,
    String? role,
    String? department,
    bool? isDepartmentManager,
    String? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      type: type ?? this.type,
      organizationId: organizationId ?? this.organizationId,
      organizationCode: organizationCode ?? this.organizationCode,
      organizationName: organizationName ?? this.organizationName,
      employeeId: employeeId ?? this.employeeId,
      branchId: branchId ?? this.branchId,
      branch: branch ?? this.branch,
      role: role ?? this.role,
      department: department ?? this.department,
      isDepartmentManager: isDepartmentManager ?? this.isDepartmentManager,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.fullName == fullName &&
        other.type == type &&
        other.organizationId == organizationId &&
        other.organizationCode == organizationCode &&
        other.organizationName == organizationName &&
        other.employeeId == employeeId &&
        other.branchId == branchId &&
        other.branch == branch &&
        other.role == role &&
        other.department == department &&
        other.isDepartmentManager == isDepartmentManager &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    firstName,
    lastName,
    fullName,
    type,
    organizationId,
    organizationCode,
    organizationName,
    employeeId,
    branchId,
    branch,
    role,
    department,
    isDepartmentManager,
    status,
  );

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, type: $type, organizationCode: $organizationCode, employeeId: $employeeId, branchId: $branchId, role: $role, department: $department, status: $status)';
  }
}

/// Login Response Model
class LoginResponse {
  final String accessToken;
  final UserModel user;

  const LoginResponse({required this.accessToken, required this.user});

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'user': user.toJson(),
  };

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Handle both snake_case and camelCase
      final token =
          json['access_token']?.toString() ??
          json['accessToken']?.toString() ??
          '';

      if (token.isEmpty) {
        throw FormatException('Access token is missing from response');
      }

      final userJson = json['user'];
      if (userJson == null || userJson is! Map<String, dynamic>) {
        throw FormatException('User data is missing or invalid');
      }

      return LoginResponse(
        accessToken: token,
        user: UserModel.fromJson(userJson),
      );
    } catch (e) {
      throw FormatException('Invalid login response format: $e');
    }
  }

  LoginResponse copyWith({String? accessToken, UserModel? user}) {
    return LoginResponse(
      accessToken: accessToken ?? this.accessToken,
      user: user ?? this.user,
    );
  }

  bool get isValid => accessToken.isNotEmpty && user.id.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoginResponse &&
        other.accessToken == accessToken &&
        other.user == user;
  }

  @override
  int get hashCode => Object.hash(accessToken, user);

  @override
  String toString() {
    return 'LoginResponse(accessToken: ${accessToken.substring(0, 20)}..., user: $user)';
  }
}
