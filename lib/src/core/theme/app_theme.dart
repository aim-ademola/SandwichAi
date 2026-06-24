import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return _theme(
      brightness: Brightness.light,
      colors: SandwichThemeColors.light,
    );
  }

  static ThemeData dark() {
    return _theme(
      brightness: Brightness.dark,
      colors: SandwichThemeColors.dark,
    );
  }

  static ThemeData _theme({
    required Brightness brightness,
    required SandwichThemeColors colors,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
      primary: colors.primary,
      secondary: colors.primaryAlt,
      surface: colors.surface,
      error: colors.error,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Work_Sans',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      extensions: const <ThemeExtension<dynamic>>[SandwichThemeColors.light],
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Work_Sans',
        ),
        contentTextStyle: TextStyle(
          color: colors.textSecondary,
          fontSize: 14,
          fontFamily: 'Work_Sans',
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.divider),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.border.withValues(alpha: 0.45)),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
        fontFamily: 'Work_Sans',
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textMuted),
        prefixIconColor: colors.textMuted,
        suffixIconColor: colors.textMuted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.textInverse,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colors.primary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: colors.textPrimary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
