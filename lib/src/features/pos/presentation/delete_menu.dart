import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/state.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/event.dart';
import 'package:sandwich_ai/src/features/pos/bloc/add_menu_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';

class DeleteMenuItemDialog extends StatefulWidget {
  final ApiMenuItem menuItem;

  const DeleteMenuItemDialog({super.key, required this.menuItem});

  @override
  State<DeleteMenuItemDialog> createState() => _DeleteMenuItemDialogState();
}

class _DeleteMenuItemDialogState extends State<DeleteMenuItemDialog> {
  bool _isDeleting = false;

  void _handleDelete() {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    context.read<MenuItemsBloc>().add(
      DeleteMenuItem(menuItemId: widget.menuItem.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MenuItemsBloc, MenuItemsState>(
      listener: (context, state) {
        if (state is MenuItemDeleted) {
          setState(() {
            _isDeleting = false;
          });

          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Menu item "${widget.menuItem.dishName}" deleted successfully',
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
        } else if (state is MenuItemDeletionError) {
          setState(() {
            _isDeleting = false;
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 32,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Delete Menu Item',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: kprimaryTextColor1,
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                'Are you sure you want to delete "${widget.menuItem.dishName}"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kprimaryTextColor2,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isDeleting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _isDeleting
                                ? Colors.grey[300]!
                                : kprimaryTextColor2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isDeleting
                                ? Colors.grey[400]
                                : kprimaryTextColor1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Delete Button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isDeleting ? null : _handleDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          disabledBackgroundColor: Colors.red.withValues(
                            alpha: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isDeleting
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
                                'Delete',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension DeleteMenuItemDialogExtension on BuildContext {
  void showDeleteMenuItemDialog(ApiMenuItem menuItem) {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => DeleteMenuItemDialog(menuItem: menuItem),
    );
  }
}
