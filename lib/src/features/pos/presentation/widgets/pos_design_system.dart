import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/pos/presentation/widgets/pos_icon_tile.dart';

class PosPageScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? drawer;
  final VoidCallback? onBack;
  final bool showBackButton;

  const PosPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.drawer,
    this.onBack,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        drawer: drawer,
        backgroundColor: context.modeBackground,
        appBar: AppBar(
          backgroundColor: context.modeBackground,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 76,
          leadingWidth: 64,
          leading: showBackButton
              ? Center(
                  child: IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowLeft01,
                      color: context.modeTextPrimary,
                      size: 26 * AppIcon.sizeScale,
                      strokeWidth: 1.8,
                    ),
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                    tooltip: 'Back',
                  ),
                )
              : null,
          title: Text(
            title,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: context.modeTextPrimary,
            ),
          ),
          centerTitle: true,
          actions: actions,
        ),
        body: body,
      ),
    );
  }
}

class PosSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  const PosSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.16
                  : 0.04,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PosSectionHeader extends StatelessWidget {
  final String title;
  final String? countLabel;
  final Widget? trailing;

  const PosSectionHeader({
    super.key,
    required this.title,
    this.countLabel,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: context.modeTextPrimary,
            ),
          ),
        ),
        if (countLabel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: context.modePrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              countLabel!,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: context.modePrimary,
              ),
            ),
          ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

class PosIconActionButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const PosIconActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: HugeIcon(
                icon: icon,
                color: color,
                size: 20 * AppIcon.sizeScale,
                strokeWidth: 1.9,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PosEmptyState extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String message;

  const PosEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            PosIconTile(
              icon: icon,
              color: context.modePrimary,
              size: 58,
              iconSize: 28,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                color: context.modeTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
