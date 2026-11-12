import 'package:flutter/material.dart';

/// Configurações centralizadas de tema, cores e tipografia do LicitHub.
class TemaApp {
  const TemaApp._();

  static const String fonteSerifada = 'Libre Baskerville';
  static const String fonteSemSerifa = 'IBM Plex Sans';

  static const List<String> fallbackSerifada = [
    'Georgia',
    'Times New Roman',
    'serif',
  ];

  static const List<String> fallbackSemSerifa = [
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static ThemeData obterTemaClaro() {
    return ThemeData(
      fontFamily: fonteSemSerifa,
      fontFamilyFallback: fallbackSemSerifa,
      scaffoldBackgroundColor: const Color(0xFFF8FAFE),
      primaryColor: const Color(0xFF0F172A),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: fonteSemSerifa,
          color: Color(0xFF334155),
        ),
        bodyMedium: TextStyle(
          fontFamily: fonteSemSerifa,
          color: Color(0xFF334155),
        ),
        labelLarge: TextStyle(
          fontFamily: fonteSemSerifa,
        ),
      ),
    );
  }
}
