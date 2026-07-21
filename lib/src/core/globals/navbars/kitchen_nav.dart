import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/globals/chat/chat_rrom_scrssn.dart';

import 'package:sandwich_ai/src/features/kitchen/presentation/kitchen_dash.dart';
import 'package:sandwich_ai/src/features/kitchen/presentation/kitchen_order_history.dart';

class KitchenBottomNavBar extends StatefulWidget {
  final int initialIndex;
  final List<Widget> pages;

  const KitchenBottomNavBar({
    super.key,
    this.initialIndex = 0,
    required this.pages,
  });

  @override
  State<KitchenBottomNavBar> createState() => _KitchenBottomNavBarState();
}

class _KitchenBottomNavBarState extends State<KitchenBottomNavBar> {
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
      body: IndexedStack(index: _currentIndex, children: _pages),
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
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  icon: HugeIcons.strokeRoundedTimeQuarterPass,
                  activeIcon: HugeIcons.strokeRoundedTimeQuarterPass,
                  label: 'Order History',
                  index: 1,
                ),
                _buildNavItem(
                  icon: HugeIcons.strokeRoundedMessage01,
                  activeIcon: HugeIcons.strokeRoundedMessage01,
                  label: 'Chat',
                  index: 2,
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
  home, // index = 0
  table, // index = 1
  order, // index = 2
  chat; // index = 3

  /// Get BottomNavItem from index
  static BottomNavItem fromIndex(int index) {
    return BottomNavItem.values.firstWhere(
      (item) => item.index == index,
      orElse: () => BottomNavItem.home,
    );
  }

  /// Get the route path for this navigation item
  String get route {
    switch (this) {
      case BottomNavItem.home:
        return '/home';
      case BottomNavItem.table:
        return '/table';
      case BottomNavItem.order:
        return '/order';
      case BottomNavItem.chat:
        return '/chat';
    }
  }

  /// Get the display label for this navigation item
  String get label {
    switch (this) {
      case BottomNavItem.home:
        return 'Home';
      case BottomNavItem.table:
        return 'Table';
      case BottomNavItem.order:
        return 'Order';
      case BottomNavItem.chat:
        return 'chat';
    }
  }
}

class KitchenMainScreen extends StatelessWidget {
  const KitchenMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KitchenBottomNavBar(
      initialIndex: 0, // Starting index
      pages: [
        KitchenDashboardScreen(),
        KitchenOrderHistoryScreen(),
        // OrderScreen(),
        ChatRoomsScreen(
          showNavBarCallback: () {
            // optional navbar callback
          },
        ),
      ],
    );
  }
}
