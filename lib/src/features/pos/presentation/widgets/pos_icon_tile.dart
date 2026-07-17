import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class PosIconTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final double size;
  final double iconSize;
  final double borderRadius;

  const PosIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 54,
    this.iconSize = 27,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          color: color,
          size: iconSize,
          strokeWidth: 1.9,
        ),
      ),
    );
  }
}
