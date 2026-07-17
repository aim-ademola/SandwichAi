import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/api_menu_blocs/bloc.dart'
    as api_menu;
import 'package:sandwich_ai/src/features/pos/bloc/api_menu_blocs/event.dart'
    as api_menu_event;
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/pos_menu_categories.dart';

class EditMenuItemDialog extends StatefulWidget {
  final ApiMenuItem menuItem;

  const EditMenuItemDialog({super.key, required this.menuItem});

  @override
  State<EditMenuItemDialog> createState() => _EditMenuItemDialogState();
}

class _EditMenuItemDialogState extends State<EditMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _preparationTimeController;
  late String _selectedCategory;

  bool _isAvailable = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing menu item data
    _nameController = TextEditingController(text: widget.menuItem.dishName);
    _descriptionController = TextEditingController(
      text: widget.menuItem.description,
    );
    _priceController = TextEditingController(
      text: widget.menuItem.price.toString(),
    );
    _preparationTimeController = TextEditingController(
      text: widget.menuItem.preparationTime.toString(),
    );

    _isAvailable = widget.menuItem.isAvailable;
    _selectedCategory =
        PosMenuCategories.names.contains(widget.menuItem.category)
        ? widget.menuItem.category
        : PosMenuCategories.names.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _preparationTimeController.dispose();
    super.dispose();
  }

  void _handleUpdate() {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // Dispatch UpdateMenuItem event to BLoC
      context.read<MenuItemsBloc>().add(
        UpdateMenuItem(
          menuItemId: widget.menuItem.id,
          dishName: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          price: int.parse(_priceController.text.trim()),
          preparationTime: int.parse(_preparationTimeController.text.trim()),
          isAvailable: _isAvailable,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MenuItemsBloc, MenuItemsState>(
      listener: (context, state) {
        if (state is MenuItemUpdated) {
          context.read<api_menu.MenuItemsBloc>().add(
            const api_menu_event.RefreshMenuItems(),
          );

          setState(() {
            _isSubmitting = false;
          });

          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Menu item "${state.menuItem.dishName}" updated successfully',
                style: WorkSansAppTextStyles.medium.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: kGreen,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else if (state is MenuItemUpdateError) {
          setState(() {
            _isSubmitting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.error,
                style: WorkSansAppTextStyles.medium.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Edit Menu Item',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: kprimaryTextColor1,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: kprimaryTextColor2,
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Category
                  Text(
                    'Category',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
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
                    items: PosMenuCategories.names.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Row(
                          children: [
                            PosMenuCategoryIcon(
                              category: category,
                              color: kPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(category)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _selectedCategory = value);
                            }
                          },
                  ),
                  const SizedBox(height: 20),

                  // Item Name
                  Text(
                    'Item Name',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      hintText: 'Enter item name',
                      hintStyle: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: kprimaryTextColor2,
                      ),
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter item name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    'Description',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_isSubmitting,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter item description',
                      hintStyle: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: kprimaryTextColor2,
                      ),
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
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Price and Preparation Time Row
                  Row(
                    children: [
                      // Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price (₦)',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kprimaryTextColor1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _priceController,
                              enabled: !_isSubmitting,
                              decoration: InputDecoration(
                                hintText: 'Enter price',
                                hintStyle: WorkSansAppTextStyles.medium
                                    .copyWith(
                                      fontSize: 14,
                                      color: kprimaryTextColor2,
                                    ),
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
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final price = int.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'Invalid price';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Preparation Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prep Time (min)',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kprimaryTextColor1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _preparationTimeController,
                              enabled: !_isSubmitting,
                              decoration: InputDecoration(
                                hintText: 'Enter time',
                                hintStyle: WorkSansAppTextStyles.medium
                                    .copyWith(
                                      fontSize: 14,
                                      color: kprimaryTextColor2,
                                    ),
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
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final time = int.tryParse(value);
                                if (time == null || time <= 0) {
                                  return 'Invalid time';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Availability Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kprimaryTextColor1,
                        ),
                      ),
                      Switch(
                        value: _isAvailable,
                        onChanged: _isSubmitting
                            ? null
                            : (value) {
                                setState(() {
                                  _isAvailable = value;
                                });
                              },
                        activeThumbColor: kPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        disabledBackgroundColor: kPrimary.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Update',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension EditMenuItemDialogExtension on BuildContext {
  void showEditMenuItemDialog(ApiMenuItem menuItem) {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => EditMenuItemDialog(menuItem: menuItem),
    );
  }
}
