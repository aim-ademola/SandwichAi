import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> xs = [
    BoxShadow(blurRadius: 4, offset: Offset(0, 1), color: Color(0x14000000)),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Color(0x18000000)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(blurRadius: 12, offset: Offset(0, 4), color: Color(0x1F000000)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(blurRadius: 20, offset: Offset(0, 8), color: Color(0x24000000)),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(blurRadius: 32, offset: Offset(0, 12), color: Color(0x29000000)),
  ];
}
