import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_forecast_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_forecast_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_forecast_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/recipe_forecast_model.dart';
import 'package:sandwich_ai/src/features/processing/presentation/moduleinfo.dart';
import 'package:sandwich_ai/src/features/processing/presentation/processing_drawer.dart';

class RecipeCalculatorScreen extends StatefulWidget {
  const RecipeCalculatorScreen({super.key});

  @override
  State<RecipeCalculatorScreen> createState() => _RecipeCalculatorScreenState();
}

class _RecipeCalculatorScreenState extends State<RecipeCalculatorScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _servingsController = TextEditingController();
  final _searchController = TextEditingController();

  ApiMenuItem? _selectedMenuItem;
  List<ApiMenuItem> _menuItems = [];
  List<ApiMenuItem> _filteredMenuItems = [];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    context.read<MenuItemsBloc>().add(const LoadMenuItems());
  }

  @override
  void dispose() {
    _servingsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterMenuItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMenuItems = _menuItems;
      } else {
        _filteredMenuItems = _menuItems.where((item) {
          return item.dishName.toLowerCase().contains(query.toLowerCase()) ||
              item.category.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _calculateRecipe() {
    if (_formKey.currentState!.validate() && _selectedMenuItem != null) {
      final recipeId = _selectedMenuItem!.recipe?.id ?? '';

      if (recipeId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This menu item does not have a recipe configured',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      context.read<RecipeForecastBloc>().add(
        CalculateRecipeForecast(
          recipeId: recipeId,
          dishName: _selectedMenuItem!.dishName,
          targetServings: int.parse(_servingsController.text),
          organizationId: _selectedMenuItem!.organizationId,
          branchId: _selectedMenuItem!.branchId,
        ),
      );
    }
  }

  void _resetCalculator() {
    setState(() {
      _selectedMenuItem = null;
      _servingsController.clear();
      _searchController.clear();
      _filteredMenuItems = _menuItems;
      _showDropdown = false;
    });
    context.read<RecipeForecastBloc>().add(const ResetRecipeForecast());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: ProcessingAppDrawer(),
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: _buildAppBar(context),
        body: BlocListener<RecipeForecastBloc, RecipeForecastState>(
          listener: (context, state) {
            if (state is RecipeForecastError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.error,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(12),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalculatorCard(),
                const SizedBox(height: 20),
                BlocBuilder<RecipeForecastBloc, RecipeForecastState>(
                  builder: (context, state) {
                    if (state is RecipeForecastCalculated) {
                      return _buildResultsCard(state.forecast);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'AI Recipe Calculator',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      actions: [
        BlocBuilder<RecipeForecastBloc, RecipeForecastState>(
          builder: (context, state) {
            if (state is RecipeForecastCalculated) {
              return IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: _resetCalculator,
                tooltip: 'Reset',
              );
            }
            return IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () {
                context.read<MenuItemsBloc>().add(const LoadMenuItems());
              },
              tooltip: 'Refresh',
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalculatorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calculate_outlined,
                    size: 24,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Calculate Recipe',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 10),

                InfoIconButton(
                  onPressed: () {
                    showModuleInfoBottomSheet(
                      context: context,
                      title: "About This Module",
                      description:
                          "This module scales recipe ingredients based on the desired servings, providing precise quantity predictions for procurement and preparation.",
                      useCases: [
                        "Scale recipes for events or large orders",
                        "Calculate ingredients for custom serving sizes",
                        "Estimate procurement needs",
                      ],
                    );
                  },
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Calculate ingredient quantities for a target number of servings.',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            _buildMenuItemSelector(),
            const SizedBox(height: 20),
            _buildServingsInput(),
            const SizedBox(height: 28),
            _buildCalculateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemSelector() {
    return BlocBuilder<MenuItemsBloc, MenuItemsState>(
      builder: (context, state) {
        if (state is MenuItemsLoading) {
          return _buildLoadingSelector();
        }

        if (state is MenuItemsError) {
          return _buildErrorSelector(state.error);
        }

        if (state is MenuItemsEmpty) {
          return _buildEmptySelector();
        }

        if (state is MenuItemsLoaded) {
          // Filter only items with recipes
          final newMenuItems = state.menuItems
              .where((item) => item.recipe != null)
              .toList();

          // Check if there are menu items but none have recipes
          final hasMenuItemsWithoutRecipes =
              state.menuItems.isNotEmpty && newMenuItems.isEmpty;

          // Update menu items if they're different
          if (_menuItems.isEmpty || _menuItems.length != newMenuItems.length) {
            // Schedule the update for after the build phase
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _menuItems = newMenuItems;
                  // Only reset filtered items if search is empty
                  if (_searchController.text.isEmpty) {
                    _filteredMenuItems = _menuItems;
                  }
                });
              }
            });
          }

          // Show special message if menu items exist but have no recipes
          if (hasMenuItemsWithoutRecipes) {
            return _buildNoRecipesSelector(state.menuItems.length);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Menu Item',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() => _showDropdown = !_showDropdown);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F6F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedMenuItem?.dishName ??
                              'Search and select a menu item',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            color: _selectedMenuItem != null
                                ? Colors.black87
                                : const Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                      Icon(
                        _showDropdown
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showDropdown) _buildSearchableDropdown(),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSearchableDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMenuItems,
              decoration: InputDecoration(
                hintText: 'Search menu items...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF9E9E9E),
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFFF8F6F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            child: _filteredMenuItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: const Color(0xFF9E9E9E).withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No matching items found',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try adjusting your search',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: const Color(0xFF9E9E9E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: _filteredMenuItems.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF5F5F5),
                    ),
                    itemBuilder: (context, index) {
                      final item = _filteredMenuItems[index];
                      final isSelected = _selectedMenuItem?.id == item.id;

                      return ListTile(
                        onTap: () {
                          setState(() {
                            _selectedMenuItem = item;
                            _showDropdown = false;
                            _searchController.clear();
                            _filteredMenuItems = _menuItems;
                          });
                        },
                        selected: isSelected,
                        selectedTileColor: const Color(0xFFF5F5F5),
                        title: Text(
                          item.dishName,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          item.category,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: const Color(0xFF757575),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: kPrimary,
                                size: 20,
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Menu Item',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading menu items...',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSelector(String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Menu Item',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Menu Item',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 48,
                color: const Color(0xFF9E9E9E).withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No menu items available',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add menu items to get started',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF9E9E9E),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoRecipesSelector(int totalMenuItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Menu Item',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No recipes configured',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have $totalMenuItems menu item${totalMenuItems != 1 ? 's' : ''}, but none have recipes attached.',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 13,
                  color: Colors.orange.shade800,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Please contact your admin to add recipes to menu items.',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServingsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Servings',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF757575),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _servingsController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter servings',
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: const Color(0xFF9E9E9E),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F6F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: const Icon(Icons.people_outline),
          ),
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            color: Colors.black87,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter number of servings';
            }
            final servings = int.tryParse(value);
            if (servings == null || servings <= 0) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCalculateButton() {
    return BlocBuilder<RecipeForecastBloc, RecipeForecastState>(
      builder: (context, state) {
        final isCalculating = state is RecipeForecastCalculating;

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isCalculating ? null : _calculateRecipe,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE0E0E0),
              disabledForegroundColor: const Color(0xFF9E9E9E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isCalculating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: kPrimary,
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calculate, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Calculate',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildResultsCard(RecipeForecastResponse forecast) {
    return Column(
      children: [
        _buildRecipeInfoCard(forecast),
        const SizedBox(height: 20),
        _buildIngredientsCard(forecast),
        if (forecast.preparationNotes.isNotEmpty &&
            forecast.preparationNotes != 'No preparation notes available') ...[
          const SizedBox(height: 20),
          _buildPreparationNotesCard(forecast),
        ],
      ],
    );
  }

  Widget _buildRecipeInfoCard(RecipeForecastResponse forecast) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimary, Color.fromARGB(255, 246, 86, 78)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipe Calculation',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      forecast.dishName,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  label: 'Target Servings',
                  value: '${forecast.targetServings}',
                  icon: Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  label: 'Original Servings',
                  value: '${forecast.originalServings}',
                  icon: Icons.restaurant_menu,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      'Scaling Factor',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${forecast.scalingFactor.toStringAsFixed(2)}x',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (forecast.estimatedCost != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Estimated Cost',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₦${forecast.estimatedCost!.toStringAsFixed(2)}',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 12),
          Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsCard(RecipeForecastResponse forecast) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_basket_outlined,
                  size: 24,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scaled Ingredients',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${forecast.ingredients.length} items',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: forecast.ingredients.length,
            separatorBuilder: (context, index) => const Divider(
              height: 24,
              color: Color(0xFFF5F5F5),
              thickness: 1,
            ),
            itemBuilder: (context, index) {
              final ingredient = forecast.ingredients[index];
              return _buildIngredientItem(ingredient);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(ScaledIngredient ingredient) {
    final hasScaling = ingredient.originalQuantity != ingredient.scaledQuantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.circle, size: 12, color: kPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.ingredientName,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                if (hasScaling) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Original: ',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 12,
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                          Text(
                            '${ingredient.originalQuantity.toStringAsFixed(ingredient.originalQuantity % 1 == 0 ? 0 : 1)} ${ingredient.originalUnit}',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Scaled: ',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 12,
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                          Text(
                            '${ingredient.scaledQuantity.toStringAsFixed(ingredient.scaledQuantity % 1 == 0 ? 0 : 1)} ${ingredient.scaledUnit}',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.trending_up,
                            size: 14,
                            color: kPrimary.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'No scaling needed',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 12,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: hasScaling
                  ? kPrimary.withOpacity(0.1)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasScaling
                    ? kPrimary.withOpacity(0.3)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${ingredient.scaledQuantity.toStringAsFixed(ingredient.scaledQuantity % 1 == 0 ? 0 : 1)}',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: hasScaling ? kPrimary : Colors.black87,
                  ),
                ),
                Text(
                  ingredient.scaledUnit,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasScaling ? kPrimary : const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparationNotesCard(RecipeForecastResponse forecast) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notes_outlined,
                  size: 24,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Preparation Notes',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              forecast.preparationNotes,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
