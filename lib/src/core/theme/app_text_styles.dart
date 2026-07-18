import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Work_Sans';
  static const String brandFontFamily = fontFamily;

  static TextStyle displayLarge = const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontFamily: brandFontFamily,
    letterSpacing: 0,
    height: 1.25,
  );

  static TextStyle displayMedium = const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontFamily: brandFontFamily,
    letterSpacing: 0,
    height: 1.25,
  );

  static TextStyle heading1 = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: brandFontFamily,
    letterSpacing: 0,
    height: 1.3,
  );

  static TextStyle heading2 = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: brandFontFamily,
    letterSpacing: 0,
    height: 1.3,
  );

  static TextStyle heading3 = const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    letterSpacing: 0,
    height: 1.3,
  );

  static TextStyle bodyLarge = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    letterSpacing: 0,
    height: 1.35,
  );

  static TextStyle bodyMedium = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    letterSpacing: 0,
    height: 1.35,
  );

  static TextStyle bodySmall = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    letterSpacing: 0,
    height: 1.35,
  );

  static TextStyle labelLarge = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    letterSpacing: 0,
    height: 1.25,
  );

  static TextStyle labelMedium = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    letterSpacing: 0,
    height: 1.25,
  );

  static TextStyle button = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontFamily: brandFontFamily,
    letterSpacing: 0,
    height: 1.25,
  );

  static TextStyle caption = const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    letterSpacing: 0,
    height: 1.35,
  );
}
