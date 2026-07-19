import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:sandwich_ai/src/core/navigation/department_navigation.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation: grows from 0.5x to 1.3x scale
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward(); // Start animation immediately

    // Navigate when animation finishes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        unawaited(_openInitialRoute());
      }
    });
  }

  Future<void> _openInitialRoute() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final route = await _resolveInitialRoute();
    if (!mounted) return;
    context.go(route);
  }

  Future<String> _resolveInitialRoute() async {
    final authCache = AuthCacheHelper.instance;
    final isLoggedIn = await authCache.isLoggedIn();
    if (!isLoggedIn) return '/';

    final user = await authCache.getUserData();
    final route = DepartmentNavigation.routeForDepartment(user?.department);
    return route ?? '/';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.modeBackground,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Image.asset(
            'assets/img/Logo-DqvzRW6_.png',
            width: 100,
            fit: BoxFit.scaleDown,
          ),
        ),
      ),
    );
  }
}
