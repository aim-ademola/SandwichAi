import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/config/responsive_config.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
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
    cursorColor: context.modePrimary,
    controller: controller,
    obscureText: obscureText,
    textInputAction: textInputAction,
    keyboardType: keyboardType,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    style: WorkSansAppTextStyles.medium.copyWith(
      fontSize: fontSize,
      color: context.modeTextPrimary,
    ),
    decoration: InputDecoration(
      hintText: hintText,
      errorText: errorText,
      errorStyle: WorkSansAppTextStyles.medium.copyWith(
        fontSize: fontSize * 0.85,
        color: context.modeError,
      ),
      hintStyle: WorkSansAppTextStyles.medium.copyWith(
        fontSize: fontSize,
        color: context.modeTextMuted,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: context.modeSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          responsive.getBorderRadius(screenWidth),
        ),
        borderSide: BorderSide(color: context.modeBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          responsive.getBorderRadius(screenWidth),
        ),
        borderSide: BorderSide(
          color: errorText != null
              ? context.modeError.withValues(alpha: 0.65)
              : context.modeBorder,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          responsive.getBorderRadius(screenWidth),
        ),
        borderSide: BorderSide(
          color: errorText != null ? context.modeError : context.modePrimary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          responsive.getBorderRadius(screenWidth),
        ),
        borderSide: BorderSide(color: context.modeError, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          responsive.getBorderRadius(screenWidth),
        ),
        borderSide: BorderSide(color: context.modeError, width: 2),
      ),
      suffixIcon: suffixIcon,
    ),
  );
}
