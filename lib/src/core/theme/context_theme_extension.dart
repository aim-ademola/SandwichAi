import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';

extension ThemeContextExtension on BuildContext {
  /// Custom SandwichAI colors
  SandwichThemeColors get colors =>
      Theme.of(this).extension<SandwichThemeColors>()!;

  /// Flutter ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Flutter TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Current ThemeData
  ThemeData get theme => Theme.of(this);

  /// Dark mode check
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Light mode check
  bool get isLightMode => !isDarkMode;
}
