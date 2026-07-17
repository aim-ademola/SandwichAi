import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/customer_model.dart';
import 'package:sandwich_ai/src/features/pos/presentation/widgets/pos_design_system.dart';

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
        return context.modeTextMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PosPageScaffold(
      title: 'Customers',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: PosIconActionButton(
            icon: HugeIcons.strokeRoundedAdd01,
            color: context.modePrimary,
            tooltip: 'Add customer',
            onPressed: () async {
              final customerBloc = context.read<CustomerBloc>();
              await context.push('/customer-dtls');
              if (!mounted) return;
              customerBloc.add(const RefreshCustomers());
            },
          ),
        ),
      ],
      body: Column(
        children: [
          // Search Bar
          Container(
            color: context.modeSurface,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              cursorColor: context.modePrimary,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or email...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: context.modeTextMuted,
                ),
                prefixIcon: Icon(Icons.search, color: context.modeTextMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: context.modeTextMuted),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: context.modeSurfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.modeBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.modeBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.modePrimary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextPrimary,
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
                          color: context.modeTextInverse,
                        ),
                      ),
                      backgroundColor: context.modeError,
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
                  return Center(
                    child: CircularProgressIndicator(
                      color: context.modePrimary,
                    ),
                  );
                }

                if (state is CustomersError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedAlert02,
                          size: 52,
                          color: context.modeError,
                          strokeWidth: 1.9,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load customers',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.modeTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.error,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            color: context.modeTextSecondary,
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
                            backgroundColor: context.modePrimary,
                            foregroundColor: context.modeTextInverse,
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
                              color: context.modeTextInverse,
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
                        PosEmptyState(
                          icon: HugeIcons.strokeRoundedUserMultiple02,
                          title: 'No customers found',
                          message: 'Start by adding your first customer',
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<CustomerBloc>().add(const RefreshCustomers());
                  },
                  color: context.modePrimary,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: customers.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= customers.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: context.modePrimary,
                            ),
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
      onTap: () async {
        final customerBloc = context.read<CustomerBloc>();
        await context.push('/customer-detail/${customer.id}');
        if (!mounted) return;
        customerBloc.add(const RefreshCustomers());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.modeSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.modeBorder.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.24
                    : 0.04,
              ),
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
                    color: context.modePrimary.withValues(alpha: 0.1),
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
                        color: context.modePrimary,
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
                          color: context.modeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer.phone,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 13,
                          color: context.modeTextSecondary,
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
                    ).withValues(alpha: 0.15),
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
                    icon: HugeIcons.strokeRoundedShoppingBag01,
                    label: 'Orders',
                    value: '${customer.totalOrders}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: HugeIcons.strokeRoundedMoney03,
                    label: 'Spent',
                    value: _formatCurrency(customer.totalSpent),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: HugeIcons.strokeRoundedStar,
                    label: 'Points',
                    value: '${customer.loyaltyPoints}',
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
    required List<List<dynamic>> icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        HugeIcon(
          icon: icon,
          size: 18,
          color: context.modeTextMuted,
          strokeWidth: 1.8,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.modeTextPrimary,
          ),
        ),
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 11,
            color: context.modeTextMuted,
          ),
        ),
      ],
    );
  }
}
