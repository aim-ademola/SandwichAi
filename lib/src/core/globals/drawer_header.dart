import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/theme/theme_controller.dart';
import 'package:sandwich_ai/src/features/auth/data/models/login_model.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/logout_service.dart';

Widget buildDrawerHeader() {
  return Builder(
    builder: (context) {
      final colors = SandwichThemeColors.of(context);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 22, 14, 20),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: FutureBuilder<UserModel?>(
          future: AuthCacheHelper.instance.getUserData(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            final subtitle = _profileSubtitle(user);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Image.asset(
                    'assets/img/Logo-DqvzRW6_.png',
                    height: 35,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SandwichAI',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colors.textInverse,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: colors.textInverse.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _AccountMenuButton(user: user),
              ],
            );
          },
        ),
      );
    },
  );
}

class _AccountMenuButton extends StatelessWidget {
  const _AccountMenuButton({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final colors = SandwichThemeColors.of(context);

    return PopupMenuButton<_AccountMenuAction>(
      tooltip: 'Account menu',
      offset: const Offset(0, 44),
      icon: CircleAvatar(
        radius: 18,
        backgroundColor: colors.textInverse.withValues(alpha: 0.18),
        child: Text(
          _initials(user),
          style: TextStyle(
            color: colors.textInverse,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      onSelected: (action) async {
        switch (action) {
          case _AccountMenuAction.profile:
            _showProfileSheet(context, user);
            break;
          case _AccountMenuAction.theme:
            _showThemeSheet(context);
            break;
          case _AccountMenuAction.logout:
            await LogoutService.instance.showLogoutDialog(context);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _AccountMenuAction.profile,
          child: _AccountMenuTile(icon: Icons.person_outline, label: 'Profile'),
        ),
        const PopupMenuItem(
          value: _AccountMenuAction.theme,
          child: _AccountMenuTile(
            icon: Icons.dark_mode_outlined,
            label: 'Theme',
          ),
        ),
        PopupMenuItem(
          value: _AccountMenuAction.logout,
          child: _AccountMenuTile(
            icon: Icons.logout,
            label: 'Logout',
            color: colors.error,
          ),
        ),
      ],
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = SandwichThemeColors.of(context);
    final foreground = color ?? colors.textPrimary;

    return Row(
      children: [
        Icon(icon, size: 20, color: foreground),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

enum _AccountMenuAction { profile, theme, logout }

void _showThemeSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return AnimatedBuilder(
        animation: ThemeController.instance,
        builder: (context, _) {
          final colors = SandwichThemeColors.of(context);
          final selected = ThemeController.instance.themeMode;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme selection',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ThemeOptionTile(
                    title: 'Light',
                    subtitle: 'Bright interface for daytime work.',
                    icon: Icons.light_mode_outlined,
                    value: ThemeMode.light,
                    groupValue: selected,
                    color: colors.warning,
                  ),
                  _ThemeOptionTile(
                    title: 'Dark',
                    subtitle: 'Reduced glare for low-light work.',
                    icon: Icons.dark_mode_outlined,
                    value: ThemeMode.dark,
                    groupValue: selected,
                    color: colors.primaryBlue,
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode groupValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = SandwichThemeColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: value == groupValue ? colors.surfaceAlt : colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value == groupValue ? colors.primary : colors.border,
        ),
      ),
      child: ListTile(
        onTap: () {
          ThemeController.instance.setThemeMode(value);
        },
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: colors.textSecondary)),
        trailing: Icon(
          value == groupValue
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: value == groupValue ? colors.primary : colors.textMuted,
        ),
      ),
    );
  }
}

void _showProfileSheet(BuildContext context, UserModel? user) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final colors = SandwichThemeColors.of(context);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.primary.withValues(alpha: 0.14),
                    child: Text(
                      _initials(user),
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName(user),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'No email available',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ProfileInfoRow(label: 'Role', value: user?.role),
              _ProfileInfoRow(label: 'Department', value: user?.department),
              _ProfileInfoRow(
                label: 'Organization',
                value: user?.organizationName,
              ),
              _ProfileInfoRow(label: 'Branch', value: user?.branch?.name),
              _ProfileInfoRow(label: 'Status', value: user?.status),
            ],
          ),
        ),
      );
    },
  );
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final colors = SandwichThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              (value == null || value!.trim().isEmpty) ? 'Not set' : value!,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _profileSubtitle(UserModel? user) {
  final role = user?.role?.trim();
  final department = user?.department?.trim();

  if (role != null && role.isNotEmpty) return role;
  if (department != null && department.isNotEmpty) return department;
  return 'Manager Dashboard';
}

String _displayName(UserModel? user) {
  final fullName = user?.fullName?.trim();
  if (fullName != null && fullName.isNotEmpty) return fullName;

  final firstName = user?.firstName?.trim();
  final lastName = user?.lastName?.trim();
  final combined = [
    if (firstName != null && firstName.isNotEmpty) firstName,
    if (lastName != null && lastName.isNotEmpty) lastName,
  ].join(' ');

  if (combined.isNotEmpty) return combined;
  return user?.email ?? 'Account';
}

String _initials(UserModel? user) {
  final name = _displayName(user);
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) return 'SA';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}
