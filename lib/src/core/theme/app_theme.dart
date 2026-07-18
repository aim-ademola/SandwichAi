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
      extensions: <ThemeExtension<dynamic>>[colors],
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
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFamily: AppTextStyles.brandFontFamily,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: colors.textPrimary, size: 22),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: IconThemeData(color: colors.textSecondary, size: 22),
      primaryIconTheme: IconThemeData(color: colors.primary, size: 22),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.textSecondary,
          disabledForegroundColor: colors.textMuted.withValues(alpha: 0.45),
          hoverColor: colors.primary.withValues(alpha: 0.08),
          focusColor: colors.primary.withValues(alpha: 0.1),
          highlightColor: colors.primary.withValues(alpha: 0.1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          fontFamily: AppTextStyles.brandFontFamily,
          letterSpacing: 0,
        ),
        contentTextStyle: TextStyle(
          color: colors.textSecondary,
          fontSize: 14,
          fontFamily: AppTextStyles.fontFamily,
          letterSpacing: 0,
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
      listTileTheme: ListTileThemeData(
        iconColor: colors.textSecondary,
        textColor: colors.textPrimary,
        selectedColor: colors.primary,
        selectedTileColor: colors.primary.withValues(alpha: 0.1),
        titleTextStyle: appTextTheme.titleSmall?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: appTextTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
        ),
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
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.brandFontFamily,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.textInverse,
          disabledBackgroundColor: colors.surfaceMuted,
          disabledForegroundColor: colors.textMuted,
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.brandFontFamily,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.border),
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.brandFontFamily,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.brandFontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.textInverse,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        iconColor: colors.textSecondary,
        textStyle: appTextTheme.bodyMedium?.copyWith(color: colors.textPrimary),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceAlt,
        selectedColor: colors.primary.withValues(alpha: 0.14),
        disabledColor: colors.surfaceMuted,
        labelStyle: appTextTheme.labelMedium?.copyWith(
          color: colors.textSecondary,
        ),
        secondaryLabelStyle: appTextTheme.labelMedium?.copyWith(
          color: colors.primary,
        ),
        iconTheme: IconThemeData(color: colors.textSecondary, size: 18),
        side: BorderSide(color: colors.border.withValues(alpha: 0.7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.primary,
        dividerColor: colors.divider,
        labelStyle: appTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: appTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textMuted,
        selectedLabelStyle: appTextTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: appTextTheme.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primary.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.primary, size: 22);
          }
          return IconThemeData(color: colors.textMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return appTextTheme.labelSmall!.copyWith(
            color: selected ? colors.primary : colors.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(colors.textInverse),
        side: BorderSide(color: colors.border, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.primary;
          return colors.textMuted;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.textInverse;
          return colors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary.withValues(alpha: 0.85);
          }
          return colors.surfaceMuted;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? colors.surfaceAlt : colors.textPrimary,
        contentTextStyle: appTextTheme.bodyMedium?.copyWith(
          color: colors.textInverse,
        ),
        actionTextColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static TextTheme _workSansTextTheme(TextTheme textTheme) {
    TextStyle? withFont(
      TextStyle? style, {
      double? fontSize,
      FontWeight? fontWeight,
    }) {
      return style?.copyWith(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: 0,
      );
    }

    return textTheme.copyWith(
      displayLarge: withFont(
        textTheme.displayLarge,
        fontSize: 32,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: withFont(
        textTheme.displayMedium,
        fontSize: 28,
        fontWeight: FontWeight.w800,
      ),
      displaySmall: withFont(
        textTheme.displaySmall,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: withFont(
        textTheme.headlineLarge,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: withFont(
        textTheme.headlineMedium,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: withFont(
        textTheme.headlineSmall,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: withFont(
        textTheme.titleLarge,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: withFont(
        textTheme.titleMedium,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: withFont(
        textTheme.titleSmall,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: withFont(
        textTheme.bodyLarge,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: withFont(
        textTheme.bodyMedium,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: withFont(
        textTheme.bodySmall,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: withFont(
        textTheme.labelLarge,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: withFont(
        textTheme.labelMedium,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: withFont(
        textTheme.labelSmall,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
