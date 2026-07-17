import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/customer_model.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadCustomerById(widget.customerId));
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return '₦0.00';
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '₦${formatter.format(amount)}';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
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

  void _showDeleteDialog(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Customer',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kprimaryTextColor1,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${customer.name}? This action cannot be undone.',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: kprimaryTextColor2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor2,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CustomerBloc>().add(DeleteCustomer(customer.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete',
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
          'Customer Details',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kprimaryTextColor1,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Customer deleted successfully',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: kGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            Navigator.pop(context);
          }

          if (state is CustomerActionError) {
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
          if (state is CustomerDetailLoading ||
              state is CustomerActionLoading) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }

          if (state is CustomerDetailError) {
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
                    'Failed to load customer',
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
                ],
              ),
            );
          }

          if (state is! CustomerDetailLoaded) {
            return const SizedBox.shrink();
          }

          final customer = state.customer;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : 'C',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        customer.name,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: kprimaryTextColor1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer.phone,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 15,
                          color: kprimaryTextColor2,
                        ),
                      ),
                      ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getMembershipColor(
                              customer.membershipTier,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                size: 18,
                                color: _getMembershipColor(
                                  customer.membershipTier,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${customer.membershipTier} Member',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _getMembershipColor(
                                    customer.membershipTier,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context
                                    .push('/edit-customer', extra: customer)
                                    .then((_) {
                                      context.read<CustomerBloc>().add(
                                        LoadCustomerById(widget.customerId),
                                      );
                                    });
                              },
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: Text(
                                'Edit',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimary,
                                side: BorderSide(
                                  color: kPrimary.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showDeleteDialog(customer),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: Text(
                                'Delete',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Stats Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistics',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kprimaryTextColor1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.shopping_bag_outlined,
                              label: 'Total Orders',
                              value: '${customer.totalOrders}',
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.attach_money,
                              label: 'Total Spent',
                              value: _formatCurrency(customer.totalSpent),
                              color: const Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.stars,
                              label: 'Loyalty Points',
                              value: '${customer.loyaltyPoints}',
                              color: const Color(0xFFFF9800),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.star_rate,
                              label: 'Avg Rating',
                              value: customer.avgRating != null
                                  ? customer.avgRating!.toStringAsFixed(1)
                                  : 'N/A',
                              color: const Color(0xFFFFC107),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Contact Information
                _buildSection(
                  title: 'Contact Information',
                  children: [
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: customer.email,
                    ),
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: customer.phone,
                    ),
                    if (customer.address != null)
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value: customer.address!,
                      ),
                    if (customer.city != null)
                      _buildInfoRow(
                        icon: Icons.location_city_outlined,
                        label: 'City',
                        value: customer.city!,
                      ),
                  ],
                ),

                // Personal Information
                _buildSection(
                  title: 'Personal Information',
                  children: [
                    if (customer.dateOfBirth != null)
                      _buildInfoRow(
                        icon: Icons.cake_outlined,
                        label: 'Date of Birth',
                        value: _formatDate(customer.dateOfBirth),
                      ),
                    if (customer.dietaryRestrictions != null)
                      _buildInfoRow(
                        icon: Icons.restaurant_outlined,
                        label: 'Dietary Restrictions',
                        value: customer.dietaryRestrictions!,
                      ),
                  ],
                ),

                // Preferences
                _buildSection(
                  title: 'Marketing Preferences',
                  children: [
                    _buildPreferenceRow(
                      icon: Icons.campaign_outlined,
                      label: 'Marketing Communications',
                      value: customer.allowsMarketing,
                    ),
                    _buildPreferenceRow(
                      icon: Icons.sms_outlined,
                      label: 'SMS Notifications',
                      value: customer.allowsSMS,
                    ),
                    _buildPreferenceRow(
                      icon: Icons.email_outlined,
                      label: 'Email Notifications',
                      value: customer.allowsEmail,
                    ),
                  ],
                ),

                // Account Information
                _buildSection(
                  title: 'Account Information',
                  children: [
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Member Since',
                      value: _formatDate(customer.createdAt),
                    ),
                    if (customer.lastOrderDate != null)
                      _buildInfoRow(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Last Order',
                        value: _formatDate(customer.lastOrderDate),
                      ),
                    if (customer.avgOrderValue != null)
                      _buildInfoRow(
                        icon: Icons.receipt_outlined,
                        label: 'Average Order Value',
                        value: _formatCurrency(customer.avgOrderValue),
                      ),
                    _buildInfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Account Status',
                      value: customer.isActive == true ? 'Active' : 'Inactive',
                      valueColor: customer.isActive == true
                          ? const Color(0xFF4CAF50)
                          : Colors.grey,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: kprimaryTextColor2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kprimaryTextColor2),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    color: kprimaryTextColor2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: valueColor ?? kprimaryTextColor1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRow({
    required IconData icon,
    required String label,
    required bool value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kprimaryTextColor2),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor1,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: value
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value ? 'Enabled' : 'Disabled',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value ? const Color(0xFF4CAF50) : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
