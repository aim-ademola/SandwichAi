import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/network/api_engine_private/api_client.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';

class DrawerModuleNavigation extends StatelessWidget {
  const DrawerModuleNavigation({super.key, required this.activeModuleTitle});

  final String activeModuleTitle;

  @override
  Widget build(BuildContext context) {
    final modules = _DrawerModule.all;

    return _DrawerPanel(
      title: 'Modules',
      icon: Icons.apps_rounded,
      child: Column(
        children: [
          for (final module in modules) ...[
            _DrawerModuleTile(
              module: module,
              isActive: module.matches(activeModuleTitle),
            ),
            if (module != modules.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class DrawerBranchSwitcher extends StatefulWidget {
  const DrawerBranchSwitcher({super.key, required this.activeModuleTitle});

  final String activeModuleTitle;

  @override
  State<DrawerBranchSwitcher> createState() => _DrawerBranchSwitcherState();
}

class _DrawerBranchSwitcherState extends State<DrawerBranchSwitcher> {
  late Future<_BranchSwitcherData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadBranches();
  }

  Future<_BranchSwitcherData> _loadBranches() async {
    final cachedBranchId = await AuthCacheHelper.instance.getBranchID() ?? '';
    final cachedBranchName =
        await AuthCacheHelper.instance.getBranchName() ?? 'Current branch';
    final user = await AuthCacheHelper.instance.getUserData();
    final organizationId =
        user?.organizationId ?? await AuthCacheHelper.instance.getOrgId() ?? '';

    final fallbackBranch = DrawerBranch(
      id: cachedBranchId,
      name: cachedBranchName,
      code: user?.branch?.code ?? '',
      city: user?.branch?.city ?? '',
    );

    final branches = await _BranchDirectoryRepository().loadBranches(
      organizationId: organizationId,
      fallbackBranch: fallbackBranch,
    );

    return _BranchSwitcherData(
      activeBranchId: cachedBranchId,
      branches: branches,
    );
  }

  Future<void> _selectBranch(DrawerBranch branch) async {
    await AuthCacheHelper.instance.switchActiveBranch(
      branchId: branch.id,
      branchName: branch.name,
      branchCode: branch.code,
      city: branch.city,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${branch.name}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.modeSuccess,
      ),
    );

    final route = _DrawerModule.routeFor(widget.activeModuleTitle);
    Navigator.of(context).pop();
    if (route != null) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BranchSwitcherData>(
      future: _future,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final data = snapshot.data;
        final branches = data?.branches ?? const <DrawerBranch>[];
        final activeBranch = branches.where((branch) {
          return branch.id == data?.activeBranchId;
        }).firstOrNull;

        return _DrawerPanel(
          title: 'Branch',
          icon: Icons.storefront_rounded,
          trailing: isLoading
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.modePrimary,
                  ),
                )
              : null,
          child: InkWell(
            onTap: branches.length <= 1
                ? null
                : () => _showBranchPicker(branches, data?.activeBranchId ?? ''),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.appColors.drawerItem,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.modeBorder.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.modePrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_city_rounded,
                      color: context.modePrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeBranch?.name ??
                              (isLoading ? 'Loading branch...' : 'No branch'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.modeTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          branches.length > 1
                              ? '${branches.length} branches available'
                              : 'Assigned branch',
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
                  if (branches.length > 1)
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
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

  Future<void> _showBranchPicker(
    List<DrawerBranch> branches,
    String activeBranchId,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.modeSurface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch branch',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.modeTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: branches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final branch = branches[index];
                      final selected = branch.id == activeBranchId;

                      return AppBranchOptionTile(
                        branch: branch,
                        selected: selected,
                        onTap: () {
                          Navigator.of(context).pop();
                          _selectBranch(branch);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AppBranchOptionTile extends StatelessWidget {
  const AppBranchOptionTile({
    super.key,
    required this.branch,
    required this.selected,
    required this.onTap,
  });

  final DrawerBranch branch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? context.modePrimary.withValues(alpha: 0.1)
                : context.appColors.drawerItem,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? context.modePrimary.withValues(alpha: 0.5)
                  : context.modeBorder.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? context.modePrimary : context.modeTextMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.modeTextPrimary,
                      ),
                    ),
                    if (branch.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        branch.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 12,
                          color: context.modeTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerBranch {
  const DrawerBranch({
    required this.id,
    required this.name,
    this.code = '',
    this.city = '',
  });

  final String id;
  final String name;
  final String code;
  final String city;

  String get subtitle {
    return [if (code.isNotEmpty) code, if (city.isNotEmpty) city].join(' - ');
  }

  factory DrawerBranch.fromJson(Map<String, dynamic> json) {
    return DrawerBranch(
      id: _parseString(json['id'] ?? json['branchId'] ?? json['branch_id']),
      name: _parseString(json['name'] ?? json['branchName'] ?? json['branch']),
      code: _parseString(
        json['code'] ?? json['branchCode'] ?? json['branch_code'],
      ),
      city: _parseString(json['city']),
    );
  }

  static String _parseString(dynamic value) {
    if (value == null || value is Map) return '';
    return value.toString();
  }
}

class _BranchSwitcherData {
  const _BranchSwitcherData({
    required this.activeBranchId,
    required this.branches,
  });

  final String activeBranchId;
  final List<DrawerBranch> branches;
}

class _BranchDirectoryRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<List<DrawerBranch>> loadBranches({
    required String organizationId,
    required DrawerBranch fallbackBranch,
  }) async {
    final candidates = <String>[
      if (organizationId.isNotEmpty) 'branches?organizationId=$organizationId',
      if (organizationId.isNotEmpty) 'branches/organization/$organizationId',
      if (organizationId.isNotEmpty) 'organizations/$organizationId/branches',
      if (organizationId.isNotEmpty) 'Branches/organization/$organizationId',
    ];

    for (final path in candidates) {
      try {
        final response = await _apiClient
            .get<dynamic>(path)
            .timeout(const Duration(seconds: 8));

        if (!response.isSuccess || response.data == null) continue;

        final branches = _parseBranches(response.data);
        if (branches.isNotEmpty) {
          return _mergeFallback(branches, fallbackBranch);
        }
      } catch (_) {
        continue;
      }
    }

    return fallbackBranch.id.isEmpty ? const [] : [fallbackBranch];
  }

  List<DrawerBranch> _parseBranches(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => DrawerBranch.fromJson(Map<String, dynamic>.from(item)))
          .where((branch) => branch.id.isNotEmpty)
          .toList();
    }

    if (payload is Map) {
      final json = Map<String, dynamic>.from(payload);
      final possibleLists = [
        json['data'],
        json['branches'],
        if (json['data'] is Map) (json['data'] as Map)['branches'],
        if (json['data'] is Map) (json['data'] as Map)['items'],
      ];

      for (final value in possibleLists) {
        if (value is List) {
          return _parseBranches(value);
        }
      }

      final singleBranch = DrawerBranch.fromJson(json);
      if (singleBranch.id.isNotEmpty) return [singleBranch];
    }

    return const [];
  }

  List<DrawerBranch> _mergeFallback(
    List<DrawerBranch> branches,
    DrawerBranch fallbackBranch,
  ) {
    if (fallbackBranch.id.isEmpty) return branches;
    if (branches.any((branch) => branch.id == fallbackBranch.id)) {
      return branches;
    }
    return [fallbackBranch, ...branches];
  }
}

class _DrawerModule {
  const _DrawerModule({
    required this.title,
    required this.route,
    required this.icon,
    required this.aliases,
  });

  final String title;
  final String route;
  final IconData icon;
  final List<String> aliases;

  bool matches(String value) {
    final normalized = value.toLowerCase().trim();
    return aliases.any((alias) => alias.toLowerCase() == normalized);
  }

  static String? routeFor(String title) {
    for (final module in all) {
      if (module.matches(title)) return module.route;
    }
    return null;
  }

  static const all = <_DrawerModule>[
    _DrawerModule(
      title: 'Stock Control',
      route: '/Stock-control-nav',
      icon: Icons.inventory_2_outlined,
      aliases: ['Stock Control'],
    ),
    _DrawerModule(
      title: 'Processing',
      route: '/Processing-nav',
      icon: Icons.precision_manufacturing_outlined,
      aliases: ['Processing'],
    ),
    _DrawerModule(
      title: 'Procurement',
      route: '/Procurement-nav',
      icon: Icons.receipt_long_outlined,
      aliases: ['Procurement'],
    ),
    _DrawerModule(
      title: 'Point of Sale',
      route: '/Pos-nav',
      icon: Icons.point_of_sale_outlined,
      aliases: ['Point of Sale', 'POS'],
    ),
    _DrawerModule(
      title: 'Kitchen',
      route: '/Kitchen-nav',
      icon: Icons.soup_kitchen_outlined,
      aliases: ['Kitchen'],
    ),
  ];
}

class _DrawerModuleTile extends StatelessWidget {
  const _DrawerModuleTile({required this.module, required this.isActive});

  final _DrawerModule module;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? context.modePrimary : context.modeTextPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive
            ? null
            : () {
                Navigator.of(context).pop();
                context.go(module.route);
              },
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isActive
                ? context.modePrimary.withValues(alpha: 0.1)
                : context.appColors.drawerItem,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? context.modePrimary.withValues(alpha: 0.38)
                  : context.modeBorder.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(module.icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  module.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (isActive)
                Icon(Icons.check_circle_rounded, color: color, size: 18)
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.modeTextMuted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerPanel extends StatelessWidget {
  const _DrawerPanel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.modeSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.modeBorder.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: context.modePrimary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: context.modeTextPrimary,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
