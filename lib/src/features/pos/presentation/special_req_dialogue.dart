import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';

// Model to hold item with special request
class OrderItemWithRequest {
  final String menuItemId;
  final int quantity;
  final String? specialRequest;

  OrderItemWithRequest({
    required this.menuItemId,
    required this.quantity,
    this.specialRequest,
  });

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'quantity': quantity,
      if (specialRequest != null && specialRequest!.isNotEmpty)
        'specialRequest': specialRequest,
    };
  }
}

// Extension to show special request dialog
extension SpecialRequestDialogExtension on BuildContext {
  Future<String?> showSpecialRequestDialog({
    required ApiMenuItem item,
    String? existingRequest,
  }) {
    return showDialog<String>(
      context: this,
      builder: (context) =>
          SpecialRequestDialog(item: item, existingRequest: existingRequest),
    );
  }
}

class SpecialRequestDialog extends StatefulWidget {
  final ApiMenuItem item;
  final String? existingRequest;

  const SpecialRequestDialog({
    super.key,
    required this.item,
    this.existingRequest,
  });

  @override
  State<SpecialRequestDialog> createState() => _SpecialRequestDialogState();
}

class _SpecialRequestDialogState extends State<SpecialRequestDialog> {
  late TextEditingController _requestController;

  // Common special requests
  final List<String> _commonRequests = [
    'Extra spicy',
    'No onions',
    'Less salt',
    'Extra sauce',
    'Well done',
    'Medium rare',
    'No pepper',
    'Extra cheese',
  ];

  final List<String> _selectedRequests = [];

  @override
  void initState() {
    super.initState();
    _requestController = TextEditingController(
      text: widget.existingRequest ?? '',
    );

    // Parse existing request for chips
    if (widget.existingRequest != null) {
      for (var request in _commonRequests) {
        if (widget.existingRequest!.toLowerCase().contains(
          request.toLowerCase(),
        )) {
          _selectedRequests.add(request);
        }
      }
    }
  }

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  void _toggleRequest(String request) {
    setState(() {
      if (_selectedRequests.contains(request)) {
        _selectedRequests.remove(request);
      } else {
        _selectedRequests.add(request);
      }

      // Update text field
      _requestController.text = _selectedRequests.join(', ');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Special Request',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.dishName,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick select chips
                    Text(
                      'Quick Select',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kprimaryTextColor1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commonRequests.map((request) {
                        final isSelected = _selectedRequests.contains(request);
                        return FilterChip(
                          label: Text(request),
                          selected: isSelected,
                          onSelected: (selected) => _toggleRequest(request),
                          selectedColor: kPrimary.withOpacity(0.2),
                          checkmarkColor: kPrimary,
                          labelStyle: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 13,
                            color: isSelected ? kPrimary : kprimaryTextColor2,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: isSelected ? kPrimary : Colors.grey[300]!,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Custom request field
                    Text(
                      'Custom Request',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kprimaryTextColor1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _requestController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Type your special request here...',
                        hintStyle: WorkSansAppTextStyles.medium.copyWith(
                          color: kprimaryTextColor2,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F6F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(null);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Clear',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kprimaryTextColor2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final request = _requestController.text.trim();
                        Navigator.of(
                          context,
                        ).pop(request.isNotEmpty ? request : null);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Save',
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
          ],
        ),
      ),
    );
  }
}
