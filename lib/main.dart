import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sandwich_ai/app_initializer.dart';
import 'package:sandwich_ai/router/router.dart';
import 'package:sandwich_ai/src/core/constant/di/app_providers.dart';
import 'package:sandwich_ai/src/core/globals/notifications/local_notification.dart';
import 'package:sandwich_ai/src/core/theme/app_theme.dart';
import 'package:sandwich_ai/src/core/theme/theme_controller.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  NotificationService.navigatorKey = navigatorKey;

  await NotificationService().initialize();

  await Hive.initFlutter();
  await Hive.openBox('auth_box');
  await Hive.openBox('onboarding_box');
  await Hive.openBox('pending_requests');
  await Hive.openBox('settings_box');
  await Hive.openBox('order_sessions_box');
  await ThemeController.instance.load();

  runApp(AppBlocProviders(child: AppInitializer(child: const MyApp())));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MaterialApp.router(
              scaffoldMessengerKey: rootScaffoldMessengerKey,

              key: navigatorKey,

              title: 'SandwichAi',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: ThemeController.instance.themeMode,
              routerConfig: AppRouter.router,
              debugShowCheckedModeBanner: false,
            ),
          ),
        );
      },
    );
  }
}
