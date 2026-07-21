import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/theme/theme_controller.dart';
import 'package:sandwich_ai/src/features/auth/data/models/login_model.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/logout_service.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/presentation/chnge_pwd.dart';

class GlobalProfileScreen extends StatefulWidget {
  const GlobalProfileScreen({super.key, required this.activeModuleTitle});

  final String activeModuleTitle;

  @override
  State<GlobalProfileScreen> createState() => _GlobalProfileScreenState();
}

class _GlobalProfileScreenState extends State<GlobalProfileScreen> {
  late Future<_AccountProfileData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadProfile();
  }

  Future<_AccountProfileData> _loadProfile() async {
    final cache = AuthCacheHelper.instance;
    final user = await cache.getUserData();
    final branchName = await cache.getBranchName();
    final orgName = await cache.getOrgName();
    final loginTime = await cache.getLoginTimestamp();

    return _AccountProfileData(
      user: user,
      branchName: branchName,
      organizationName: orgName,
      loginTime: loginTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
        appBar: AppBar(
          backgroundColor: context.modeSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: AppIcon(
              Icons.arrow_back_rounded,
              color: context.modeTextPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Account',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.modeTextPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: FutureBuilder<_AccountProfileData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: context.modePrimary),
              );
            }

            final data = snapshot.data ?? const _AccountProfileData();
            final user = data.user;
            final displayName = _displayName(user);
            final moduleTitle = _formatDisplayLabel(
              widget.activeModuleTitle,
              fallback: widget.activeModuleTitle,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                _ProfileHero(
                  name: displayName,
                  email: user?.email ?? '',
                  moduleTitle: moduleTitle,
                ),
                const SizedBox(height: 14),
                const _MobileThemeSelection(),
                const SizedBox(height: 14),
                _InfoSection(
                  title: 'Profile',
                  icon: Icons.person_outline_rounded,
                  rows: [
                    _InfoRowData('Name', displayName),
                    _InfoRowData('Email', user?.email ?? 'Not available'),
                    _InfoRowData(
                      'Role',
                      _formatDisplayLabel(user?.role ?? user?.type),
                    ),
                    _InfoRowData(
                      'Department',
                      _formatDisplayLabel(
                        user?.department ?? widget.activeModuleTitle,
                      ),
                    ),
                    _InfoRowData(
                      'Status',
                      _formatDisplayLabel(user?.status, fallback: 'Active'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _InfoSection(
                  title: 'Organization',
                  icon: Icons.business_outlined,
                  rows: [
                    _InfoRowData(
                      'Organization',
                      user?.organizationName ??
                          data.organizationName ??
                          'Not available',
                    ),
                    _InfoRowData(
                      'Organization Code',
                      user?.organizationCode ?? 'Not available',
                    ),
                    _InfoRowData(
                      'Branch',
                      user?.branch?.name ??
                          data.branchName ??
                          user?.branchId ??
                          'Not available',
                    ),
                    _InfoRowData(
                      'Employee ID',
                      user?.employeeId ?? 'Not available',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _InfoSection(
                  title: 'Security',
                  icon: Icons.shield_outlined,
                  rows: [
                    _InfoRowData(
                      'Signed in',
                      data.loginTime == null
                          ? 'Not available'
                          : _formatDate(data.loginTime!),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _AccountActionTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _AccountActionTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'Sign out of this device',
                  isDanger: true,
                  onTap: () => LogoutService.instance.showLogoutDialog(context),
                ),
              ],
            );
          },
        ),
      ),
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

  String _formatDisplayLabel(String? value, {String fallback = 'Employee'}) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return fallback;

    final normalized = raw
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) {
          if (part.length <= 2 && part == part.toUpperCase()) return part;

          final lower = part.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
        ? 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day}/${date.month}/${date.year} $hour:$minute $period';
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.moduleTitle,
  });

  final String name;
  final String email;
  final String moduleTitle;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.modePrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              initial,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: context.modePrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: context.modeTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isEmpty ? 'No email available' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.modeTextMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.modePrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    moduleTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: context.modePrimary,
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

class _MobileThemeSelection extends StatelessWidget {
  const _MobileThemeSelection();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final selected = ThemeController.instance.themeMode;

        return _Panel(
          title: 'Appearance',
          icon: Icons.palette_outlined,
          child: Row(
            children: [
              Expanded(
                child: _ThemeOption(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  selected: selected == ThemeMode.light,
                  onTap: () =>
                      ThemeController.instance.setThemeMode(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ThemeOption(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  selected: selected == ThemeMode.dark,
                  onTap: () =>
                      ThemeController.instance.setThemeMode(ThemeMode.dark),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: selected ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? context.modePrimary.withValues(alpha: 0.12)
              : context.appColors.drawerItem,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? context.modePrimary.withValues(alpha: 0.55)
                : context.modeBorder.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              icon,
              size: 20,
              color: selected ? context.modePrimary : context.modeTextMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? context.modePrimary : context.modeTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_InfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      icon: icon,
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _InfoRow(data: rows[index]),
            if (index != rows.length - 1)
              Divider(height: 18, color: context.modeDivider),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.data});

  final _InfoRowData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 116,
          child: Text(
            data.label,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.modeTextMuted,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            data.value.isEmpty ? 'Not available' : data.value,
            textAlign: TextAlign.right,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: context.modeTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? context.modeError : context.modeTextPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDanger
                ? context.appColors.logoutSurface
                : context.modeSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDanger
                  ? context.modeError.withValues(alpha: 0.16)
                  : context.modeBorder.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              AppIcon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: isDanger
                            ? context.modeError.withValues(alpha: 0.82)
                            : context.modeTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              AppIcon(Icons.chevron_right_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon, color: context.modePrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: context.modeTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRowData {
  const _InfoRowData(this.label, this.value);

  final String label;
  final String value;
}

class _AccountProfileData {
  const _AccountProfileData({
    this.user,
    this.branchName,
    this.organizationName,
    this.loginTime,
  });

  final UserModel? user;
  final String? branchName;
  final String? organizationName;
  final DateTime? loginTime;
}
