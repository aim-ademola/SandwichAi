import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/globals/chat/chat_rrom_scrssn.dart';

import 'package:sandwich_ai/src/features/kitchen/presentation/kitchen_dash.dart';
import 'package:sandwich_ai/src/features/pos/presentation/active_orders.dart';

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
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: 'assets/svg/home.svg',
                  activeIcon: 'assets/svg/home.svg',
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  icon: 'assets/svg/bx_cart.svg',
                  activeIcon: 'assets/svg/bx_cart.svg',
                  label: 'Active Orders',
                  index: 1,
                ),
                // _buildNavItem(
                //   icon: 'assets/svg/order.svg',
                //   activeIcon: 'assets/svg/order.svg',
                //   label: 'Order',
                //   index: 2,
                // ),
                _buildNavItem(
                  icon: 'assets/svg/chat.svg',
                  activeIcon: 'assets/svg/chat.svg',
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
    required String icon,
    required String activeIcon,
    required String label,
    required int index,
  }) {
    final bool isActive = _currentIndex == index;
    final Color activeColor = kPrimary;
    final Color inactiveColor = const Color(0xFF9E9E9E); // Grey color

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentIndex = index;
            });
          },
          splashColor: activeColor.withOpacity(0.1),
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  isActive ? activeIcon : icon,
                  color: isActive ? activeColor : null,
                  fit: BoxFit.scaleDown,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? activeColor : inactiveColor,
                    letterSpacing: 0.1,
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
        ActiveOrdersScreen(),
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
