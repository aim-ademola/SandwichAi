abstract class CustomerEvent {
  const CustomerEvent();
}

// List events
class LoadCustomers extends CustomerEvent {
  final int page;
  final int limit;
  final String? search;

  const LoadCustomers({this.page = 1, this.limit = 10, this.search});
}

class RefreshCustomers extends CustomerEvent {
  final String? search;

  const RefreshCustomers({this.search});
}

class LoadMoreCustomers extends CustomerEvent {
  const LoadMoreCustomers();
}

class SearchCustomers extends CustomerEvent {
  final String query;

  const SearchCustomers(this.query);
}

// Single customer events
class LoadCustomerById extends CustomerEvent {
  final String id;

  const LoadCustomerById(this.id);
}

class CreateCustomer extends CustomerEvent {
  final String phone;
  final String email;
  final String name;
  final String? dateOfBirth;
  final String? address;
  final String? city;
  final String? dietaryRestrictions;
  final bool? allowsMarketing;
  final bool? allowsSMS;
  final bool? allowsEmail;

  const CreateCustomer({
    required this.phone,
    required this.email,
    required this.name,
    this.dateOfBirth,
    this.address,
    this.city,
    this.dietaryRestrictions,
    this.allowsMarketing,
    this.allowsSMS,
    this.allowsEmail,
  });
}

class UpdateCustomer extends CustomerEvent {
  final String id;
  final String? phone;
  final String? email;
  final String? name;
  final String? dateOfBirth;
  final String? address;
  final String? city;
  final String? dietaryRestrictions;
  final bool? allowsMarketing;
  final bool? allowsSMS;
  final bool? allowsEmail;

  const UpdateCustomer({
    required this.id,
    this.phone,
    this.email,
    this.name,
    this.dateOfBirth,
    this.address,
    this.city,
    this.dietaryRestrictions,
    this.allowsMarketing,
    this.allowsSMS,
    this.allowsEmail,
  });
}

class DeleteCustomer extends CustomerEvent {
  final String id;

  const DeleteCustomer(this.id);
}
