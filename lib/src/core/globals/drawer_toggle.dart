import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';

class AppDrawerScope extends InheritedWidget {
  const AppDrawerScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static AppDrawerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppDrawerScope>();
  }

  @override
  bool updateShouldNotify(AppDrawerScope oldWidget) {
    return openDrawer != oldWidget.openDrawer;
  }
}

class DrawerToggleButton extends StatelessWidget {
  const DrawerToggleButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AppIcon(Icons.menu, color: color ?? context.modeTextPrimary),
      tooltip: 'Open drawer',
      onPressed: () {
        final scopedDrawer = AppDrawerScope.maybeOf(context);
        if (scopedDrawer != null) {
          scopedDrawer.openDrawer();
          return;
        }

        Scaffold.maybeOf(context)?.openDrawer();
      },
    );
  }
}
