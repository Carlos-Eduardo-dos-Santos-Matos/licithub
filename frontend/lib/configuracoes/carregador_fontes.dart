import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Serviço responsável por carregar dinamicamente as fontes Libre Baskerville (serifada)
/// e IBM Plex Sans (sem serifa) no motor gráfico do Flutter.
class CarregadorFontes {
  const CarregadorFontes._();

  static Future<void> carregarFontesTipografia() async {
    Future<void> registrarFamilia(String familia, List<String> urls) async {
      try {
        final loader = FontLoader(familia);
        bool adicionou = false;
        for (final url in urls) {
          final resp = await http.get(Uri.parse(url));
          if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
            final bytes = resp.bodyBytes;
            loader.addFont(
              Future.value(
                ByteData.sublistView(bytes),
              ),
            );
            adicionou = true;
          }
        }
        if (adicionou) {
          await loader.load();
        }
      } catch (e) {
        debugPrint('[LicitHub Fonts] Aviso ao carregar $familia: $e');
      }
    }

    await Future.wait([
      registrarFamilia('Libre Baskerville', const [
        'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/librebaskerville/LibreBaskerville-Regular.ttf',
        'https://cdn.jsdelivr.net/gh/google/fonts@main/ofl/librebaskerville/LibreBaskerville-Bold.ttf',
      ]),
      registrarFamilia('IBM Plex Sans', const [
        'https://cdn.jsdelivr.net/fontsource/fonts/ibm-plex-sans@latest/latin-400-normal.ttf',
        'https://cdn.jsdelivr.net/fontsource/fonts/ibm-plex-sans@latest/latin-500-normal.ttf',
        'https://cdn.jsdelivr.net/fontsource/fonts/ibm-plex-sans@latest/latin-600-normal.ttf',
        'https://cdn.jsdelivr.net/fontsource/fonts/ibm-plex-sans@latest/latin-700-normal.ttf',
      ]),
    ]);
  }
}
