import 'package:flutter/material.dart';
import '../../core/theme/gemini_colors.dart';

class GeminiSparkleIcon extends StatelessWidget {
  final double size;

  const GeminiSparkleIcon({
    super.key,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GeminiSparklePainter(),
    );
  }
}

class _GeminiSparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final rect = Rect.fromLTWH(0, 0, w, h);
    final paint = Paint()
      ..shader = GeminiColors.geminiGradient.createShader(rect)
      ..style = PaintingStyle.fill;

    // Draw 4-point curved star (Google Gemini shape)
    final path = Path();
    path.moveTo(center.dx, 0); // Top tip
    path.quadraticBezierTo(center.dx, center.dy, w, center.dy); // Top to Right
    path.quadraticBezierTo(center.dx, center.dy, center.dx, h); // Right to Bottom
    path.quadraticBezierTo(center.dx, center.dy, 0, center.dy); // Bottom to Left
    path.quadraticBezierTo(center.dx, center.dy, center.dx, 0); // Left to Top
    path.close();

    canvas.drawPath(path, paint);

    // Subtle smaller secondary sparkle
    final smallSparkle = Path();
    final sx = w * 0.85;
    final sy = h * 0.15;
    final sw = w * 0.18;
    final sh = h * 0.18;
    smallSparkle.moveTo(sx, sy - sh);
    smallSparkle.quadraticBezierTo(sx, sy, sx + sw, sy);
    smallSparkle.quadraticBezierTo(sx, sy, sx, sy + sh);
    smallSparkle.quadraticBezierTo(sx, sy, sx - sw, sy);
    smallSparkle.quadraticBezierTo(sx, sy, sx, sy - sh);
    smallSparkle.close();

    canvas.drawPath(smallSparkle, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
