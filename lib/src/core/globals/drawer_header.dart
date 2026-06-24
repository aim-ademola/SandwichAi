import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';

Widget buildDrawerHeader() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    decoration: BoxDecoration(
      color: kPrimary,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Logo
        Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Image.asset(
            'assets/img/Logo-DqvzRW6_.png',
            height: 35,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(width: 5),
        Column(
          children: [
            Text(
              'SandwichAI',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),

            Text(
              'Manager Dashboard',
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
