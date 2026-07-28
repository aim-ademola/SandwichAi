import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sandwich_ai/app_initializer.dart';
import 'package:sandwich_ai/firebase_options.dart';
import 'package:sandwich_ai/router/router.dart';
import 'package:sandwich_ai/src/core/config/app_environment.dart';
import 'package:sandwich_ai/src/core/constant/di/app_providers.dart';
import 'package:sandwich_ai/src/core/globals/notifications/firebase_messaging_service.dart';
import 'package:sandwich_ai/src/core/globals/notifications/local_notification.dart';
import 'package:sandwich_ai/src/core/theme/app_theme.dart';
import 'package:sandwich_ai/src/core/theme/theme_controller.dart';
import 'package:sandwich_ai/src/core/config/feature_registry.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> bootstrapSandwichAi(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnvironment.configure(environment);

  await Hive.initFlutter();
  await Hive.openBox('auth_box');
  await Hive.openBox('onboarding_box');
  await Hive.openBox('pending_requests');
  await Hive.openBox('settings_box');
  await Hive.openBox('order_sessions_box');

  await FeatureRegistry.initialize();

  if (FirebaseMessagingService.isSupportedPlatform) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Pass uncaught framework errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  await NotificationService().disableLocalDelivery();
  await FirebaseMessagingService.instance.initialize();

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
              title: AppEnvironment.current.appName,
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
