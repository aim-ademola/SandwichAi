import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sandwich_ai/app_initializer.dart';
import 'package:sandwich_ai/router/router.dart';
import 'package:sandwich_ai/src/core/constant/di/app_providers.dart';
import 'package:sandwich_ai/src/core/globals/notifications/local_notification.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// rm -rf build .dart_tool
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  NotificationService.navigatorKey = navigatorKey;

  await NotificationService().initialize();

  await Hive.initFlutter();
  await Hive.openBox('auth_box');
  await Hive.openBox('onboarding_box');
  await Hive.openBox('pending_requests');

  runApp(AppBlocProviders(child: AppInitializer(child: MyApp())));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
