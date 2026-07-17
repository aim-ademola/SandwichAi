import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Work_Sans';
  static const String brandFontFamily = fontFamily;

  static TextStyle displayLarge = const TextStyle(
    fontSize: 20.8,
    fontWeight: FontWeight.w700,
    fontFamily: brandFontFamily,
  );

  static TextStyle displayMedium = const TextStyle(
    fontSize: 18.2,
    fontWeight: FontWeight.w700,
    fontFamily: brandFontFamily,
  );

  static TextStyle heading1 = const TextStyle(
    fontSize: 15.6,
    fontWeight: FontWeight.w700,
    fontFamily: brandFontFamily,
  );

  static TextStyle heading2 = const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    fontFamily: brandFontFamily,
  );

  static TextStyle heading3 = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );

  static TextStyle bodyLarge = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );

  static TextStyle bodyMedium = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );

  static TextStyle bodySmall = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );

  static TextStyle labelLarge = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );

  static TextStyle labelMedium = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  static TextStyle button = const TextStyle(
    fontSize: 9.1,
    fontWeight: FontWeight.w600,
    fontFamily: brandFontFamily,
  );

  static TextStyle caption = const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );
}
