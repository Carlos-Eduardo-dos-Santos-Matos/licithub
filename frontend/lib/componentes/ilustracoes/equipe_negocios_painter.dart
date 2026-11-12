import 'package:flutter/material.dart';

/// Ilustração vetorial para o card "Sobre nós" caso a imagem de rede não carregue.
class EquipeNegociosPainter extends CustomPainter {
  const EquipeNegociosPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bg = Paint()..color = const Color(0xFFEFF6FF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // Quadro de gráficos ao fundo
    final Paint board = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.12,
          size.width * 0.35,
          size.height * 0.42,
        ),
        const Radius.circular(8),
      ),
      board,
    );

    // Barras azuis de gráfico na mesa/quadro
    final Paint chartBlue = Paint()..color = const Color(0xFF2563EB);
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * (0.13 + i * 0.06),
            size.height * (0.38 - i * 0.04),
            size.width * 0.035,
            size.height * (0.10 + i * 0.04),
          ),
          const Radius.circular(3),
        ),
        chartBlue,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
