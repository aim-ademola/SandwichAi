import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/globals/chat/chat_rrom_scrssn.dart';

import 'package:sandwich_ai/src/features/procurement/presentation/procurement_dash.dart';
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
              color: Colors.black.withValues(alpha: 0.08),
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
                  label: 'Dashboard',
                  index: 0,
                ),
                _buildNavItem(
                  icon: 'assets/svg/procuremnt_order.svg',
                  activeIcon: 'assets/svg/procuremnt_order.svg',
                  label: 'Requests',
                  index: 1,
                ),
                _buildNavItem(
                  icon: 'assets/svg/supplier.svg',
                  activeIcon: 'assets/svg/supplier.svg',
                  label: 'Supplier',
                  index: 2,
                ),
                _buildNavItem(
                  icon: 'assets/svg/chat.svg',
                  activeIcon: 'assets/svg/chat.svg',
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
          splashColor: activeColor.withValues(alpha: 0.1),
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
  const ProcurementMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProcuremntBottomNavBar(
      initialIndex: 0, // Starting index
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
