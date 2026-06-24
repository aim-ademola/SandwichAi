// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/globals/chat/chat_rrom_scrssn.dart';

import 'package:sandwich_ai/src/features/processing/presentation/processing_dasboard.dart';
import 'package:sandwich_ai/src/features/processing/presentation/recipe_calc.dart';
import 'package:sandwich_ai/src/features/processing/presentation/ai_wastage_analysis.dart';

final GlobalKey<ProcessingBottomNavBarState> stockControlNavBarKey =
    GlobalKey<ProcessingBottomNavBarState>();

class ProcessingBottomNavBar extends StatefulWidget {
  final int initialIndex;
  final List<Widget> pages;

  const ProcessingBottomNavBar({
    super.key,
    this.initialIndex = 0,
    required this.pages,
  });

  @override
  State<ProcessingBottomNavBar> createState() => ProcessingBottomNavBarState();
}

class ProcessingBottomNavBarState extends State<ProcessingBottomNavBar> {
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
                  icon: 'assets/svg/calc.svg',
                  activeIcon: 'assets/svg/calc.svg',
                  label: 'Recipe Calc',
                  index: 1,
                ),
                _buildNavItem(
                  icon: 'assets/svg/solar_box-linear.svg',
                  activeIcon: 'assets/svg/solar_box-linear.svg',
                  label: 'Wastage Analysis',
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
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  isActive ? activeIcon : icon,
                  colorFilter: ColorFilter.mode(
                    isActive ? activeColor : inactiveColor,
                    BlendMode.srcIn,
                  ),
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
}

class ProcessingControlMainScreen extends StatelessWidget {
  const ProcessingControlMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProcessingBottomNavBar(
      key: stockControlNavBarKey,
      initialIndex: 0,
      pages: [
        ProcessingDashboardScreen(),
        RecipeCalculatorScreen(),
        WastageAnalysisScreen(isFromStock: false),
        ChatRoomsScreen(
          showNavBarCallback: () {
            // optional navbar callback
          },
        ),
      ],
    );
  }
}
