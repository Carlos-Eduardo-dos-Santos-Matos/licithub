import 'package:flutter/material.dart';

/// Pintura arquitetônica para o fundo do Hero (prédio governamental com colunas clássicas),
/// garantindo fidelidade visual mesmo sem conexão externa.
class PredioGovernoPainter extends CustomPainter {
  const PredioGovernoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0B2A66), Color(0xFF1A4F9C)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    final Paint buildingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Pedestal / escadaria e fachada neoclássica com colunas
    final double baseTop = size.height * 0.82;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.08,
        baseTop,
        size.width * 0.84,
        size.height * 0.18,
      ),
      buildingPaint,
    );

    // Telhado / entablamento clássico em perspectiva
    final Path roofPath = Path()
      ..moveTo(size.width * 0.12, size.height * 0.28)
      ..lineTo(size.width * 0.36, size.height * 0.10)
      ..lineTo(size.width * 0.92, size.height * 0.42)
      ..lineTo(size.width * 0.12, size.height * 0.42)
      ..close();
    canvas.drawPath(roofPath, buildingPaint);
    canvas.drawPath(roofPath, linePaint);

    // Colunas clássicas verticais
    const int columnCount = 10;
    final double startX = size.width * 0.18;
    final double endX = size.width * 0.86;
    final double spacing = (endX - startX) / columnCount;
    for (int i = 0; i <= columnCount; i++) {
      final double x = startX + i * spacing;
      canvas.drawRect(
        Rect.fromLTWH(
          x,
          size.height * 0.42,
          spacing * 0.38,
          size.height * 0.40,
        ),
        buildingPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
