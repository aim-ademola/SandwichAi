import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/globals/account_profile_screen.dart';
import 'package:sandwich_ai/src/core/globals/notifications/notification_bell.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/theme/theme_controller.dart';
import 'package:sandwich_ai/src/features/auth/data/models/login_model.dart';

class AppDrawerShell extends StatelessWidget {
  const AppDrawerShell({
    super.key,
    required this.moduleTitle,
    required this.moduleSubtitle,
    required this.children,
    required this.footerChildren,
  });

  final String moduleTitle;
  final String moduleSubtitle;
  final List<Widget> children;
  final List<Widget> footerChildren;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: context.modeSurface,
      child: SafeArea(
        child: Column(
          children: [
            _PremiumDrawerHeader(
              moduleTitle: moduleTitle,
              moduleSubtitle: moduleSubtitle,
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: AppDrawerAccountMenu(moduleTitle: moduleTitle),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [...children],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Column(children: footerChildren),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumDrawerHeader extends StatelessWidget {
  const _PremiumDrawerHeader({
    required this.moduleTitle,
    required this.moduleSubtitle,
  });

  final String moduleTitle;
  final String moduleSubtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.modePrimary, context.modePrimary],
        ),
        boxShadow: [
          BoxShadow(
            color: context.modePrimary.withValues(alpha: isDark ? 0.2 : 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/img/Logo-DqvzRW6_.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SandwichAI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      moduleTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
              NotificationBellAction(
                iconColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                badgeColor: Colors.white,
                badgeTextColor: context.modePrimary,
                margin: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    moduleSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppDrawerAccountMenu extends StatefulWidget {
  const AppDrawerAccountMenu({super.key, required this.moduleTitle});

  final String moduleTitle;

  @override
  State<AppDrawerAccountMenu> createState() => _AppDrawerAccountMenuState();
}

class _AppDrawerAccountMenuState extends State<AppDrawerAccountMenu> {
  late Future<UserModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = AuthCacheHelper.instance.getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _future,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final name = _displayName(user);
        final subtitle = [
          if ((user?.department ?? '').isNotEmpty) user!.department!,
          if ((user?.role ?? '').isNotEmpty) user!.role!,
        ].join(' • ');

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GlobalProfileScreen(
                    activeModuleTitle: widget.moduleTitle,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.modeSurfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.modeBorder.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  _AccountAvatar(name: name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: context.modeTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle.isEmpty ? 'Account profile' : subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.modeTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: context.modeTextMuted,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _displayName(UserModel? user) {
    final fullName = user?.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;

    final nameParts = [
      user?.firstName?.trim(),
      user?.lastName?.trim(),
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    if (nameParts.isNotEmpty) return nameParts;

    final email = user?.email.trim();
    if (email != null && email.isNotEmpty) return email;

    return 'Account';
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();

    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.modePrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        initial,
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: context.modePrimary,
        ),
      ),
    );
  }
}

class AppDrawerThemeSwitch extends StatelessWidget {
  const AppDrawerThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDarkMode;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.modeSurfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.modeBorder.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? context.modePrimaryBlue.withValues(alpha: 0.18)
                      : context.modePrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? context.modePrimaryBlue : context.modePrimary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDark ? 'Dark mode' : 'Light mode',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.modeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Switch the app appearance',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.modeTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ThemeModeSelector(
                selectedMode: isDark ? ThemeMode.dark : ThemeMode.light,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.selectedMode});

  final ThemeMode selectedMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeModeButton(
            icon: Icons.light_mode_rounded,
            selected: selectedMode == ThemeMode.light,
            onTap: () => ThemeController.instance.setThemeMode(ThemeMode.light),
          ),
          _ThemeModeButton(
            icon: Icons.dark_mode_rounded,
            selected: selectedMode == ThemeMode.dark,
            onTap: () => ThemeController.instance.setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: selected ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? context.modePrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? context.modeTextInverse : context.modeTextMuted,
        ),
      ),
    );
  }
}

class AppDrawerItem extends StatelessWidget {
  const AppDrawerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
    this.badge,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final itemColor = isLogout ? context.modeError : context.modeTextPrimary;
    final itemBackground = isLogout
        ? context.appColors.logoutSurface
        : context.appColors.drawerItem;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: itemBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLogout
                  ? context.modeError.withValues(alpha: 0.16)
                  : context.modeBorder.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: itemColor.withValues(alpha: isLogout ? 0.1 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: itemColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: itemColor,
                  ),
                ),
              ),
              if (badge != null) ...[const SizedBox(width: 8), badge!],
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: itemColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
