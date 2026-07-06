class DevLoginConfig {
  const DevLoginConfig._();

  // Turn this off before production builds.
  static const bool enabled = true;
  static const String organizationCode = 'ORG-006';

  static const users = <DevLoginUser>[
    DevLoginUser(
      department: 'Inventory Manager',
      email: 'ogochukwu@gmail.com',
      password: 'password@1',
    ),
    DevLoginUser(
      department: 'Stock Keeper',
      email: 'Farouq@gmail.com',
      password: 'password@1',
    ),
    DevLoginUser(
      department: 'Payment Manager',
      email: 'jide@gmail.com',
      password: 'password@1',
    ),
    DevLoginUser(
      department: 'Inventory Manager',
      email: 'bashorun@gmail.com',
      password: 'password@1',
    ),
    DevLoginUser(
      department: 'Customer Service',
      email: 'omobabafufu@gmail.com',
      password: 'password@1',
    ),
    DevLoginUser(
      department: 'Branch Manager',
      email: 'bendestiny259@gmail.com',
      password: 'password@1',
    ),
  ];
}

class DevLoginUser {
  const DevLoginUser({
    required this.department,
    required this.email,
    required this.password,
  });

  final String department;
  final String email;
  final String password;
}
