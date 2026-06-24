// presentation/create_output_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/features/processing/bloc/output_ver_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/output_ver_blocs/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/output_ver_blocs/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/output_verfification_model.dart';

class CreateOutputVerificationScreen extends StatefulWidget {
  const CreateOutputVerificationScreen({super.key});

  @override
  State<CreateOutputVerificationScreen> createState() =>
      _CreateOutputVerificationScreenState();
}

class _CreateOutputVerificationScreenState
    extends State<CreateOutputVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _batchIdController = TextEditingController();
  final _expectedOutputController = TextEditingController();
  final _actualOutputController = TextEditingController();
  final _reasonController = TextEditingController();
  final _assignedToController = TextEditingController();
  final _verifiedByController = TextEditingController();

  MenuItem? _selectedMenuItem;
  Recipe? _selectedRecipe;
  bool _isSearching = false;
  bool _isDropdownOpen = false;
  bool _isLoadingRecipe = false; // NEW: Track recipe loading state
  List<MenuItem> _filteredItems = [];
  List<MenuItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    context.read<OutputVerificationBloc>().add(const LoadMenuItems());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _batchIdController.dispose();
    _expectedOutputController.dispose();
    _actualOutputController.dispose();
    _reasonController.dispose();
    _assignedToController.dispose();
    _verifiedByController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems
            .where(
              (item) => item.dishName.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar(
        'Please fill in all required fields correctly',
        isError: true,
      );
      return;
    }

    if (_selectedMenuItem == null || _selectedRecipe == null) {
      _showSnackBar('Please select a menu item', isError: true);
      return;
    }

    try {
      final expectedOutput = int.tryParse(
        _expectedOutputController.text.trim(),
      );
      final actualOutput = int.tryParse(_actualOutputController.text.trim());

      if (expectedOutput == null || actualOutput == null) {
        _showSnackBar('Please enter valid numeric values', isError: true);
        return;
      }
      final id = await AuthCacheHelper.instance.getEmpID() ?? '';

      final request = CreateOutputVerificationRequest(
        branchId: context.read<OutputVerificationBloc>().branchId,
        batchId: _batchIdController.text.trim(),
        productName: _selectedMenuItem!.dishName,
        recipeId: _selectedRecipe!.id,
        expectedOutput: expectedOutput,
        actualOutput: actualOutput,
        reason: _reasonController.text.trim(),
        assignedTo: _assignedToController.text.trim(),
        verifiedBy: id,
      );

      context.read<OutputVerificationBloc>().add(
        CreateOutputVerification(request: request),
      );
    } catch (e) {
      _showSnackBar('Invalid input: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: WorkSansAppTextStyles.medium.copyWith(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError ? const Color(0xFFE53935) : kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OutputVerificationBloc, OutputVerificationState>(
      // In your BlocListener in the screen
      listener: (context, state) {
        if (state is OutputVerificationCreated) {
          _showSnackBar(state.message);
          _resetForm();
        } else if (state is RecipeLoadError) {
          // Show error but keep the UI functional
          _showSnackBar(state.error, isError: true);
          setState(() {
            _allItems = state.menuItems;
            _filteredItems = state.menuItems;
            _selectedMenuItem = state.selectedMenuItem;
            _selectedRecipe = null;
            _isLoadingRecipe = false;
          });
        } else if (state is OutputVerificationError) {
          _showSnackBar(state.error, isError: true);
          setState(() {
            _isLoadingRecipe = false;
          });
        } else if (state is RecipeLoading) {
          setState(() {
            _allItems = state.menuItems;
            _filteredItems = state.menuItems;
            _selectedMenuItem = state.selectedMenuItem;
            _selectedRecipe = null;
            _isLoadingRecipe = true;
          });
        } else if (state is MenuItemsLoaded) {
          setState(() {
            _allItems = state.menuItems;
            _filteredItems = state.menuItems;
            _selectedMenuItem = state.selectedMenuItem;
            _selectedRecipe = state.recipe;
            _isLoadingRecipe = false;
          });
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final horizontalPadding = _getHorizontalPadding(screenWidth);
          final maxContentWidth = _getMaxContentWidth(screenWidth);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: _getVerticalPadding(screenWidth),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Product Information', screenWidth),
                      SizedBox(height: _getSectionSpacing(screenWidth)),
                      _buildMenuItemSearchField(screenWidth),
                      SizedBox(height: _getFieldSpacing(screenWidth)),

                      // NEW: Show recipe loading indicator or selected recipe info
                      if (_isLoadingRecipe)
                        _buildLoadingRecipeIndicator(screenWidth)
                      else if (_selectedRecipe != null)
                        _buildSelectedRecipeInfo(screenWidth),

                      if (_selectedRecipe != null || _isLoadingRecipe)
                        SizedBox(height: _getFieldSpacing(screenWidth)),

                      _buildSectionTitle('Batch Details', screenWidth),
                      SizedBox(height: _getSectionSpacing(screenWidth)),
                      _buildTextField(
                        controller: _batchIdController,
                        label: 'Batch ID',
                        hint: 'Enter batch identifier',
                        screenWidth: screenWidth,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter batch ID';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: _getFieldSpacing(screenWidth)),

                      _buildSectionTitle('Output Information', screenWidth),
                      SizedBox(height: _getSectionSpacing(screenWidth)),
                      _buildTextField(
                        controller: _expectedOutputController,
                        label: 'Expected Output',
                        hint: 'Enter expected quantity',
                        keyboardType: TextInputType.number,
                        screenWidth: screenWidth,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter expected output';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: _getFieldSpacing(screenWidth)),
                      _buildTextField(
                        controller: _actualOutputController,
                        label: 'Actual Output',
                        hint: 'Enter actual quantity produced',
                        keyboardType: TextInputType.number,
                        screenWidth: screenWidth,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter actual output';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: _getFieldSpacing(screenWidth)),
                      _buildTextField(
                        controller: _reasonController,
                        label: 'Reason for Variance',
                        hint: 'Explain any differences',
                        screenWidth: screenWidth,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter reason';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: _getFieldSpacing(screenWidth)),

                      _buildSectionTitle('Personnel', screenWidth),
                      SizedBox(height: _getSectionSpacing(screenWidth)),
                      _buildTextField(
                        controller: _assignedToController,
                        label: 'Assigned To',
                        hint: 'Enter name of assigned person',
                        screenWidth: screenWidth,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter assigned person';
                          }
                          return null;
                        },
                      ),
                      // SizedBox(height: _getFieldSpacing(screenWidth)),
                      // _buildTextField(
                      //   controller: _verifiedByController,
                      //   label: 'Verified By',
                      //   hint: 'Enter name of verifier',
                      //   screenWidth: screenWidth,
                      //   validator: (value) {
                      //     if (value == null || value.isEmpty) {
                      //       return 'Please enter verifier';
                      //     }
                      //     return null;
                      //   },
                      // ),
                      SizedBox(height: _getSectionSpacing(screenWidth) * 2),
                      _buildSubmitButton(screenWidth),
                      SizedBox(height: _getVerticalPadding(screenWidth)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingRecipeIndicator(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getInputPaddingHorizontal(screenWidth)),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _getIconSize(screenWidth),
            height: _getIconSize(screenWidth),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Loading recipe...',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              color: kprimaryTextColor1,
            ),
          ),
        ],
      ),
    );
  }

  // Replace the _buildSelectedRecipeInfo method with this:
  Widget _buildSelectedRecipeInfo(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getInputPaddingHorizontal(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: _getIconSize(screenWidth),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recipe loaded',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getInputFontSize(screenWidth),
                    fontWeight: FontWeight.w600,
                    color: kprimaryTextColor1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Serving Size: ${_selectedRecipe!.servingSize}',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getCaptionFontSize(screenWidth),
                    color: kprimaryTextColor2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, double screenWidth) {
    return Text(
      title,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: _getSectionTitleFontSize(screenWidth),
        fontWeight: FontWeight.w600,
        color: kprimaryTextColor1,
      ),
    );
  }

  Widget _buildMenuItemSearchField(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Product *',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w500,
            color: kprimaryTextColor1,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _isDropdownOpen = !_isDropdownOpen;
              _isSearching = true;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getInputPaddingHorizontal(screenWidth),
              vertical: _getInputPaddingVertical(screenWidth),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              border: Border.all(
                color: _selectedMenuItem == null && !_isSearching
                    ? const Color(0xFFE0E0E0)
                    : kPrimary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: kprimaryTextColor2,
                  size: _getIconSize(screenWidth),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedMenuItem?.dishName ??
                        'Search and select a product',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getInputFontSize(screenWidth),
                      fontWeight: FontWeight.w400,
                      color: _selectedMenuItem != null
                          ? kprimaryTextColor1
                          : kprimaryTextColor2,
                    ),
                  ),
                ),
                Icon(
                  _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: kprimaryTextColor2,
                  size: _getIconSize(screenWidth) + 4,
                ),
              ],
            ),
          ),
        ),
        if (_isSearching && _isDropdownOpen) ...[
          const SizedBox(height: 12),
          _buildSearchDropdown(screenWidth),
        ],
      ],
    );
  }

  Widget _buildSearchDropdown(double screenWidth) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(_getInputPaddingHorizontal(screenWidth)),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getInputFontSize(screenWidth),
                color: kprimaryTextColor1,
              ),
              decoration: InputDecoration(
                hintText: 'Type to search...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getInputFontSize(screenWidth),
                  color: kprimaryTextColor2,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: kprimaryTextColor2,
                  size: _getIconSize(screenWidth),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: kprimaryTextColor2,
                          size: _getIconSize(screenWidth),
                        ),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(screenWidth),
                  ),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    _getBorderRadius(screenWidth),
                  ),
                  borderSide: BorderSide(color: kPrimary, width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: _getInputPaddingHorizontal(screenWidth),
                  vertical: _getInputPaddingVertical(screenWidth),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(
                        _getInputPaddingHorizontal(screenWidth),
                      ),
                      child: Text(
                        'No products found',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: _getInputFontSize(screenWidth),
                          color: kprimaryTextColor2,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMenuItem = item;
                            _isSearching = false;
                            _isDropdownOpen = false;
                            _searchController.clear();
                            _isLoadingRecipe = true;
                            _selectedRecipe = null;
                          });
                          context.read<OutputVerificationBloc>().add(
                            SelectMenuItem(menuItem: item),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _getInputPaddingHorizontal(screenWidth),
                            vertical: _getInputPaddingVertical(screenWidth),
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      color: kPrimary.withValues(alpha: 0.1),
                                      child: Icon(
                                        Icons.restaurant,
                                        color: kPrimary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.dishName,
                                      style: WorkSansAppTextStyles.medium
                                          .copyWith(
                                            fontSize: _getInputFontSize(
                                              screenWidth,
                                            ),
                                            fontWeight: FontWeight.w600,
                                            color: kprimaryTextColor1,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.category,
                                      style: WorkSansAppTextStyles.medium
                                          .copyWith(
                                            fontSize: _getCaptionFontSize(
                                              screenWidth,
                                            ),
                                            color: kprimaryTextColor2,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required double screenWidth,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w500,
            color: kprimaryTextColor1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth),
            fontWeight: FontWeight.w400,
            color: kprimaryTextColor1,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              fontWeight: FontWeight.w400,
              color: kprimaryTextColor2,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: kPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: const BorderSide(
                color: Color(0xFFE53935),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: const BorderSide(
                color: Color(0xFFE53935),
                width: 1.5,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: _getInputPaddingHorizontal(screenWidth),
              vertical: _getInputPaddingVertical(screenWidth),
            ),
          ),
          validator: validator,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(double screenWidth) {
    return BlocBuilder<OutputVerificationBloc, OutputVerificationState>(
      builder: (context, state) {
        final isLoading = state is OutputVerificationCreating;

        return SizedBox(
          width: double.infinity,
          height: _getButtonHeight(screenWidth),
          child: ElevatedButton(
            onPressed: isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              disabledBackgroundColor: kPrimary.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  _getBorderRadius(screenWidth),
                ),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? SizedBox(
                    height: _getIconSize(screenWidth),
                    width: _getIconSize(screenWidth),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Submit Verification',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getButtonFontSize(screenWidth),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _batchIdController.clear();
    _expectedOutputController.clear();
    _actualOutputController.clear();
    _reasonController.clear();
    _assignedToController.clear();
    _verifiedByController.clear();
    setState(() {
      _selectedMenuItem = null;
      _selectedRecipe = null;
      _isLoadingRecipe = false;
    });
    context.read<OutputVerificationBloc>().add(const ResetForm());
  }

  // Responsive sizing functions
  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getMaxContentWidth(double width) {
    if (width < 600) return double.infinity;
    if (width < 900) return 600;
    return 700;
  }

  double _getVerticalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  double _getSectionSpacing(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }

  double _getFieldSpacing(double width) {
    if (width < 360) return 16;
    if (width < 600) return 18;
    return 20;
  }

  double _getSectionTitleFontSize(double width) {
    if (width < 360) return 16;
    if (width < 600) return 17;
    return 18;
  }

  double _getLabelFontSize(double width) {
    if (width < 360) return 13;
    if (width < 600) return 14;
    return 15;
  }

  double _getInputFontSize(double width) {
    if (width < 360) return 14;
    if (width < 600) return 15;
    return 16;
  }

  double _getCaptionFontSize(double width) {
    if (width < 360) return 11;
    if (width < 600) return 12;
    return 13;
  }

  double _getButtonFontSize(double width) {
    if (width < 360) return 15;
    if (width < 600) return 16;
    return 17;
  }

  double _getIconSize(double width) {
    if (width < 360) return 20;
    if (width < 600) return 22;
    return 24;
  }

  double _getButtonHeight(double width) {
    if (width < 360) return 48;
    if (width < 600) return 52;
    return 56;
  }

  double _getBorderRadius(double width) {
    if (width < 360) return 8;
    if (width < 600) return 10;
    return 12;
  }

  double _getInputPaddingHorizontal(double width) {
    if (width < 360) return 14;
    if (width < 600) return 16;
    return 18;
  }

  double _getInputPaddingVertical(double width) {
    if (width < 360) return 12;
    if (width < 600) return 14;
    return 16;
  }
}
