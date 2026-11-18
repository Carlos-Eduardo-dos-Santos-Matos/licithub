import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ControladorAcessibilidade extends ChangeNotifier {
  static const _kModoEscuro = 'licithub_modo_escuro';
  static const _kEscalaFonte = 'licithub_escala_fonte';
  static const _kOcultarSensiveis = 'licithub_ocultar_sensiveis';

  bool _modoEscuro = false;
  double _escalaFonte = 1.0;
  bool _ocultarDadosSensiveis = true;

  bool get modoEscuro => _modoEscuro;
  ThemeMode get themeMode => _modoEscuro ? ThemeMode.dark : ThemeMode.light;
  double get escalaFonte => _escalaFonte;
  bool get ocultarDadosSensiveis => _ocultarDadosSensiveis;

  Future<void> carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    _modoEscuro = prefs.getBool(_kModoEscuro) ?? false;
    _escalaFonte = prefs.getDouble(_kEscalaFonte) ?? 1.0;
    _ocultarDadosSensiveis = prefs.getBool(_kOcultarSensiveis) ?? true;
    notifyListeners();
  }

  Future<void> alternarTema() async {
    _modoEscuro = !_modoEscuro;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kModoEscuro, _modoEscuro);
  }

  Future<void> aumentarFonte() async {
    if (_escalaFonte >= 1.3) return;
    _escalaFonte = double.parse((_escalaFonte + 0.1).toStringAsFixed(1));
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kEscalaFonte, _escalaFonte);
  }

  Future<void> diminuirFonte() async {
    if (_escalaFonte <= 0.9) return;
    _escalaFonte = double.parse((_escalaFonte - 0.1).toStringAsFixed(1));
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kEscalaFonte, _escalaFonte);
  }

  Future<void> alternarProtecaoDados() async {
    _ocultarDadosSensiveis = !_ocultarDadosSensiveis;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOcultarSensiveis, _ocultarDadosSensiveis);
  }

  String mascararEmail(String email) {
    if (!_ocultarDadosSensiveis || email.isEmpty) return email;
    final partes = email.split('@');
    if (partes.length != 2) return '***';
    final usuario = partes[0];
    final visivel = usuario.length <= 2 ? usuario : usuario.substring(0, 2);
    return '$visivel***@${partes[1]}';
  }

  String mascararCnpj(String cnpj) {
    final digitos = cnpj.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 14) {
      return _ocultarDadosSensiveis ? '**.***.***/****-**' : cnpj;
    }
    if (!_ocultarDadosSensiveis) {
      return '${digitos.substring(0, 2)}.${digitos.substring(2, 5)}.${digitos.substring(5, 8)}/${digitos.substring(8, 12)}-${digitos.substring(12)}';
    }
    return '${digitos.substring(0, 2)}.***.***/${digitos.substring(8, 12)}-**';
  }
}

final ControladorAcessibilidade acessibilidadeApp = ControladorAcessibilidade();

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
      brightness: Brightness.light,
      fontFamily: fonteSemSerifa,
      fontFamilyFallback: fallbackSemSerifa,
      scaffoldBackgroundColor: const Color(0xFFF4F7F9),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE2E8F0),
      primaryColor: const Color(0xFF004CA3),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF004CA3),
        secondary: Color(0xFF0F172A),
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: fonteSemSerifa,
          color: Color(0xFF1E293B),
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

  static ThemeData obterTemaEscuro() {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: fonteSemSerifa,
      fontFamilyFallback: fallbackSemSerifa,
      scaffoldBackgroundColor: const Color(0xFF090E1A),
      cardColor: const Color(0xFF111827),
      dividerColor: const Color(0xFF1E293B),
      primaryColor: const Color(0xFF3B82F6),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3B82F6),
        secondary: Color(0xFF60A5FA),
        surface: Color(0xFF111827),
        onSurface: Color(0xFFF8FAFC),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF111827),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: fonteSemSerifa,
          color: Color(0xFFF1F5F9),
        ),
        bodyMedium: TextStyle(
          fontFamily: fonteSemSerifa,
          color: Color(0xFFCBD5E1),
        ),
        labelLarge: TextStyle(
          fontFamily: fonteSemSerifa,
        ),
      ),
    );
  }
}