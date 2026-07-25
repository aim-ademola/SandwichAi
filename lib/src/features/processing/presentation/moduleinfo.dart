import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

class ModuleInfoBottomSheet extends StatelessWidget {
  final String title;
  final String description;
  final List<String> useCases;

  const ModuleInfoBottomSheet({
    super.key,
    required this.title,
    required this.description,
    required this.useCases,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 16),
          _buildDescription(),
          SizedBox(height: 20),
          _buildUseCasesSection(),
          SizedBox(height: 20),
          _buildDismissButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AppIcon(Icons.info_outline, color: kPrimary, size: 24),
        SizedBox(width: 10),
        Text(
          title,
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      description,
      style: WorkSansAppTextStyles.medium.copyWith(fontSize: 14, height: 1.4),
    );
  }

  Widget _buildUseCasesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Use Cases:",
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        ...useCases.map(
          (useCase) => Padding(
            padding: EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "- $useCase",
                  style: WorkSansAppTextStyles.medium.copyWith(fontSize: 13),
                ),
                SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDismissButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          "Got it",
          style: WorkSansAppTextStyles.medium.copyWith(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

Future<void> showModuleInfoBottomSheet({
  required BuildContext context,
  required String title,
  required String description,
  required List<String> useCases,
}) {
  return showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return ModuleInfoBottomSheet(
        title: title,
        description: description,
        useCases: useCases,
      );
    },
  );
}

class InfoIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;

  const InfoIconButton({super.key, this.onPressed, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed:
          onPressed ??
          () {
            // Default behavior - you can pass your own onPressed
          },
      icon: AppIcon(Icons.help_rounded, color: kPrimary, size: size),
    );
  }
}
