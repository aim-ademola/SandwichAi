// presentation/create_processing_task_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_task_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_task_bloc/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/processing_task_bloc/state.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_compliance_bloc.dart/bloc.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_compliance_bloc.dart/event.dart';
import 'package:sandwich_ai/src/features/processing/bloc/recipe_compliance_bloc.dart/state.dart';
import 'package:sandwich_ai/src/features/processing/data/model/processing_task_model.dart'
    hide MenuItem;
import 'package:sandwich_ai/src/features/processing/data/model/recipe_compliance_models.dart';
import 'package:sandwich_ai/src/features/processing/data/repo/recipe_compliance_repo.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';

class CreateProcessingTaskScreen extends StatefulWidget {
  const CreateProcessingTaskScreen({super.key});

  @override
  State<CreateProcessingTaskScreen> createState() =>
      _CreateProcessingTaskScreenState();
}

class _CreateProcessingTaskScreenState
    extends State<CreateProcessingTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _assignedStaffController = TextEditingController();
  final _batchesRequestedController = TextEditingController();
  final _notesController = TextEditingController();

  MenuItem? _selectedMenuItem;
  bool _isSearching = false;
  bool _isOpened = false;
  List<MenuItem> _filteredMenuItems = [];
  int _selectedPriority = 2; // Default to Medium
  DateTime? _estimatedCompletionTime;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _assignedStaffController.dispose();
    _batchesRequestedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    context.read<RecipeComplianceBloc>().add(SearchMenuItems(query: query));
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              onSurface: kprimaryTextColor1,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: kPrimary,
                onPrimary: Colors.white,
                onSurface: kprimaryTextColor1,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _estimatedCompletionTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
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

    if (_selectedMenuItem!.recipe == null) {
      // Show warning but allow submission
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'No Recipe Attached',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          content: Text(
            'This menu item does not have a recipe attached. You can still create the task, but recipe details will be missing.',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 15,
              color: kprimaryTextColor2,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 15,
                  color: kprimaryTextColor2,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _createTask();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Continue',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    _createTask();
  }

  void _createTask() {
    if (_estimatedCompletionTime == null) {
      _showSnackBar('Please select estimated completion time', isError: true);
      return;
    }

    try {
      final batchesRequested = int.tryParse(
        _batchesRequestedController.text.trim(),
      );

      if (batchesRequested == null || batchesRequested <= 0) {
        _showSnackBar(
          'Batches requested must be greater than zero',
          isError: true,
        );
        return;
      }

      final bloc = context.read<ProcessingTaskBloc>();
      final request = CreateProcessingTaskRequest(
        branchId: bloc.branchId,
        recipeName: _selectedMenuItem!.dishName,
        recipeId: _selectedMenuItem!.recipe?.id ?? '',
        menuItemId: _selectedMenuItem!.id,
        assignedStaff: _assignedStaffController.text.trim(),
        batchesRequested: batchesRequested,
        estimatedCompletionTime: _estimatedCompletionTime!,
        priority: _selectedPriority,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      context.read<ProcessingTaskBloc>().add(
        CreateProcessingTask(request: request),
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              RecipeComplianceBloc(repository: RecipeComplianceRepository())
                ..add(LoadMenuItems()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<RecipeComplianceBloc, RecipeComplianceState>(
            listener: (context, state) {
              if (state is MenuItemsLoaded) {
                setState(() {
                  _filteredMenuItems = state.filteredItems;
                });
              }
            },
          ),
          BlocListener<ProcessingTaskBloc, ProcessingTaskState>(
            listener: (context, state) {
              if (state is ProcessingTaskSuccess) {
                _showSnackBar(state.message);
                _resetForm();
              } else if (state is ProcessingTaskError) {
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

            return BlocBuilder<RecipeComplianceBloc, RecipeComplianceState>(
              builder: (context, menuState) {
                if (menuState is MenuItemsLoading) {
                  return shimmerCatalogCard(screenWidth);
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
                            _buildSectionTitle('Task Details', screenWidth),
                            SizedBox(height: _getSectionSpacing(screenWidth)),
                            _buildTextField(
                              controller: _assignedStaffController,
                              label: 'Assigned Staff',
                              hint: 'Enter staff member name',
                              screenWidth: screenWidth,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter assigned staff';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: _getFieldSpacing(screenWidth)),
                            _buildTextField(
                              controller: _batchesRequestedController,
                              label: 'Batches Requested',
                              hint: 'Enter number of batches',
                              keyboardType: TextInputType.number,
                              screenWidth: screenWidth,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter batches requested';
                                }
                                final num = int.tryParse(value);
                                if (num == null || num <= 0) {
                                  return 'Please enter a valid number greater than 0';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: _getFieldSpacing(screenWidth)),
                            _buildPrioritySelector(screenWidth),
                            SizedBox(height: _getFieldSpacing(screenWidth)),
                            _buildDateTimePicker(screenWidth),
                            SizedBox(height: _getFieldSpacing(screenWidth)),
                            _buildSectionTitle('Additional Notes', screenWidth),
                            SizedBox(height: _getSectionSpacing(screenWidth)),
                            _buildTextArea(
                              controller: _notesController,
                              label: 'Notes (Optional)',
                              hint: 'Add any relevant information',
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
            );
          },
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedMenuItem = null;
      _selectedPriority = 2;
      _estimatedCompletionTime = null;
      _isSearching = false;
      _isOpened = false;
    });
    _searchController.clear();
    _assignedStaffController.clear();
    _batchesRequestedController.clear();
    _notesController.clear();
    _formKey.currentState?.reset();
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
          'Select Menu Item *',
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
                  Icons.search,
                  color: kprimaryTextColor2,
                  size: _getIconSize(screenWidth),
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
                          ? kprimaryTextColor1
                          : kprimaryTextColor2,
                    ),
                  ),
                ),
                _isOpened
                    ? Icon(
                        Icons.arrow_drop_down,
                        color: kprimaryTextColor2,
                        size: _getIconSize(screenWidth) + 4,
                      )
                    : Transform.rotate(
                        angle: -90 * 3.14159 / 180,
                        child: Icon(
                          Icons.arrow_drop_down,
                          color: kprimaryTextColor2,
                          size: _getIconSize(screenWidth) + 4,
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
                              onPressed: () {
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
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  onPressed: () {
                    context.read<RecipeComplianceBloc>().add(LoadMenuItems());
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ],
          ),
          Divider(height: 1, color: Colors.grey.shade200),
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
                          color: kprimaryTextColor2,
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
                            _isSearching = false;
                            _isOpened = false;
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
                                color: Colors.grey.shade200,
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
                                                color: kPrimary.withValues(
                                                  alpha: 0.1,
                                                ),
                                                child: Icon(
                                                  Icons.restaurant_menu,
                                                  color: kPrimary,
                                                  size: _getIconSize(
                                                    screenWidth,
                                                  ),
                                                ),
                                              );
                                            },
                                      )
                                    : Container(
                                        width: _getIconSize(screenWidth) + 24,
                                        height: _getIconSize(screenWidth) + 24,
                                        decoration: BoxDecoration(
                                          color: kPrimary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.restaurant_menu,
                                          color: kPrimary,
                                          size: _getIconSize(screenWidth),
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
                                            color: kprimaryTextColor1,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.category} • ${item.preparationTime} mins',
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
                              if (item.recipe != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kPrimary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Recipe',
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: _getCaptionFontSize(
                                            screenWidth,
                                          ),
                                          color: kPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'No Recipe',
                                    style: WorkSansAppTextStyles.medium
                                        .copyWith(
                                          fontSize: _getCaptionFontSize(
                                            screenWidth,
                                          ),
                                          color: Colors.grey[600],
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

  Widget _buildPrioritySelector(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority *',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w500,
            color: kprimaryTextColor1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildPriorityChip('High', 1, screenWidth)),
            const SizedBox(width: 12),
            Expanded(child: _buildPriorityChip('Medium', 2, screenWidth)),
            const SizedBox(width: 12),
            Expanded(child: _buildPriorityChip('Low', 3, screenWidth)),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityChip(String label, int priority, double screenWidth) {
    final isSelected = _selectedPriority == priority;
    Color chipColor;
    switch (priority) {
      case 1:
        chipColor = const Color(0xFFE53935);
        break;
      case 2:
        chipColor = const Color(0xFFFFA726);
        break;
      case 3:
        chipColor = kGreen;
        break;
      default:
        chipColor = kGreen;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriority = priority;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: _getInputPaddingVertical(screenWidth),
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
          border: Border.all(
            color: isSelected ? chipColor : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? chipColor : kprimaryTextColor2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimated Completion Time *',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w500,
            color: kprimaryTextColor1,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDateTime,
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
                color: _estimatedCompletionTime == null
                    ? const Color(0xFFE0E0E0)
                    : kPrimary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: kprimaryTextColor2,
                  size: _getIconSize(screenWidth),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _estimatedCompletionTime == null
                        ? 'Select date and time'
                        : _formatDateTime(_estimatedCompletionTime!),
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getInputFontSize(screenWidth),
                      fontWeight: FontWeight.w400,
                      color: _estimatedCompletionTime != null
                          ? kprimaryTextColor1
                          : kprimaryTextColor2,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: kprimaryTextColor2,
                  size: _getIconSize(screenWidth) - 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final date = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date at $time';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required double screenWidth,
    TextInputType? keyboardType,
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
            color: kprimaryTextColor1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
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
    return BlocBuilder<ProcessingTaskBloc, ProcessingTaskState>(
      builder: (context, state) {
        final isLoading = state is ProcessingTaskSubmitting;

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
                    'Create Processing Task',
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
