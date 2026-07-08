import 'package:sandwich_ai/src/core/config/app_bootstrap.dart';
import 'package:sandwich_ai/src/core/config/app_environment.dart';

Future<void> main() {
  return bootstrapSandwichAi(AppEnvironment.dev());
}
