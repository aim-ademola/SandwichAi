import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/config/responsive_config.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

Widget buildTextField({
  required TextEditingController controller,
  required String hintText,
  required double fontSize,
  required BuildContext context,
  bool obscureText = false,
  Widget? suffixIcon,
  TextInputAction? textInputAction,
  String? errorText,
  TextInputType? keyboardType,
  void Function(String)? onChanged,
  void Function(String)? onSubmitted,
}) {
  final responsive = ResponsiveConfig.instance;
  final screenWidth = context.screenWidth;

  return TextField(
    cursorColor: kPrimary,
    controller: controller,
    obscureText: obscureText,
    textInputAction: textInputAction,
    keyboardType: keyboardType,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    style: WorkSansAppTextStyles.medium.copyWith(
      fontSize: fontSize,
      color: const Color(0xFF212121),
    ),
    decoration: InputDecoration(
      hintText: hintText,
      errorText: errorText,
      errorStyle: WorkSansAppTextStyles.medium.copyWith(
        fontSize: fontSize * 0.85,
        color: Colors.red.shade700,
      ),
      hintStyle: WorkSansAppTextStyles.medium.copyWith(
        fontSize: fontSize,
        color: const Color(0xFFBDBDBD),
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          responsive.getBorderRadius(screenWidth),
        ),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          responsive.getBorderRadius(screenWidth),
        ),
        borderSide: BorderSide(
          color: errorText != null
              ? Colors.red.shade300
              : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          responsive.getBorderRadius(screenWidth),
        ),
        borderSide: BorderSide(
          color: errorText != null
              ? Colors.red.shade700
              : const Color(0xFFFF5722),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          responsive.getBorderRadius(screenWidth),
        ),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          responsive.getBorderRadius(screenWidth),
        ),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
      ),
      suffixIcon: suffixIcon,
    ),
  );
}
