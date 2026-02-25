import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/customer_model.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(const LoadCustomers());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final state = context.read<CustomerBloc>().state;
      if (state is CustomersLoaded && state.hasMore) {
        context.read<CustomerBloc>().add(const LoadMoreCustomers());
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      context.read<CustomerBloc>().add(const LoadCustomers());
    } else {
      context.read<CustomerBloc>().add(SearchCustomers(query));
    }
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return '₦0.00';
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '₦${formatter.format(amount)}';
  }

  Color _getMembershipColor(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      default:
        return kprimaryTextColor2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kprimaryTextColor1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Customers',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kprimaryTextColor1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: kPrimary, size: 28),
            onPressed: () {
              context.push('/customer-dtls').then((_) {
                context.read<CustomerBloc>().add(const RefreshCustomers());
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or email...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kprimaryTextColor2,
                ),
                prefixIcon: const Icon(Icons.search, color: kprimaryTextColor2),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: kprimaryTextColor2,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8F6F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor1,
              ),
            ),
          ),

          // Customers List
          Expanded(
            child: BlocConsumer<CustomerBloc, CustomerState>(
              listener: (context, state) {
                if (state is CustomersError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.error,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is CustomersLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  );
                }

                if (state is CustomersError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load customers',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kprimaryTextColor1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.error,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            color: kprimaryTextColor2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            context.read<CustomerBloc>().add(
                              const LoadCustomers(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<CustomerModel> customers = [];
                bool hasMore = false;

                if (state is CustomersLoaded) {
                  customers = state.customers;
                  hasMore = state.hasMore;
                } else if (state is CustomersRefreshing) {
                  customers = state.currentCustomers;
                } else if (state is CustomersLoadingMore) {
                  customers = state.currentCustomers;
                  hasMore = true;
                }

                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: kprimaryTextColor2.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No customers found',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kprimaryTextColor1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start by adding your first customer',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            color: kprimaryTextColor2,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<CustomerBloc>().add(const RefreshCustomers());
                  },
                  color: kPrimary,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: customers.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= customers.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(color: kPrimary),
                          ),
                        );
                      }

                      final customer = customers[index];
                      return _buildCustomerCard(customer);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/customer-detail',
          arguments: customer.id,
        ).then((_) {
          context.read<CustomerBloc>().add(const RefreshCustomers());
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : 'C',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name and Phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kprimaryTextColor1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer.phone,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 13,
                          color: kprimaryTextColor2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Membership Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getMembershipColor(
                      customer.membershipTier,
                    ).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    customer.membershipTier,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getMembershipColor(customer.membershipTier),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Orders',
                    value: '${customer.totalOrders ?? 0}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.attach_money,
                    label: 'Spent',
                    value: _formatCurrency(customer.totalSpent),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.stars_outlined,
                    label: 'Points',
                    value: '${customer.loyaltyPoints ?? 0}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: kprimaryTextColor2),
        const SizedBox(height: 4),
        Text(
          value,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kprimaryTextColor1,
          ),
        ),
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 11,
            color: kprimaryTextColor2,
          ),
        ),
      ],
    );
  }
}
