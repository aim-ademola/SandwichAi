class DevLoginConfig {
  const DevLoginConfig._();

  // Turn this off before production builds.
  static const bool enabled = true;
  static const String organizationCode = 'ORG-003';

  static const users = <DevLoginUser>[
    DevLoginUser(
      department: 'Kitchen department',
      email: 'adewuyieniola00@gmail.com',
      password: 'Eniola@Onboarding',
    ),
    DevLoginUser(
      department: 'Inventory department',
      email: 'orjianichristian@gmail.com',
      password: 'Christian@Onboarding',
    ),
    DevLoginUser(
      department: 'Procurement department',
      email: 'henrietta.apata@rubelsandangels.com',
      password: 'Henrietta@Onboarding',
    ),
    DevLoginUser(
      department: 'Processing department',
      email: 'aituayuwaosas@gmail.com',
      password: 'David@Onboarding',
    ),
    DevLoginUser(
      department: 'Customer service',
      email: 'joel@mailinator.com',
      password: 'John@Onboarding',
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
