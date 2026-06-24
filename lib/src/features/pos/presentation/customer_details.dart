import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/customer_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/customer_model.dart';

class CreateEditCustomerScreen extends StatefulWidget {
  final CustomerModel? customer;

  const CreateEditCustomerScreen({super.key, this.customer});

  @override
  State<CreateEditCustomerScreen> createState() =>
      _CreateEditCustomerScreenState();
}

class _CreateEditCustomerScreenState extends State<CreateEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _dietaryRestrictionsController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

  bool _allowsMarketing = false;
  bool _allowsSMS = false;
  bool _allowsEmail = false;
  DateTime? _selectedDate;

  bool get isEditMode => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _populateForm();
    }
  }

  void _populateForm() {
    final customer = widget.customer!;
    _nameController.text = customer.name;
    _phoneController.text = customer.phone;
    _emailController.text = customer.email;
    _addressController.text = customer.address ?? '';
    _cityController.text = customer.city ?? '';
    _dietaryRestrictionsController.text = customer.dietaryRestrictions ?? '';
    _allowsMarketing = customer.allowsMarketing;
    _allowsSMS = customer.allowsSMS;
    _allowsEmail = customer.allowsEmail;

    if (customer.dateOfBirth != null) {
      try {
        _selectedDate = DateTime.parse(customer.dateOfBirth!);
        _dateOfBirthController.text = DateFormat(
          'MMM dd, yyyy',
        ).format(_selectedDate!);
      } catch (e) {
        // Invalid date format
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _dietaryRestrictionsController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter email address';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter phone number';
    }
    if (value.trim().length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    return null;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (isEditMode) {
        context.read<CustomerBloc>().add(
          UpdateCustomer(
            id: widget.customer!.id,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            city: _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim(),
            dateOfBirth: _selectedDate?.toIso8601String(),
            dietaryRestrictions:
                _dietaryRestrictionsController.text.trim().isEmpty
                ? null
                : _dietaryRestrictionsController.text.trim(),
            allowsMarketing: _allowsMarketing,
            allowsSMS: _allowsSMS,
            allowsEmail: _allowsEmail,
          ),
        );
      } else {
        context.read<CustomerBloc>().add(
          CreateCustomer(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            city: _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim(),
            dateOfBirth: _selectedDate?.toUtc().toIso8601String(),
            dietaryRestrictions:
                _dietaryRestrictionsController.text.trim().isEmpty
                ? null
                : _dietaryRestrictionsController.text.trim(),
            allowsMarketing: _allowsMarketing,
            allowsSMS: _allowsSMS,
            allowsEmail: _allowsEmail,
          ),
        );
      }
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
          isEditMode ? 'Edit Customer' : 'New Customer',
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
          if (state is CustomerCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Customer created successfully',
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
            // Navigator.pop(context);
          }

          if (state is CustomerUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Customer updated successfully',
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
            // Navigator.pop(context);
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
          final isLoading = state is CustomerActionLoading;

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 600;
                final formWidth = isTablet ? 600.0 : constraints.maxWidth;

                return SingleChildScrollView(
                  child: Center(
                    child: Container(
                      width: formWidth,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24 : 20,
                        vertical: 24,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: kPrimary.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: kPrimary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isEditMode
                                          ? Icons.edit_outlined
                                          : Icons.person_add_outlined,
                                      color: kPrimary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isEditMode
                                              ? 'Update Customer'
                                              : 'New Customer',
                                          style: WorkSansAppTextStyles.medium
                                              .copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: kprimaryTextColor1,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isEditMode
                                              ? 'Update customer information'
                                              : 'Fill in customer details',
                                          style: WorkSansAppTextStyles.medium
                                              .copyWith(
                                                fontSize: 13,
                                                color: kprimaryTextColor2,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Basic Information Section
                            _buildSectionTitle('Basic Information'),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
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
                                  _buildTextField(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    hint: 'Enter customer full name',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter customer name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _phoneController,
                                    label: 'Phone Number',
                                    hint: 'Enter phone number',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: _validatePhone,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Email Address',
                                    hint: 'Enter email address',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _dateOfBirthController,
                                    label: 'Date of Birth (Optional)',
                                    hint: 'Select date of birth',
                                    icon: Icons.cake_outlined,
                                    readOnly: true,
                                    onTap: _selectDate,
                                    suffixIcon: Icons.calendar_today,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Location Information Section
                            _buildSectionTitle('Location Information'),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
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
                                  _buildTextField(
                                    controller: _addressController,
                                    label: 'Address (Optional)',
                                    hint: 'Enter street address',
                                    icon: Icons.location_on_outlined,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _cityController,
                                    label: 'City (Optional)',
                                    hint: 'Enter city',
                                    icon: Icons.location_city_outlined,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Dietary Preferences Section
                            _buildSectionTitle('Dietary Preferences'),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
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
                              child: _buildTextField(
                                controller: _dietaryRestrictionsController,
                                label: 'Dietary Restrictions (Optional)',
                                hint:
                                    'e.g., Vegetarian, Gluten-free, No peanuts',
                                icon: Icons.restaurant_outlined,
                                maxLines: 3,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Marketing Preferences Section
                            _buildSectionTitle('Marketing Preferences'),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
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
                                  _buildSwitchRow(
                                    icon: Icons.campaign_outlined,
                                    label: 'Marketing Communications',
                                    subtitle:
                                        'Receive promotional offers and news',
                                    value: _allowsMarketing,
                                    onChanged: (value) {
                                      setState(() {
                                        _allowsMarketing = value;
                                      });
                                    },
                                  ),
                                  const Divider(height: 24),
                                  _buildSwitchRow(
                                    icon: Icons.sms_outlined,
                                    label: 'SMS Notifications',
                                    subtitle: 'Receive order updates via SMS',
                                    value: _allowsSMS,
                                    onChanged: (value) {
                                      setState(() {
                                        _allowsSMS = value;
                                      });
                                    },
                                  ),
                                  const Divider(height: 24),
                                  _buildSwitchRow(
                                    icon: Icons.email_outlined,
                                    label: 'Email Notifications',
                                    subtitle: 'Receive order updates via email',
                                    value: _allowsEmail,
                                    onChanged: (value) {
                                      setState(() {
                                        _allowsEmail = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Action Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        isEditMode
                                            ? 'Update Customer'
                                            : 'Create Customer',
                                        style: WorkSansAppTextStyles.medium
                                            .copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: kprimaryTextColor1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kprimaryTextColor1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: kprimaryTextColor2,
            ),
            prefixIcon: Icon(icon, size: 20, color: kprimaryTextColor2),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, size: 20, color: kprimaryTextColor2)
                : null,
            filled: true,
            fillColor: const Color(0xFFF8F6F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
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
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: kprimaryTextColor2),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kprimaryTextColor1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 12,
                  color: kprimaryTextColor2,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeThumbColor: kPrimary),
      ],
    );
  }
}
