enum StaffStatus { all, unavailable, available }

class StaffMember {
  final String id;
  final String name;
  final String role;
  final String imageUrl;
  final bool isAvailable;

  StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.isAvailable,
  });
}
