import 'package:flutter/material.dart';
import '../configuracoes/tema_app.dart';

/// Barra lateral (Sidebar) de navegação do painel interno do LicitHub.
class MenuLateral extends StatelessWidget {
  final int indiceSelecionado;
  final bool exibindoDetalhes;
  final ValueChanged<int> aoSelecionarItem;

  const MenuLateral({
    super.key,
    required this.indiceSelecionado,
    required this.exibindoDetalhes,
    required this.aoSelecionarItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: const [
                Icon(Icons.bolt, color: Colors.blueAccent, size: 28),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'LicitHub',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: TemaApp.fonteSerifada,
                      fontFamilyFallback: TemaApp.fallbackSerifada,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _construirItemMenu(0, Icons.home_outlined, 'Dashboard'),
          _construirItemMenu(1, Icons.search, 'Buscar Editais'),
          _construirItemMenu(2, Icons.filter_alt_outlined, 'Funil'),
          _construirItemMenu(3, Icons.description_outlined, 'Documentos'),
        ],
      ),
    );
  }

  Widget _construirItemMenu(int index, IconData icon, String title) {
    final isSelected = indiceSelecionado == index && !exibindoDetalhes;
    return InkWell(
      onTap: () => aoSelecionarItem(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white60,
              size: 22,
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
