import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_model.dart';

enum InventoryMethod { fifo, lifo, fefo, manual }

class AddItemDialog extends StatefulWidget {
  final Function(CatalogItem) onAddItem;

  const AddItemDialog({super.key, required this.onAddItem});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _expiryDaysController = TextEditingController();
  final _batchesController = TextEditingController(text: '1');

  String _selectedCategory = 'Popular';
  String _selectedUnit = 'Kg';
  String _selectedStorage = 'Freezer';
  InventoryMethod _selectedInventoryMethod = InventoryMethod.fifo;

  final List<String> _categories = ['Ready-to-Go', 'City Strength', 'Popular'];

  final List<String> _units = ['Kg', 'Unit', 'L', 'g'];
  final List<String> _storageOptions = [
    'Freezer',
    'Dry Storage',
    'Refrigerator',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _expiryDaysController.dispose();
    _batchesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop();
    }
  }

  ItemStatus? _determineItemStatus(int expiryDays, int quantity) {
    if (expiryDays <= 0) return ItemStatus.expired;
    if (expiryDays <= 3) return ItemStatus.useSoon;
    if (quantity <= 5) return ItemStatus.lowStock;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = _getDialogWidth(screenWidth);
        final isSmallScreen = screenWidth < 600;

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogHeader(screenWidth),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Item Name',
                            hint: 'Enter item name',
                            screenWidth: screenWidth,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter item name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: _getFieldSpacing(screenWidth)),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Description (Optional)',
                            hint: 'Enter description',
                            screenWidth: screenWidth,
                            maxLines: 2,
                          ),
                          SizedBox(height: _getFieldSpacing(screenWidth)),
                          if (isSmallScreen)
                            ..._buildSmallScreenLayout(screenWidth)
                          else
                            ..._buildLargeScreenLayout(screenWidth),
                          SizedBox(height: _getFieldSpacing(screenWidth)),
                          _buildDropdownField(
                            label: 'Category',
                            value: _selectedCategory,
                            items: _categories,
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                            screenWidth: screenWidth,
                          ),
                          SizedBox(height: _getFieldSpacing(screenWidth)),
                          _buildDropdownField(
                            label: 'Storage Location',
                            value: _selectedStorage,
                            items: _storageOptions,
                            onChanged: (value) {
                              setState(() {
                                _selectedStorage = value!;
                              });
                            },
                            screenWidth: screenWidth,
                          ),
                          SizedBox(height: _getFieldSpacing(screenWidth)),
                          _buildInventoryMethodSection(screenWidth),
                          SizedBox(height: _getSectionSpacing(screenWidth)),
                          _buildActionButtons(screenWidth),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogHeader(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_getDialogPadding(screenWidth)),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F6),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Add New Item',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getHeaderFontSize(screenWidth),
              fontWeight: FontWeight.w700,
              color: kprimaryTextColor1,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.close,
              size: _getIconSize(screenWidth),
              color: const Color(0xFF757575),
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSmallScreenLayout(double screenWidth) {
    return [
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: _quantityController,
              label: 'Quantity',
              hint: '0',
              screenWidth: screenWidth,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                if (int.tryParse(value) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
          ),
          SizedBox(width: _getFieldSpacing(screenWidth)),
          Expanded(
            child: _buildDropdownField(
              label: 'Unit',
              value: _selectedUnit,
              items: _units,
              onChanged: (value) {
                setState(() {
                  _selectedUnit = value!;
                });
              },
              screenWidth: screenWidth,
            ),
          ),
        ],
      ),
      SizedBox(height: _getFieldSpacing(screenWidth)),
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: _expiryDaysController,
              label: 'Expiry (Days)',
              hint: '0',
              screenWidth: screenWidth,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                if (int.tryParse(value) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
          ),
          SizedBox(width: _getFieldSpacing(screenWidth)),
          Expanded(
            child: _buildTextField(
              controller: _batchesController,
              label: 'Batches',
              hint: '1',
              screenWidth: screenWidth,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                if (int.tryParse(value) == null || int.parse(value) < 1) {
                  return 'Invalid';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildLargeScreenLayout(double screenWidth) {
    return [
      Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildTextField(
              controller: _quantityController,
              label: 'Quantity',
              hint: '0',
              screenWidth: screenWidth,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter quantity';
                }
                if (int.tryParse(value) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
          ),
          SizedBox(width: _getFieldSpacing(screenWidth)),
          Expanded(
            child: _buildDropdownField(
              label: 'Unit',
              value: _selectedUnit,
              items: _units,
              onChanged: (value) {
                setState(() {
                  _selectedUnit = value!;
                });
              },
              screenWidth: screenWidth,
            ),
          ),
          SizedBox(width: _getFieldSpacing(screenWidth)),
          Expanded(
            flex: 2,
            child: _buildTextField(
              controller: _expiryDaysController,
              label: 'Expiry (Days)',
              hint: '0',
              screenWidth: screenWidth,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter expiry days';
                }
                if (int.tryParse(value) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
          ),
          SizedBox(width: _getFieldSpacing(screenWidth)),
          Expanded(
            child: _buildTextField(
              controller: _batchesController,
              label: 'Batches',
              hint: '1',
              screenWidth: screenWidth,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                if (int.tryParse(value) == null || int.parse(value) < 1) {
                  return 'Must be ≥ 1';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required double screenWidth,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w600,
            color: kprimaryTextColor1,
          ),
        ),
        SizedBox(height: _getLabelSpacing(screenWidth)),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          cursorColor: kPrimary,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getInputFontSize(screenWidth),
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              fontWeight: FontWeight.w400,
              color: const Color(0xFF9E9E9E),
            ),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFE53935),
                width: 1.5,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: _getInputPadding(screenWidth),
              vertical: _getInputPadding(screenWidth),
            ),
            errorStyle: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getErrorFontSize(screenWidth),
              fontWeight: FontWeight.w400,
              color: const Color(0xFFE53935),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required double screenWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w600,
            color: kprimaryTextColor1,
          ),
        ),
        SizedBox(height: _getLabelSpacing(screenWidth)),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: _getInputFontSize(screenWidth),
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: _getInputPadding(screenWidth),
                vertical: _getInputPadding(screenWidth),
              ),
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: const Color(0xFF757575),
              size: _getIconSize(screenWidth),
            ),
            dropdownColor: Colors.white,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: _getInputFontSize(screenWidth),
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryMethodSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Method',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: _getLabelFontSize(screenWidth),
            fontWeight: FontWeight.w600,
            color: kprimaryTextColor1,
          ),
        ),
        SizedBox(height: _getLabelSpacing(screenWidth)),
        Container(
          padding: EdgeInsets.all(_getInputPadding(screenWidth)),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildInventoryMethodOption(
                method: InventoryMethod.fifo,
                title: 'FIFO (First In, First Out)',
                description: 'Oldest stock is used first',
                screenWidth: screenWidth,
              ),
              SizedBox(height: _getMethodSpacing(screenWidth)),
              _buildInventoryMethodOption(
                method: InventoryMethod.lifo,
                title: 'LIFO (Last In, First Out)',
                description: 'Newest stock is used first',
                screenWidth: screenWidth,
              ),
              SizedBox(height: _getMethodSpacing(screenWidth)),
              _buildInventoryMethodOption(
                method: InventoryMethod.fefo,
                title: 'FEFO (First Expired, First Out)',
                description: 'Items expiring soonest are used first',
                screenWidth: screenWidth,
              ),
              SizedBox(height: _getMethodSpacing(screenWidth)),
              _buildInventoryMethodOption(
                method: InventoryMethod.manual,
                title: 'Manual',
                description: 'No automatic ordering',
                screenWidth: screenWidth,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryMethodOption({
    required InventoryMethod method,
    required String title,
    required String description,
    required double screenWidth,
  }) {
    final isSelected = _selectedInventoryMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedInventoryMethod = method;
        });
      },
      child: Container(
        padding: EdgeInsets.all(_getMethodPadding(screenWidth)),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? kPrimary : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: _getRadioSize(screenWidth),
              height: _getRadioSize(screenWidth),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? kPrimary : const Color(0xFF757575),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: _getRadioSize(screenWidth) * 0.5,
                        height: _getRadioSize(screenWidth) * 0.5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: kPrimary,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: _getMethodSpacing(screenWidth)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getMethodTitleFontSize(screenWidth),
                      fontWeight: FontWeight.w600,
                      color: isSelected ? kPrimary : kprimaryTextColor1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: _getMethodDescFontSize(screenWidth),
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(double screenWidth) {
    final isSmallScreen = screenWidth < 600;

    if (isSmallScreen) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: EdgeInsets.symmetric(
                  vertical: _getButtonPadding(screenWidth),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Add to Inventory',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getButtonFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: _getFieldSpacing(screenWidth)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: _getButtonPadding(screenWidth),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              child: Text(
                'Cancel',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: _getButtonFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF757575),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: _getButtonPadding(screenWidth),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            child: Text(
              'Cancel',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getButtonFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF757575),
              ),
            ),
          ),
        ),
        SizedBox(width: _getFieldSpacing(screenWidth)),
        Expanded(
          child: ElevatedButton(
            onPressed: _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              padding: EdgeInsets.symmetric(
                vertical: _getButtonPadding(screenWidth),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Add to Inventory',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: _getButtonFontSize(screenWidth),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Responsive sizing functions
  double _getDialogWidth(double screenWidth) {
    if (screenWidth < 600) return screenWidth * 0.95;
    if (screenWidth < 900) return 500;
    return 600;
  }

  double _getDialogPadding(double screenWidth) {
    if (screenWidth < 360) return 16;
    if (screenWidth < 600) return 20;
    return 24;
  }

  double _getHeaderFontSize(double screenWidth) {
    if (screenWidth < 360) return 16;
    if (screenWidth < 600) return 18;
    return 20;
  }

  double _getIconSize(double screenWidth) {
    if (screenWidth < 360) return 20;
    if (screenWidth < 600) return 22;
    return 24;
  }

  double _getFieldSpacing(double screenWidth) {
    if (screenWidth < 360) return 14;
    if (screenWidth < 600) return 16;
    return 18;
  }

  double _getSectionSpacing(double screenWidth) {
    if (screenWidth < 360) return 20;
    if (screenWidth < 600) return 24;
    return 28;
  }

  double _getLabelFontSize(double screenWidth) {
    if (screenWidth < 360) return 12;
    if (screenWidth < 600) return 13;
    return 14;
  }

  double _getLabelSpacing(double screenWidth) {
    if (screenWidth < 360) return 6;
    if (screenWidth < 600) return 7;
    return 8;
  }

  double _getInputFontSize(double screenWidth) {
    if (screenWidth < 360) return 13;
    if (screenWidth < 600) return 14;
    return 15;
  }

  double _getInputPadding(double screenWidth) {
    if (screenWidth < 360) return 10;
    if (screenWidth < 600) return 12;
    return 14;
  }

  double _getErrorFontSize(double screenWidth) {
    if (screenWidth < 360) return 10;
    if (screenWidth < 600) return 11;
    return 12;
  }

  double _getMethodSpacing(double screenWidth) {
    if (screenWidth < 360) return 8;
    if (screenWidth < 600) return 10;
    return 12;
  }

  double _getMethodPadding(double screenWidth) {
    if (screenWidth < 360) return 10;
    if (screenWidth < 600) return 12;
    return 14;
  }

  double _getRadioSize(double screenWidth) {
    if (screenWidth < 360) return 18;
    if (screenWidth < 600) return 20;
    return 22;
  }

  double _getMethodTitleFontSize(double screenWidth) {
    if (screenWidth < 360) return 12;
    if (screenWidth < 600) return 13;
    return 14;
  }

  double _getMethodDescFontSize(double screenWidth) {
    if (screenWidth < 360) return 11;
    if (screenWidth < 600) return 12;
    return 13;
  }

  double _getButtonFontSize(double screenWidth) {
    if (screenWidth < 360) return 13;
    if (screenWidth < 600) return 14;
    return 15;
  }

  double _getButtonPadding(double screenWidth) {
    if (screenWidth < 360) return 12;
    if (screenWidth < 600) return 14;
    return 16;
  }
}
