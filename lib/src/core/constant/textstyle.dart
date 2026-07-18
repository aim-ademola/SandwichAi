import 'package:flutter/material.dart';

class WorkSansAppTextStyles {
  WorkSansAppTextStyles._();

  static const String fontFamily = 'Work_Sans';
  static const String brandFontFamily = fontFamily;

  static TextStyle xLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
    letterSpacing: 0,
    height: 1.25,
  );
  static TextStyle large = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
    letterSpacing: 0,
    height: 1.25,
  );
  static TextStyle big = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    letterSpacing: 0,
    height: 1.3,
  );
  static TextStyle medium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    letterSpacing: 0,
    height: 1.35,
  );
  static TextStyle small = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    letterSpacing: 0,
    height: 1.35,
  );
  static TextStyle tiny = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    letterSpacing: 0,
    height: 1.35,
  );

  static TextStyle brandTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: brandFontFamily,
    letterSpacing: 0,
    height: 1.3,
  );

  static TextStyle brandButton = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontFamily: brandFontFamily,
    letterSpacing: 0,
    height: 1.25,
  );
}
