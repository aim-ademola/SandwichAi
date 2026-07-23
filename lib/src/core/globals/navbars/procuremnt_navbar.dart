import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/globals/drawer_toggle.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/globals/chat/chat_rrom_scrssn.dart';

import 'package:sandwich_ai/src/features/procurement/presentation/procurement_dash.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/procurement_drawer.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/procuremnt_purchase_req.dart';
import 'package:sandwich_ai/src/features/procurement/presentation/supplier_list.dart';

class ProcuremntBottomNavBar extends StatefulWidget {
  final int initialIndex;
  final List<Widget> pages;

  const ProcuremntBottomNavBar({
    super.key,
    this.initialIndex = 0,
    required this.pages,
  });

  @override
  State<ProcuremntBottomNavBar> createState() => _ProcuremntBottomNavBarState();
}

class _ProcuremntBottomNavBarState extends State<ProcuremntBottomNavBar> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Wrap pages with KeepAlive to preserve state
    _pages = widget.pages.map((page) => KeepAliveWrapper(child: page)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: ProcurementAppDrawer(),
      body: AppDrawerScope(
        openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      backgroundColor: context.modeBackground,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.modeSurface,
          border: Border(top: BorderSide(color: context.modeBorder)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.25
                    : 0.08,
              ),
              blurRadius: 8,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: HugeIcons.strokeRoundedDashboardSquare01,
                  activeIcon: HugeIcons.strokeRoundedDashboardSquare01,
                  label: 'Dashboard',
                  index: 0,
                ),
                _buildNavItem(
                  icon: HugeIcons.strokeRoundedInvoice03,
                  activeIcon: HugeIcons.strokeRoundedInvoice03,
                  label: 'Requests',
                  index: 1,
                ),
                _buildNavItem(
                  icon: HugeIcons.strokeRoundedUserMultiple02,
                  activeIcon: HugeIcons.strokeRoundedUserMultiple02,
                  label: 'Supplier',
                  index: 2,
                ),
                _buildNavItem(
                  icon: HugeIcons.strokeRoundedMessage01,
                  activeIcon: HugeIcons.strokeRoundedMessage01,
                  label: 'Chat',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required List<List<dynamic>> icon,
    required List<List<dynamic>> activeIcon,
    required String label,
    required int index,
  }) {
    final bool isActive = _currentIndex == index;
    final Color activeColor = context.modePrimary;
    final Color inactiveColor = context.modeTextMuted;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentIndex = index;
            });
          },
          splashColor: activeColor.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: isActive ? activeIcon : icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: 22 * AppIcon.sizeScale,
                  strokeWidth: 1.8,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// KeepAliveWrapper to preserve state across page switches
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // Must call super.build
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

/// Bottom Navigation Item Enum
///
/// Defines the available navigation items.
/// Use the built-in `index` property to get the navigation index.
enum BottomNavItem {
  dashboard, // index = 0
  orders, // index = 1
  suppliers, // index = 2
  budget; // index = 3

  /// Get BottomNavItem from index
  static BottomNavItem fromIndex(int index) {
    return BottomNavItem.values.firstWhere(
      (item) => item.index == index,
      orElse: () => BottomNavItem.dashboard,
    );
  }

  /// Get the route path for this navigation item
  String get route {
    switch (this) {
      case BottomNavItem.dashboard:
        return '/procurement-dash';
      case BottomNavItem.orders:
        return '/procurement_orders';
      case BottomNavItem.suppliers:
        return '/order';
      case BottomNavItem.budget:
        return '/procurement_requests';
    }
  }

  /// Get the display label for this navigation item
  String get label {
    switch (this) {
      case BottomNavItem.dashboard:
        return 'Dashboard';
      case BottomNavItem.orders:
        return 'Orders';
      case BottomNavItem.suppliers:
        return 'Supplier';
      case BottomNavItem.budget:
        return 'Requests';
    }
  }
}

class ProcurementMainScreen extends StatelessWidget {
  final int initialIndex;

  const ProcurementMainScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return ProcuremntBottomNavBar(
      initialIndex: initialIndex,
      pages: [
        ProcurementDashboardScreen(),
        ProcurementOrdersScreen(),
        SupplierListWrapper(),
        ChatRoomsScreen(
          showNavBarCallback: () {
            // optional navbar callback
          },
        ),
      ],
    );
  }
}
