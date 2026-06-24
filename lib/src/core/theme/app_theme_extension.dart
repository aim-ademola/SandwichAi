import 'package:flutter/material.dart';

// Legacy light palette constants. Prefer context.appColors/context.colors for
// new UI so widgets automatically adapt between light and dark themes.
const kPrimary = Color(0xFFEC4613);
const kPrimaryBlue = Color(0xFF1969FE);
const kPrimary2 = Color(0xFFB15BA4);
const kprimaryTextColor1 = Color(0xFF000000);
const kprimaryTextColor2 = Color(0xFF646464);
const kprimaryTextColor3 = Color(0xFFFCFCFC);
const kprimaryTextColorGrey = Color(0xFF737373);
const kprimaryTextColor4 = Color(0xFF16123B);
const kPrimaryTextColor5 = Color(0xFF2E2E2E);
const kTextFieldBoorder = Color(0xFFE3E3E3);

const kBlack = Color(0xFF000000);
const kBlack2 = Color(0xFF37474F);
const kBlack3 = Color(0xFF979595);
const kBlack4 = Color(0xFF12101A);
const kBlack5 = Color(0xCC1C1939);
const kBlack6 = Color(0xFF091123);
const kBlack7 = Color(0xFF1C1939);
const kBlack8 = Color(0xFF222222);
const kBlack9 = Color(0xFF0D0D0D);
const kBlack10 = Color(0xFF111111);
const kBlack11 = Color(0xFF212121);

const kGrey = Color(0xFF767676);
const kGrey1 = Color(0xFF616161);
const kGrey2 = Color(0xFF747474);
const kGrey3 = Color(0xFFD9D9D9);
const kGrey4 = Color(0xFF495057);
const kGrey5 = Color(0xFFACB5BD);
const kGrey6 = Color(0xFF979797);
const kGrey7 = Color(0xFF595959);
const kGrey8 = Color(0xFF6D6D6D);
const kGrey9 = Color(0xFF767680);

const kPinInput = Color(0xFF656565);
const kPurple = Color(0xFF7165E3);
const kRed = Color(0xFFC82020);
const kGold = Color(0xFFFFD700);
const kSilver = Color(0xFFBDC2C0);
const kSolitude = Color(0xFFEEF3FF);
const kStone = Color(0xFFEBF3EC);
const kStone2 = Color(0xFF9EA6BE);
const kTransparent = Colors.transparent;
const kWhite = Color(0xFFFFFFFF);
const kGreen = Color(0xFF1A9D2F);
const kToggle = Color(0xFF00B83F);
const kDivider = Color(0xFFE9ECED);
const kBlue = Color(0xFF2196F3);
const kBorder = Color(0xFFD0D0D0);
const kError = Color(0xFFF5F6F8);
const kAsh = Color(0xFFF9F8F6);
const kScaffoldBgColor = Color(0xFF1C1939);

class SandwichThemeColors extends ThemeExtension<SandwichThemeColors> {
  const SandwichThemeColors({
    required this.primary,
    required this.primaryBlue,
    required this.primaryAlt,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textInverse,
    required this.textMuted,
    required this.border,
    required this.divider,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.drawerItem,
    required this.logoutSurface,
  });

  final Color primary;
  final Color primaryBlue;
  final Color primaryAlt;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color textInverse;
  final Color textMuted;
  final Color border;
  final Color divider;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color drawerItem;
  final Color logoutSurface;

  static const light = SandwichThemeColors(
    primary: kPrimary,
    primaryBlue: kPrimaryBlue,
    primaryAlt: kPrimary2,
    background: Color(0xFFF8F6F6),
    surface: kWhite,
    surfaceAlt: kAsh,
    surfaceMuted: kError,
    textPrimary: kprimaryTextColor1,
    textSecondary: kprimaryTextColor2,
    textInverse: kWhite,
    textMuted: kprimaryTextColorGrey,
    border: kBorder,
    divider: kDivider,
    success: kGreen,
    warning: Color(0xFFFFA726),
    error: kRed,
    info: kBlue,
    drawerItem: Color(0xFFF8F6F6),
    logoutSurface: Color(0xFFFFEBEE),
  );

  static const dark = SandwichThemeColors(
    primary: Color(0xFFFF7A45),
    primaryBlue: Color(0xFF79AFFF),
    primaryAlt: Color(0xFFE58BCE),
    background: Color(0xFF0E1117),
    surface: Color(0xFF171B24),
    surfaceAlt: Color(0xFF202636),
    surfaceMuted: Color(0xFF293142),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textInverse: Color(0xFFFFFFFF),
    textMuted: Color(0xFF94A3B8),
    border: Color(0xFF3A4356),
    divider: Color(0xFF2A3142),
    success: Color(0xFF55D879),
    warning: Color(0xFFFFC15A),
    error: Color(0xFFFF6B6B),
    info: Color(0xFF6AB7FF),
    drawerItem: Color(0xFF202636),
    logoutSurface: Color(0xFF3D1F25),
  );

  static SandwichThemeColors of(BuildContext context) {
    return Theme.of(context).extension<SandwichThemeColors>()!;
  }

  @override
  SandwichThemeColors copyWith({
    Color? primary,
    Color? primaryBlue,
    Color? primaryAlt,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textInverse,
    Color? textMuted,
    Color? border,
    Color? divider,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? drawerItem,
    Color? logoutSurface,
  }) {
    return SandwichThemeColors(
      primary: primary ?? this.primary,
      primaryBlue: primaryBlue ?? this.primaryBlue,
      primaryAlt: primaryAlt ?? this.primaryAlt,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textInverse: textInverse ?? this.textInverse,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      drawerItem: drawerItem ?? this.drawerItem,
      logoutSurface: logoutSurface ?? this.logoutSurface,
    );
  }

  @override
  SandwichThemeColors lerp(
    ThemeExtension<SandwichThemeColors>? other,
    double t,
  ) {
    if (other is! SandwichThemeColors) return this;

    return SandwichThemeColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      primaryAlt: Color.lerp(primaryAlt, other.primaryAlt, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      drawerItem: Color.lerp(drawerItem, other.drawerItem, t)!,
      logoutSurface: Color.lerp(logoutSurface, other.logoutSurface, t)!,
    );
  }
}

extension SandwichThemeColorContext on BuildContext {
  SandwichThemeColors get appColors => SandwichThemeColors.of(this);

  Color get modePrimary => appColors.primary;
  Color get modePrimaryBlue => appColors.primaryBlue;
  Color get modePrimaryAlt => appColors.primaryAlt;
  Color get modeBackground => appColors.background;
  Color get modeSurface => appColors.surface;
  Color get modeSurfaceAlt => appColors.surfaceAlt;
  Color get modeSurfaceMuted => appColors.surfaceMuted;
  Color get modeTextPrimary => appColors.textPrimary;
  Color get modeTextSecondary => appColors.textSecondary;
  Color get modeTextInverse => appColors.textInverse;
  Color get modeTextMuted => appColors.textMuted;
  Color get modeBorder => appColors.border;
  Color get modeDivider => appColors.divider;
  Color get modeSuccess => appColors.success;
  Color get modeWarning => appColors.warning;
  Color get modeError => appColors.error;
  Color get modeInfo => appColors.info;
}
