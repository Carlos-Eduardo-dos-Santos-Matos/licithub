import 'package:flutter/material.dart';

/// Desenha as formas circulares geométricas sutis e o efeito "orb" translúcido no painel escuro da Tela de Login.
class FundoLoginPainter extends CustomPainter {
  const FundoLoginPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Efeito orb suave no canto inferior direito do painel azul
    final Offset orbCenter = Offset(size.width * 0.85, size.height * 0.78);
    final double orbRadius = size.width * 0.65;
    final Paint orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3898FF).withValues(alpha: 0.28),
          const Color(0xFF006EE6).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: orbCenter, radius: orbRadius));
    canvas.drawCircle(orbCenter, orbRadius, orbPaint);

    // Linhas circulares geométricas sutis (topo-direito e base-esquerda)
    final Paint circleLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..isAntiAlias = true;

    // Círculo superior direito
    final double topRadius = size.width * 0.36;
    final Offset topCenter = Offset(size.width * 0.96, size.height * 0.14);
    canvas.drawCircle(topCenter, topRadius, circleLinePaint);

    // Círculo inferior esquerdo
    final double bottomRadius = size.width * 0.42;
    final Offset bottomCenter = Offset(size.width * 0.08, size.height * 0.95);
    canvas.drawCircle(bottomCenter, bottomRadius, circleLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
