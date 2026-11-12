import 'package:flutter/material.dart';

/// Desenha o logotipo oficial "G" colorido do Google sem depender de pacotes ou assets externos.
class LogoGooglePainter extends CustomPainter {
  const LogoGooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.19;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    // Vermelho (topo)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, -2.55, 1.80, false, paint);

    // Amarelo (esquerda)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, 2.45, 1.30, false, paint);

    // Verde (base)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 0.65, 1.80, false, paint);

    // Azul (arco direito + barra horizontal)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -0.15, 0.85, false, paint);

    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - strokeWidth * 0.48,
        size.width * 0.48,
        strokeWidth * 0.96,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
