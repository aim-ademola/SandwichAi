import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/utils/debouncer.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_compliance_bloc.dart/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_compliance_bloc.dart/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_compliance_bloc.dart/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/recipe_compliance_models.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';

class RecipeComplianceScreen extends StatefulWidget {
  const RecipeComplianceScreen({super.key});

  @override
  State<RecipeComplianceScreen> createState() => _RecipeComplianceScreenState();
}

class _RecipeComplianceScreenState extends State<RecipeComplianceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _batchesPreparedController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _expectedInputController = TextEditingController();
  final _actualInputController = TextEditingController();
  final _notesController = TextEditingController();
  late final Debouncer _searchDebouncer;

  MenuItem? _selectedMenuItem;
  bool _isSearching = false;
  bool _isOpened = false;
  List<MenuItem> _filteredMenuItems = [];

  @override
  void initState() {
    super.initState();
    _searchDebouncer = Debouncer(
      delay: const Duration(milliseconds: 350),
    );
    _searchController.addListener(_onSearchChanged);

    // Load menu items on init
    // final bloc = context.read<RecipeComplianceBloc>();
    context.read<RecipeComplianceBloc>().add(LoadMenuItems());
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    _batchesPreparedController.dispose();
    _itemNameController.dispose();
    _expectedInputController.dispose();
    _actualInputController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    _searchDebouncer(() {
      if (!mounted) return;
      context.read<RecipeComplianceBloc>().add(
        SearchMenuItems(query: query.trim()),
      );
    });
  }

  void _applyRecipeFromMenuItem(MenuItem item) {
    final ingredients = item.recipe?.ingredients ?? [];

    if (ingredients.isEmpty) {
      _itemNameController.text = item.dishName;
      return;
    }

    final recipeItems = ingredients
        .map((ingredient) {
          final name = ingredient.item?.itemName.trim();
          if (name == null || name.isEmpty) return null;

          final quantity = ingredient.expectedQuantity.trim();
          final unit = ingredient.unit.trim();
          final measurement = [
            if (quantity.isNotEmpty && quantity != '0') quantity,
            if (unit.isNotEmpty) unit,
          ].join(' ');

          return measurement.isEmpty ? name : '$name ($measurement)';
        })
        .whereType<String>()
        .toList();

    _itemNameController.text = recipeItems.isEmpty
        ? item.dishName
        : recipeItems.join(', ');
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar(
        'Please fill in all required fields correctly',
        isError: true,
      );
      return;
    }

    if (_selectedMenuItem == null) {
      _showSnackBar('Please select a menu item', isError: true);
      return;
    }

    try {
      final batchesPrepared = int.tryParse(
        _batchesPreparedController.text.trim(),
      );
      final expectedInput = int.tryParse(_expectedInputController.text.trim());
      final actualInput = int.tryParse(_actualInputController.text.trim());

      if (batchesPrepared == null ||
          expectedInput == null ||
          actualInput == null) {
        _showSnackBar('Please enter valid numeric values', isError: true);
        return;
      }

      if (batchesPrepared <= 0) {
        _showSnackBar(
          'Batches prepared must be greater than zero',
          isError: true,
        );
        return;
      }

      if (expectedInput < 0 || actualInput < 0) {
        _showSnackBar('Input values cannot be negative', isError: true);
        return;
      }

      final bloc = context.read<RecipeComplianceBloc>();
      final request = RecipeComplianceRequest(
        menuItemId: _selectedMenuItem!.id,
        branchId: bloc.branchId,
        batchesPrepared: batchesPrepared,
        itemName: _itemNameController.text.trim(),
        expectedInput: expectedInput,
        actualInput: actualInput,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      context.read<RecipeComplianceBloc>().add(
        SubmitRecipeCompliance(request: request),
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
            color: context.modeTextInverse,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError ? context.modeError : context.modeSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RecipeComplianceBloc, RecipeComplianceState>(
          listener: (context, state) {
            if (state is MenuItemsLoaded) {
              setState(() {
                _filteredMenuItems = state.filteredItems;
              });
            } else if (state is RecipeComplianceSuccess) {
              _showSnackBar('Recipe compliance submitted successfully!');

              // Future.delayed(const Duration(milliseconds: 500), () {
              //   if (mounted) {
              //     Navigator.pop(context, true);
              //   }
              // });
            } else if (state is RecipeComplianceError) {
              _showSnackBar(state.error, isError: true);
            }
          },
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final horizontalPadding = _getHorizontalPadding(screenWidth);
          final maxContentWidth = _getMaxContentWidth(screenWidth);

          return Scaffold(
            backgroundColor: context.modeBackground,
            body: BlocBuilder<RecipeComplianceBloc, RecipeComplianceState>(
              builder: (context, state) {
                if (state is MenuItemsLoading) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return shimmerCatalogCard(constraints.maxWidth);
                    },
                  );
                }

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
                            _buildSectionTitle(
                              'Menu Item Selection',
                              screenWidth,
                            ),
                            SizedBox(height: _getSectionSpacing(screenWidth)),
                            _buildMenuItemSearchField(screenWidth),
                            SizedBox(height: _getFieldSpacing(screenWidth)),

                            _buildSectionTitle(
                              'Batch Information',
                              screenWidth,
                            ),
                            SizedBox(height: _getSectionSpacing(screenWidth)),
                            _buildTextField(
                              controller: _batchesPreparedController,
                              label: 'Batches Prepared',
                              hint: 'Enter number of batches',
                              keyboardType: TextInputType.number,
                              screenWidth: screenWidth,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter batches prepared';
                                }
                                final num = int.tryParse(value);
                                if (num == null || num <= 0) {
                                  return 'Please enter a valid number greater than 0';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: _getFieldSpacing(screenWidth)),
                            _buildTextField(
                              controller: _itemNameController,
                              label: 'Item Name',
                              hint: _selectedMenuItem?.recipe != null
                                  ? 'Auto-generated from selected menu recipe'
                                  : 'e.g., Chicken, Rice, Tomatoes',
                              screenWidth: screenWidth,
                              readOnly: _selectedMenuItem?.recipe != null,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter item name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: _getFieldSpacing(screenWidth)),

                            _buildSectionTitle(
                              'Input Measurements',
                              screenWidth,
                            ),
                            SizedBox(height: _getSectionSpacing(screenWidth)),
                            _buildTextField(
                              controller: _expectedInputController,
                              label: 'Expected Input',
                              hint: 'Enter expected quantity',
                              keyboardType: TextInputType.number,
                              screenWidth: screenWidth,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter expected input';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: _getFieldSpacing(screenWidth)),
                            _buildTextField(
                              controller: _actualInputController,
                              label: 'Actual Input',
                              hint: 'Enter actual quantity used',
                              keyboardType: TextInputType.number,
                              screenWidth: screenWidth,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter actual input';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: _getFieldSpacing(screenWidth)),

                            _buildSectionTitle('Additional Notes', screenWidth),
                            SizedBox(height: _getSectionSpacing(screenWidth)),
                            _buildTextArea(
                              controller: _notesController,
                              label: 'Notes (Optional)',
                              hint: 'Add any relevant observations or comments',
                              screenWidth: screenWidth,
                            ),
                            SizedBox(
                              height: _getSectionSpacing(screenWidth) * 2,
                            ),
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
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, double screenWidth) {
    return Text(
      title,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: _getSectionTitleFontSize(screenWidth),
        fontWeight: FontWeight.w600,
        color: context.modeTextPrimary,
      ),
    );
  }

  Widget _buildMenuItemSearchField(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Menu Item *',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w500,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _isOpened = !_isOpened;
              _isSearching = true;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getInputPaddingHorizontal(screenWidth),
              vertical: _getInputPaddingVertical(screenWidth),
            ),
            decoration: BoxDecoration(
              color: context.modeSurface,
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              border: Border.all(
                color: _selectedMenuItem == null && !_isSearching
                    ? context.modeBorder
                    : context.modePrimary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: _getIconSize(screenWidth) + 4,
                  height: _getIconSize(screenWidth) + 4,
                  child: Center(
                    child: AppIcon(
                      Icons.search,
                      color: context.modeTextSecondary,
                      size: _getIconSize(screenWidth),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedMenuItem?.dishName ??
                        'Search and select a menu item',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getInputFontSize(screenWidth),
                      fontWeight: FontWeight.w400,
                      color: _selectedMenuItem != null
                          ? context.modeTextPrimary
                          : context.modeTextSecondary,
                    ),
                  ),
                ),
                _isOpened
                    ? SizedBox(
                        width: _getIconSize(screenWidth) + 8,
                        height: _getIconSize(screenWidth) + 8,
                        child: Center(
                          child: AppIcon(
                            Icons.arrow_drop_down,
                            color: context.modeTextSecondary,
                            size: _getIconSize(screenWidth) + 4,
                          ),
                        ),
                      )
                    : Transform.rotate(
                        angle: -90 * 3.14159 / 180,
                        child: SizedBox(
                          width: _getIconSize(screenWidth) + 8,
                          height: _getIconSize(screenWidth) + 8,
                          child: Center(
                            child: AppIcon(
                              Icons.arrow_drop_down,
                              color: context.modeTextSecondary,
                              size: _getIconSize(screenWidth) + 4,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
        if (_isSearching && _isOpened) ...[
          const SizedBox(height: 12),
          _buildMenuSearchDropdown(screenWidth),
        ],
      ],
    );
  }

  Widget _buildMenuSearchDropdown(double screenWidth) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: context.modeBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: context.modeTextPrimary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(
                    _getInputPaddingHorizontal(screenWidth),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getInputFontSize(screenWidth),
                      color: context.modeTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type to search...',
                      hintStyle: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: _getInputFontSize(screenWidth),
                        color: context.modeTextSecondary,
                      ),
                      prefixIcon: AppIconSlot(
                        Icons.search,
                        color: context.modeTextSecondary,
                        size: _getIconSize(screenWidth),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: AppIcon(
                                Icons.clear,
                                color: context.modeTextSecondary,
                                size: _getIconSize(screenWidth),
                              ),
                              onPressed: () {
                                _searchDebouncer.cancel();
                                _searchController.clear();
                                context.read<RecipeComplianceBloc>().add(
                                  const ClearMenuSearch(),
                                );
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          _getBorderRadius(screenWidth),
                        ),
                        borderSide: BorderSide(color: context.modeBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          _getBorderRadius(screenWidth),
                        ),
                        borderSide: BorderSide(
                          color: context.modePrimary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: _getInputPaddingHorizontal(screenWidth),
                        vertical: _getInputPaddingVertical(screenWidth),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  onPressed: () {
                    context.read<RecipeComplianceBloc>().add(LoadMenuItems());
                  },
                  icon: AppIcon(Icons.refresh, color: context.modePrimary),
                ),
              ),
            ],
          ),
          Divider(height: 1, color: context.modeDivider),
          Expanded(
            child: _filteredMenuItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(
                        _getInputPaddingHorizontal(screenWidth),
                      ),
                      child: Text(
                        'No menu items found',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: _getInputFontSize(screenWidth),
                          color: context.modeTextSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredMenuItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredMenuItems[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMenuItem = item;
                            _applyRecipeFromMenuItem(item);
                            _isSearching = false;
                            _isOpened = false;
                            _searchDebouncer.cancel();
                            _searchController.clear();
                          });
                          context.read<RecipeComplianceBloc>().add(
                            const ClearMenuSearch(),
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
                                color: context.modeDivider,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item.imageUrl.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl,
                                        width: _getIconSize(screenWidth) + 24,
                                        height: _getIconSize(screenWidth) + 24,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                width:
                                                    _getIconSize(screenWidth) +
                                                    24,
                                                height:
                                                    _getIconSize(screenWidth) +
                                                    24,
                                                color: context.modePrimary
                                                    .withValues(alpha: 0.1),
                                                child: Center(
                                                  child: AppIcon(
                                                    Icons.restaurant_menu,
                                                    color: context.modePrimary,
                                                    size: _getIconSize(
                                                      screenWidth,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                      )
                                    : Container(
                                        width: _getIconSize(screenWidth) + 24,
                                        height: _getIconSize(screenWidth) + 24,
                                        decoration: BoxDecoration(
                                          color: context.modePrimary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Center(
                                          child: AppIcon(
                                            Icons.restaurant_menu,
                                            color: context.modePrimary,
                                            size: _getIconSize(screenWidth),
                                          ),
                                        ),
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
                                            color: context.modeTextPrimary,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.category} - ${item.preparationTime} mins',
                                      style: WorkSansAppTextStyles.medium
                                          .copyWith(
                                            fontSize: _getCaptionFontSize(
                                              screenWidth,
                                            ),
                                            color: context.modeTextSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.recipe != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.modePrimary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Recipe',
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: _getCaptionFontSize(
                                            screenWidth,
                                          ),
                                          color: context.modePrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
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
    String? prefixText,
    bool readOnly = false,
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
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth),
            fontWeight: FontWeight.w400,
            color: context.modeTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              fontWeight: FontWeight.w400,
              color: context.modeTextSecondary,
            ),
            prefixText: prefixText,
            prefixStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
            filled: true,
            fillColor: readOnly
                ? context.modePrimary.withValues(alpha: 0.06)
                : context.modeSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modeBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modeBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modePrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modeError, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modeError, width: 1.5),
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

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String hint,
    required double screenWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w500,
            color: context.modeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth),
            fontWeight: FontWeight.w400,
            color: context.modeTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              fontWeight: FontWeight.w400,
              color: context.modeTextSecondary,
            ),
            filled: true,
            fillColor: context.modeSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modeBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modeBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _getBorderRadius(screenWidth),
              ),
              borderSide: BorderSide(color: context.modePrimary, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: _getInputPaddingHorizontal(screenWidth),
              vertical: _getInputPaddingVertical(screenWidth),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(double screenWidth) {
    return BlocBuilder<RecipeComplianceBloc, RecipeComplianceState>(
      builder: (context, state) {
        final isLoading = state is RecipeComplianceSubmitting;

        return SizedBox(
          width: double.infinity,
          height: _getButtonHeight(screenWidth),
          child: ElevatedButton(
            onPressed: isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.modePrimary,
              disabledBackgroundColor: context.modePrimary.withValues(
                alpha: 0.6,
              ),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.modeTextInverse,
                      ),
                    ),
                  )
                : Text(
                    'Submit Compliance Check',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getButtonFontSize(screenWidth),
                      fontWeight: FontWeight.w600,
                      color: context.modeTextInverse,
                    ),
                  ),
          ),
        );
      },
    );
  }

  // Responsive sizing functions
  double _getHorizontalPadding(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 900) return 32;
    return 48;
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
