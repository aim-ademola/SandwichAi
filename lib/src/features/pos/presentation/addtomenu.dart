import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/app_bootstrap.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/api_menu_blocs/bloc.dart'
    as api_menu;
import 'package:sandwich_ai/src/features/pos/bloc/api_menu_blocs/event.dart'
    as api_menu_event;
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/data/model/pos_menu_categories.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/add_menu_repo.dart'
    as add_menu_repo;

class AddMenuItemDialog extends StatefulWidget {
  final add_menu_repo.MenuItemsRepositoryInterface repository;
  final ValueChanged<ApiMenuItem>? onLocalCreated;
  final void Function(String localId, ApiMenuItem menuItem)? onBackendCreated;
  final ValueChanged<String>? onCreateFailed;

  const AddMenuItemDialog({
    super.key,
    required this.repository,
    this.onLocalCreated,
    this.onBackendCreated,
    this.onCreateFailed,
  });

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

  final List<String> _categories = PosMenuCategories.names;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _preparationTimeController.dispose();
    super.dispose();
  }

  Future<void> _handleDone() async {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select a category',
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
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      final now = DateTime.now();
      final localId = 'local-menu-${now.microsecondsSinceEpoch}';
      final branchId = await AuthCacheHelper.instance.getBranchID() ?? '';
      final organizationId = await AuthCacheHelper.instance.getOrgId() ?? '';
      final dishName = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final category = _selectedCategory!;
      final price = int.parse(_priceController.text.trim());
      final preparationTime = int.parse(_preparationTimeController.text.trim());
      final imageUrl = _imagePath ?? '';
      final localItem = ApiMenuItem(
        id: localId,
        dishName: dishName,
        description: description,
        category: category,
        price: price.toString(),
        preparationTime: preparationTime,
        isAvailable: _isAvailable,
        imageUrl: imageUrl,
        branchId: branchId,
        organizationId: organizationId,
        createdAt: now,
        updatedAt: now,
      );

      widget.onLocalCreated?.call(localItem);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final response = await widget.repository.createMenuItem(
        branchId: branchId,
        dishName: dishName,
        description: description,
        category: category,
        price: price,
        preparationTime: preparationTime,
        isAvailable: _isAvailable,
        imageUrl: imageUrl,
      );

      response.when(
        success: (menuItem) {
          widget.onBackendCreated?.call(localId, menuItem);
          rootScaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(
                'Menu item "${menuItem.dishName}" added successfully',
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
        },
        error: (error) {
          widget.onCreateFailed?.call(localId);
          rootScaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(
                error.toString(),
                style: WorkSansAppTextStyles.medium.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: kRed,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      );
    }
  }

  void _selectImage(BuildContext rootContext) {
    // Show image picker options
    showModalBottomSheet(
      context: rootContext,
      backgroundColor: rootContext.modeSurface,
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
                color: rootContext.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: AppIcon(
                Icons.camera_alt,
                color: rootContext.modePrimary,
              ),
              title: Text(
                'Camera',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  color: rootContext.modeTextPrimary,
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
                        color: rootContext.modeTextInverse,
                      ),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: AppIcon(
                Icons.photo_library,
                color: rootContext.modePrimary,
              ),
              title: Text(
                'Gallery',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 16,
                  color: rootContext.modeTextPrimary,
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
                        color: rootContext.modeTextInverse,
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
    return Dialog(
      backgroundColor: context.modeSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width > 560
            ? 520
            : MediaQuery.sizeOf(context).width * 0.9,
        height: MediaQuery.sizeOf(context).height * 0.86,
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
                            color: context.modeTextPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: AppIcon(
                          Icons.close,
                          color: context.modeTextMuted,
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
                      color: context.modeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: 'Select category',
                      hintStyle: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: context.modeTextMuted,
                      ),
                      filled: true,
                      fillColor: context.modeSurfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.modeBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.modeBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.modePrimary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    icon: AppIcon(
                      Icons.arrow_drop_down,
                      color: context.modeTextMuted,
                    ),
                    dropdownColor: context.modeSurface,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: context.modeTextPrimary,
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PosMenuCategoryIcon(
                              category: category,
                              color: context.modePrimary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (context) {
                      return _categories.map((category) {
                        return Row(
                          children: [
                            PosMenuCategoryIcon(
                              category: category,
                              color: context.modePrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
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
                      color: context.modeTextPrimary,
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
                        color: context.modeTextMuted,
                      ),
                      filled: true,
                      fillColor: context.modeSurfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.modeBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.modeBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
                      color: context.modeTextPrimary,
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
                        color: context.modeTextMuted,
                      ),
                      filled: true,
                      fillColor: context.modeSurfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.modeBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: context.modeBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
                              'Price (â‚¦)',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.modeTextPrimary,
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
                                      color: context.modeTextMuted,
                                    ),
                                filled: true,
                                fillColor: context.modeSurfaceAlt,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: context.modeBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: context.modeBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: context.modePrimary,
                                  ),
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
                                color: context.modeTextPrimary,
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
                                      color: context.modeTextMuted,
                                    ),
                                filled: true,
                                fillColor: context.modeSurfaceAlt,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: context.modeBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: context.modeBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: context.modePrimary,
                                  ),
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
                          color: context.modeTextPrimary,
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
                        activeThumbColor: context.modePrimary,
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
                      color: context.modeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _isSubmitting ? null : () => _selectImage(context),
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: context.modeSurfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.modeBorder,
                          style: BorderStyle.solid,
                          width: 1,
                        ),
                      ),
                      child: _imagePath == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppIcon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: context.modeTextMuted,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add image',
                                  style: WorkSansAppTextStyles.medium.copyWith(
                                    fontSize: 14,
                                    color: context.modeTextMuted,
                                  ),
                                ),
                              ],
                            )
                          : Stack(
                              children: [
                                Center(
                                  child: AppIcon(
                                    Icons.image,
                                    size: 60,
                                    color: context.modeTextMuted,
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
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: AppIcon(
                                        Icons.close,
                                        size: 20,
                                        color: context.modeTextInverse,
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
                        backgroundColor: context.modePrimary,
                        foregroundColor: context.modeTextInverse,
                        disabledBackgroundColor: context.modePrimary.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  context.modeTextInverse,
                                ),
                              ),
                            )
                          : Text(
                              'Done',
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.modeTextInverse,
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
    final apiMenuBloc = read<api_menu.MenuItemsBloc>();
    final repository = read<add_menu_repo.MenuItemsRepositoryInterface>();
    showDialog(
      context: this,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) => AddMenuItemDialog(
        repository: repository,
        onLocalCreated: (menuItem) {
          apiMenuBloc.add(api_menu_event.UpsertLocalMenuItem(menuItem));
        },
        onBackendCreated: (localId, menuItem) {
          apiMenuBloc.add(
            api_menu_event.ReplaceLocalMenuItem(
              localId: localId,
              menuItem: menuItem,
            ),
          );
          apiMenuBloc.add(const api_menu_event.RefreshMenuItems());
        },
        onCreateFailed: (localId) {
          apiMenuBloc.add(api_menu_event.RemoveLocalMenuItem(localId));
        },
      ),
    );
  }
}
