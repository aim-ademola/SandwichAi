import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/main.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/bloc.dart';

class AddMenuItemDialog extends StatefulWidget {
  const AddMenuItemDialog({super.key});

  @override
  State<AddMenuItemDialog> createState() => _AddMenuItemDialogState();
}

class _AddMenuItemDialogState extends State<AddMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _preparationTimeController = TextEditingController();

  String? _selectedCategory;
  String? _imagePath;
  bool _isAvailable = true;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Appetizers',
    'Main Course',
    'Desserts',
    'Drinks',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _preparationTimeController.dispose();
    super.dispose();
  }

  void _handleDone() {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select a category',
              style: WorkSansAppTextStyles.medium.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      // Dispatch CreateMenuItem event to BLoC
      context.read<MenuItemsBloc>().add(
        CreateMenuItem(
          dishName: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory!,
          price: int.parse(_priceController.text.trim()),
          preparationTime: int.parse(_preparationTimeController.text.trim()),
          isAvailable: _isAvailable,
          imageUrl: _imagePath,
        ),
      );
    }
  }

  void _selectImage(BuildContext rootContext) {
    // Show image picker options
    showModalBottomSheet(
      context: rootContext,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (rootContext) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image Source',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: kPrimary),
              title: Text(
                'Camera',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  color: kprimaryTextColor1,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _imagePath = 'https://example.com/images/camera-photo.jpg';
                });
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    content: Text(
                      'Camera feature coming soon',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: kPrimary),
              title: Text(
                'Gallery',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  color: kprimaryTextColor1,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _imagePath = 'https://example.com/images/gallery-photo.jpg';
                });
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    content: Text(
                      'Gallery feature coming soon',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MenuItemsBloc, MenuItemsState>(
      listener: (context, state) {
        final rootContext = Navigator.of(context, rootNavigator: true).context;
        if (state is MenuItemCreated) {
          setState(() {
            _isSubmitting = false;
          });

          Navigator.of(context).pop();

          // Show success message
          WidgetsBinding.instance.addPostFrameCallback((_) {
            rootScaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text(
                  'Menu item "${state.menuItem.dishName}" added successfully',
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
          });
        } else if (state is MenuItemCreationError) {
          setState(() {
            _isSubmitting = false;
          });

          rootScaffoldMessengerKey.currentState?.showSnackBar(
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
                          'Add New Menu Item',
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

                  // Category Dropdown
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
                      hintText: 'Select category',
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
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: kprimaryTextColor2,
                    ),
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: kprimaryTextColor1,
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
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
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
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
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
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
                  const SizedBox(height: 20),

                  // Image Upload (Optional)
                  Text(
                    'Item Image (Optional)',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _isSubmitting ? null : () => _selectImage(context),
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F6F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                          width: 1,
                        ),
                      ),
                      child: _imagePath == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: kprimaryTextColor2,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add image',
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 14,
                                    color: kprimaryTextColor2,
                                  ),
                                ),
                              ],
                            )
                          : Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 60,
                                    color: kprimaryTextColor2,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: _isSubmitting
                                        ? null
                                        : () {
                                            setState(() {
                                              _imagePath = null;
                                            });
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Done Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        disabledBackgroundColor: kPrimary.withOpacity(0.5),
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
                              'Done',
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

extension AddMenuItemDialogExtension on BuildContext {
  void showAddMenuItemDialog() {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => const AddMenuItemDialog(),
    );
  }
}
