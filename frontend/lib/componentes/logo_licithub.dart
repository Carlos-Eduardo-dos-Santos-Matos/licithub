import 'package:flutter/material.dart';
import '../configuracoes/tema_app.dart';

/// Marca oficial "LicitHub" (em Libre Baskerville serifada) acompanhada pelo
/// subtítulo "LICITAÇÕES" (em IBM Plex Sans, caixa alta, leve e espaçada).
class LogoLicitHub extends StatelessWidget {
  final Color primaryColor;
  final Color subtitleColor;
  final double titleFontSize;
  final double subtitleFontSize;
  final bool mostrarSubtitulo;

  const LogoLicitHub({
    super.key,
    required this.primaryColor,
    required this.subtitleColor,
    this.titleFontSize = 26,
    this.subtitleFontSize = 9.5,
    this.mostrarSubtitulo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LicitHub',
          style: TextStyle(
            fontFamily: TemaApp.fonteSerifada,
            fontFamilyFallback: TemaApp.fallbackSerifada,
            fontSize: titleFontSize,
            fontWeight: FontWeight.w700,
            color: primaryColor,
            height: 1.05,
            letterSpacing: -0.3,
          ),
        ),
        if (mostrarSubtitulo) ...[
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 1.0),
            child: Text(
              'LICITAÇÕES',
              style: TextStyle(
                fontFamily: TemaApp.fonteSemSerifa,
                fontFamilyFallback: TemaApp.fallbackSemSerifa,
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w400,
                color: subtitleColor,
                letterSpacing: 3.4,
                height: 1.1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
