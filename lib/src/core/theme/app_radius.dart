import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 999;

  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));

  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));

  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));

  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));

  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));

  static const BorderRadius radiusXxl = BorderRadius.all(Radius.circular(xxl));

  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}
