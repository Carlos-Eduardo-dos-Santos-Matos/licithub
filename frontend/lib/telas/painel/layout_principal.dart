import 'package:flutter/material.dart';
import '../../componentes/menu_lateral.dart';
import '../../modelos/edital.dart';
import 'tela_buscar_editais.dart';
import 'tela_dashboard.dart';
import 'tela_detalhes_edital.dart';
import 'tela_documentos.dart';
import 'tela_funil.dart';

typedef MainLayout = LayoutPrincipal;

/// Estrutura principal do painel interno (Menu Lateral + Navegação em Abas).
class LayoutPrincipal extends StatefulWidget {
  const LayoutPrincipal({super.key});

  @override
  State<LayoutPrincipal> createState() => _LayoutPrincipalState();
}

class _LayoutPrincipalState extends State<LayoutPrincipal> {
  int _selectedIndex = 0;
  Edital? _editalSelecionado;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const TelaDashboard(),
      TelaBuscarEditais(
        onAnalisar: (edital) {
          setState(() {
            _editalSelecionado = edital;
          });
        },
      ),
      const TelaFunil(),
      const TelaDocumentos(),
    ];

    return Scaffold(
      body: Row(
        children: [
          // Menu Lateral (Sidebar)
          MenuLateral(
            indiceSelecionado: _selectedIndex,
            exibindoDetalhes: _editalSelecionado != null,
            aoSelecionarItem: (index) {
              setState(() {
                _selectedIndex = index;
                _editalSelecionado = null;
              });
            },
          ),

          // Área Principal de Conteúdo
          Expanded(
            child: Container(
              color: const Color(0xFFF4F7F9),
              child: Stack(
                children: [
                  Offstage(
                    offstage: _editalSelecionado != null,
                    child: IndexedStack(index: _selectedIndex, children: pages),
                  ),
                  if (_editalSelecionado != null)
                    TelaDetalhesEdital(
                      edital: _editalSelecionado!,
                      onBack: () {
                        setState(() {
                          _editalSelecionado = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
