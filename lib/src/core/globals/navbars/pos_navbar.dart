import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/globals/chat/chat_rrom_scrssn.dart';
import 'package:sandwich_ai/src/features/pos/presentation/active_orders.dart';
import 'package:sandwich_ai/src/features/pos/presentation/order_session_entry.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_dashboard.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_showcase_scope.dart';
import 'package:showcaseview/showcaseview.dart';

class PosBottomNavBar extends StatefulWidget {
  final int initialIndex;
  final List<Widget> pages;

  const PosBottomNavBar({
    super.key,
    this.initialIndex = 0,
    required this.pages,
  });

  @override
  State<PosBottomNavBar> createState() => PosBottomNavBarState();
}

class PosBottomNavBarState extends State<PosBottomNavBar> {
  late int _currentIndex;
  late List<Widget> _pages;
  late final ShowcaseView _showcaseView;

  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register(
      scope: posShowcaseScope,
      blurValue: 1,
    );
    _currentIndex = widget.initialIndex;
    _pages = widget.pages.map((page) => KeepAliveWrapper(child: page)).toList();
  }

  @override
  void didUpdateWidget(covariant PosBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  void showNavBarTemporarily({int durationSeconds = 3}) {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: durationSeconds), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _showcaseView.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      backgroundColor: context.modeBackground,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
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
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: 'assets/svg/home.svg',
                activeIcon: 'assets/svg/home.svg',
                label: 'Home',
                index: 0,
              ),
              // _buildNavItem(
              //   icon: 'assets/svg/table.svg',
              //   activeIcon: 'assets/svg/table.svg',
              //   label: 'Table',
              //   index: 1,
              // ),
              _buildNavItem(
                icon: 'assets/svg/procuremnt_order.svg',
                activeIcon: 'assets/svg/procuremnt_order.svg',
                label: 'New Order',
                index: 1,
              ),
              _buildNavItem(
                icon: 'assets/svg/bx_cart.svg',
                activeIcon: 'assets/svg/bx_cart.svg',
                label: 'Active Orders',
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
                  colorFilter: ColorFilter.mode(
                    isActive ? activeColor : inactiveColor,
                    BlendMode.srcIn,
                  ),
                  width: 24,
                  height: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
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

/// KeepAliveWrapper to preserve state across pages
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
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

/// Main POS Screen
class POSMainScreen extends StatelessWidget {
  final int? initialIndex;
  const POSMainScreen({super.key, this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return PosBottomNavBar(
      initialIndex: initialIndex ?? 0,
      pages: [
        const PosDashboardScreen(),
        // TableManagementScreen(),
        const OrderSessionEntryScreen(),
        const ActiveOrdersScreen(),
        ChatRoomsScreen(
          showNavBarCallback: () {
            // optional navbar callback
          },
        ),
      ],
    );
  }
}
