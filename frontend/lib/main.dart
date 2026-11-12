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

void main() {
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

  void _concluirLogin(BuildContext navContext, String origem, {String? email}) {
    debugPrint(
      '[LicitHub Auth] Login acionado via $origem${email != null ? ' ($email)' : ''}',
    );
    buscarDadosDashboard().then((dados) {
      debugPrint(
        '[LicitHub Auth] Conexão com backend validada (${dados.keys.join(', ')})',
      );
    }).catchError((Object erro) {
      debugPrint(
        '[LicitHub Auth] Backend offline ou indisponível no momento: $erro',
      );
    });

    Navigator.of(navContext).pushReplacementNamed('/painel');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LicitHub MVP',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.obterTemaClaro(),
      initialRoute: '/',
      routes: {
        '/': (context) => const TelaInicial(),
        '/login': (routeContext) => TelaLogin(
              onLoginSuccess: (email) => _concluirLogin(
                routeContext,
                'formulário de e-mail/senha',
                email: email,
              ),
              onGoogleLogin: () => _concluirLogin(
                routeContext,
                'Google OAuth (mock)',
              ),
            ),
        '/painel': (context) => const LayoutPrincipal(),
        '/dashboard': (context) => const LayoutPrincipal(),
      },
    );
  }
}
