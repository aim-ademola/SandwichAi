import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';

class WorkSansAppTextStyles {
  WorkSansAppTextStyles._();

  static const String fontFamily = 'Phluff';

  static TextStyle xLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: kprimaryTextColor1,
    fontFamily: fontFamily,
  );
  static TextStyle large = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: kprimaryTextColor1,
    fontFamily: fontFamily,
  );
  static TextStyle big = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: kprimaryTextColor1,
    fontFamily: fontFamily,
  );
  static TextStyle medium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: kprimaryTextColor1,
    fontFamily: fontFamily,
  );
  static TextStyle small = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: kprimaryTextColor1,
    fontFamily: fontFamily,
  );
  static TextStyle tiny = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w300,
    color: kprimaryTextColor1,
    fontFamily: fontFamily,
  );
}
