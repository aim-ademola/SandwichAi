import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/globals/chat/chat_rrom_scrssn.dart';

import 'package:sandwich_ai/src/features/stock_control/presentation/stock_catalogue.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/stock_control_dashboard.dart';
import 'package:sandwich_ai/src/features/stock_control/presentation/stock_movement.dart';

final GlobalKey<StockControlBottomNavBarState> stockControlNavBarKey =
    GlobalKey<StockControlBottomNavBarState>();

class StockControlBottomNavBar extends StatefulWidget {
  final int initialIndex;
  final List<Widget> pages;

  const StockControlBottomNavBar({
    super.key,
    this.initialIndex = 0,
    required this.pages,
  });

  @override
  State<StockControlBottomNavBar> createState() =>
      StockControlBottomNavBarState();
}

class StockControlBottomNavBarState extends State<StockControlBottomNavBar> {
  late int _currentIndex;
  late List<Widget> _pages;

  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = widget.pages.map((page) => KeepAliveWrapper(child: page)).toList();
  }

  bool get _isChatScreen => _currentIndex == 4; // Chat screen index

  void showNavBarTemporarily({int durationSeconds = 3}) {
    setState(() {});

    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: durationSeconds), () {
      if (_isChatScreen) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
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
                  icon: HugeIcons.strokeRoundedTable,
                  activeIcon: HugeIcons.strokeRoundedTable,
                  label: 'Catalogue',
                  index: 1,
                ),
                _buildNavItem(
                  icon: HugeIcons.strokeRoundedPackage02,
                  activeIcon: HugeIcons.strokeRoundedPackage02,
                  label: 'Stock Movement',
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
            // TransferService().initialize(context);
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
  payment; // index = 3

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
        return '/catalogue';
      case BottomNavItem.order:
        return '/order';
      case BottomNavItem.payment:
        return '/payment';
    }
  }

  /// Get the display label for this navigation item
  String get label {
    switch (this) {
      case BottomNavItem.home:
        return 'Home';
      case BottomNavItem.table:
        return 'Catalogue';
      case BottomNavItem.order:
        return 'Order';
      case BottomNavItem.payment:
        return 'Payment';
    }
  }
}

class StockControlMainScreen extends StatelessWidget {
  const StockControlMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StockControlBottomNavBar(
      key: stockControlNavBarKey,
      initialIndex: 0,
      pages: [
        StockControlDashboardScreen(),
        StockCatalogScreen(),
        InventoryMovementScreen(),
        ChatRoomsScreen(
          showNavBarCallback: () {
            // optional navbar callback
          },
        ),
      ],
    );
  }
}
