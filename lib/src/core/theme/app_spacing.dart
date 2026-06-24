import 'package:flutter/widgets.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double giant = 48;

  // Padding

  static const EdgeInsets pagePadding = EdgeInsets.all(lg);

  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  static const EdgeInsets dialogPadding = EdgeInsets.all(lg);

  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: lg,
  );

  static const EdgeInsets screenVertical = EdgeInsets.symmetric(vertical: lg);

  // Gaps

  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl);

  static const SizedBox gapWs = SizedBox(width: sm);
  static const SizedBox gapWm = SizedBox(width: md);
  static const SizedBox gapWl = SizedBox(width: lg);
  static const SizedBox gapWxl = SizedBox(width: xl);
}
