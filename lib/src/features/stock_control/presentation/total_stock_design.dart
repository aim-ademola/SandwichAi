import 'package:flutter/material.dart';

class StockCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Gradient circles in top right
    final gradient = RadialGradient(
      colors: [
        Colors.blue.withOpacity(0.3),
        Colors.purple.withOpacity(0.1),
        Colors.transparent,
      ],
    );

    paint.shader = gradient.createShader(
      Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.2),
        radius: size.width * 0.25,
      ),
    );
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.2),
      size.width * 0.25,
      paint,
    );

    // Decorative lines
    paint.shader = null;
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.blue.withOpacity(0.2);
    paint.strokeWidth = 2;

    final path = Path();
    path.moveTo(size.width * 0.6, 0);
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.3,
      size.width,
      size.height * 0.4,
    );
    canvas.drawPath(path, paint);

    // Bottom accent line
    paint.color = Colors.purple.withOpacity(0.15);
    paint.strokeWidth = 3;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width * 0.3, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
