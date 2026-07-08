import 'package:sandwich_ai/src/core/config/app_bootstrap.dart';
import 'package:sandwich_ai/src/core/config/app_environment.dart';

export 'package:sandwich_ai/src/core/config/app_bootstrap.dart'
    show MyApp, rootScaffoldMessengerKey, navigatorKey;

Future<void> main() {
  return bootstrapSandwichAi(AppEnvironment.staging());
}
