import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';

class SandwichAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool centerTitle;

  const SandwichAppBar({
    super.key,
    required this.title,
    this.onMenuPressed,
    this.onBackPressed,
    this.actions,
    this.showBackButton = false,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.modeSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      leading: _buildLeading(context),
      title: Text(
        title,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: context.modeTextPrimary,
        ),
      ),
      actions: actions,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (onMenuPressed != null) {
      return IconButton(
        icon: Icon(Icons.menu, color: context.modeTextPrimary),
        onPressed: onMenuPressed,
      );
    }

    if (showBackButton) {
      return IconButton(
        icon: Icon(Icons.arrow_back, color: context.modeTextPrimary),
        onPressed: onBackPressed ?? () => Navigator.maybePop(context),
      );
    }

    return null;
  }
}
