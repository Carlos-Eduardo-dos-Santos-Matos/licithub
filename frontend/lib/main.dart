import 'package:flutter/material.dart';
import 'configuracoes/carregador_fontes.dart';
import 'configuracoes/tema_app.dart';
import 'servicos/api_servico.dart';
import 'telas/painel/layout_principal.dart';
import 'telas/publico/tela_inicial.dart';
import 'telas/publico/tela_login.dart';

export 'configuracoes/tema_app.dart';
export 'modelos/edital.dart';
export 'servicos/api_servico.dart';
export 'servicos/formatadores.dart';
export 'telas/painel/layout_principal.dart';
export 'telas/painel/tela_buscar_editais.dart';
export 'telas/painel/tela_dashboard.dart';
export 'telas/painel/tela_detalhes_edital.dart';
export 'telas/painel/tela_documentos.dart';
export 'telas/painel/tela_funil.dart';
export 'telas/publico/tela_inicial.dart';
export 'telas/publico/tela_login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessaoUsuario.carregarSessao();
  await acessibilidadeApp.carregarPreferencias();
  runApp(const LicitHubApp());
}

class LicitHubApp extends StatefulWidget {
  const LicitHubApp({super.key});

  @override
  State<LicitHubApp> createState() => _LicitHubAppState();
}

class _LicitHubAppState extends State<LicitHubApp> {
  @override
  void initState() {
    super.initState();
    _inicializarFontes();
  }

  Future<void> _inicializarFontes() async {
    await CarregadorFontes.carregarFontesTipografia();
    if (mounted) {
      setState(() {});
    }
  }

  Widget _construirRotaProtegida(BuildContext routeContext) {
    if (SessaoUsuario.estaAutenticado) {
      return const LayoutPrincipal();
    }
    return TelaLogin(
      onLoginSuccess: (_) {
        Navigator.of(routeContext).pushReplacementNamed('/painel');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: acessibilidadeApp,
      builder: (context, _) {
        return MaterialApp(
          title: 'LicitHub MVP',
          debugShowCheckedModeBanner: false,
          theme: TemaApp.obterTemaClaro(),
          darkTheme: TemaApp.obterTemaEscuro(),
          themeMode: acessibilidadeApp.themeMode,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(acessibilidadeApp.escalaFonte),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          initialRoute: '/',
          routes: {
            '/': (context) => const TelaInicial(),
            '/login': (routeContext) => TelaLogin(
                  onLoginSuccess: (_) {
                    Navigator.of(routeContext).pushReplacementNamed('/painel');
                  },
                ),
            '/painel': _construirRotaProtegida,
            '/dashboard': _construirRotaProtegida,
          },
        );
      },
    );
  }
}