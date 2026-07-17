import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/theme/app_text_styles.dart';
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
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      extensions: const <ThemeExtension<dynamic>>[SandwichThemeColors.light],
    );

    final appTextTheme = _workSansTextTheme(
      base.textTheme,
    ).apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary);

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 11.7,
          fontWeight: FontWeight.w700,
          fontFamily: AppTextStyles.brandFontFamily,
        ),
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
          fontSize: 13,
          fontWeight: FontWeight.w700,
          fontFamily: AppTextStyles.brandFontFamily,
        ),
        contentTextStyle: TextStyle(
          color: colors.textSecondary,
          fontSize: 14,
          fontFamily: AppTextStyles.fontFamily,
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
      textTheme: appTextTheme,
      primaryTextTheme: appTextTheme,
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
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.brandFontFamily,
            fontWeight: FontWeight.w700,
          ),
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

  static TextTheme _workSansTextTheme(TextTheme textTheme) {
    TextStyle? withFont(TextStyle? style) {
      return style?.copyWith(fontFamily: AppTextStyles.fontFamily);
    }

    return textTheme.copyWith(
      displayLarge: withFont(textTheme.displayLarge),
      displayMedium: withFont(textTheme.displayMedium),
      displaySmall: withFont(textTheme.displaySmall),
      headlineLarge: withFont(textTheme.headlineLarge),
      headlineMedium: withFont(textTheme.headlineMedium),
      headlineSmall: withFont(textTheme.headlineSmall),
      titleLarge: withFont(textTheme.titleLarge),
      titleMedium: withFont(textTheme.titleMedium),
      titleSmall: withFont(textTheme.titleSmall),
      bodyLarge: withFont(textTheme.bodyLarge),
      bodyMedium: withFont(textTheme.bodyMedium),
      bodySmall: withFont(textTheme.bodySmall),
      labelLarge: withFont(textTheme.labelLarge),
      labelMedium: withFont(textTheme.labelMedium),
      labelSmall: withFont(textTheme.labelSmall),
    );
  }
}
